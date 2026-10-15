"""
Integration-test fixtures.

Root cause of the previous hang & teardown errors
--------------------------------------------------
The `db_session` fixture used the default transactional isolation.
Every SELECT therefore started an implicit transaction that held a
SHARE lock on the queried table until explicit commit/rollback.

When a test performed:
    1. POST  /register          (app writes OTP)
    2. db_session.execute(SELECT from email_verifications)
    3. POST  /verify-email      (app UPDATEs the same row)

Step 3 blocked forever on the SHARE lock from step 2 → pytest hung.
The same lock caused TRUNCATE to timeout in teardown.

Fix
---
`db_session` now runs in AUTOCOMMIT: every statement commits instantly,
so reads never leave locks behind. Writes (from factories) still persist.
A fresh `_engine.begin()` transaction performs the TRUNCATE cleanup.
"""
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import NullPool

from app.core.config import settings
from app.core.security import create_access_token
from app.domain.entities.user import User, UserRole
from app.infrastructure.database.base import Base
from app.infrastructure.database.models import *  # noqa: F401,F403
from app.infrastructure.database.session import get_db
from app.main import create_app
from tests.helpers.factories import create_user


# ═══════════════════════════════════════════════════════════════
# Engine — one per session
# ═══════════════════════════════════════════════════════════════
@pytest_asyncio.fixture(scope="session", loop_scope="session")
async def _engine():
    engine = create_async_engine(
        settings.database_url,
        echo=False,
        poolclass=NullPool,
        # Belt-and-suspenders: asyncpg per-query timeout prevents
        # any future lock contention from hanging the suite.
        connect_args={"command_timeout": 30},
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture(scope="session", loop_scope="session")
async def _session_factory(_engine):
    """Regular (transactional) factory — used by the app's `get_db`."""
    return async_sessionmaker(
        bind=_engine,
        expire_on_commit=False,
        class_=AsyncSession,
        autoflush=False,
    )


# ═══════════════════════════════════════════════════════════════
# Assertion session — AUTOCOMMIT
# ═══════════════════════════════════════════════════════════════
@pytest_asyncio.fixture(loop_scope="session")
async def db_session(_engine):
    """
    AUTOCOMMIT session for reads and factory writes.

    Why AUTOCOMMIT:
      A SELECT under default isolation opens a transaction that holds
      a SHARE lock until the session ends. The app's subsequent UPDATE
      would block on that lock. AUTOCOMMIT releases locks instantly.
    """
    ac_engine = _engine.execution_options(isolation_level="AUTOCOMMIT")
    maker = async_sessionmaker(
        bind=ac_engine,
        expire_on_commit=False,
        class_=AsyncSession,
        autoflush=False,
    )
    async with maker() as session:
        yield session

    # Cleanup — its own explicit transaction on a fresh connection.
    async with _engine.begin() as conn:
        for table in reversed(Base.metadata.sorted_tables):
            await conn.execute(
                text(f'TRUNCATE TABLE "{table.name}" RESTART IDENTITY CASCADE')
            )


# ═══════════════════════════════════════════════════════════════
# HTTP client — app's `get_db` overridden with our factory
# ═══════════════════════════════════════════════════════════════
@pytest_asyncio.fixture(loop_scope="session")
async def client(_session_factory):
    app = create_app()

    async def _override_get_db():
        async with _session_factory() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise
            finally:
                await session.close()

    app.dependency_overrides[get_db] = _override_get_db

    transport = ASGITransport(app=app)
    async with AsyncClient(
        transport=transport, base_url="http://test",
    ) as ac:
        yield ac

    app.dependency_overrides.clear()


# ═══════════════════════════════════════════════════════════════
# Persisted users
# ═══════════════════════════════════════════════════════════════
@pytest_asyncio.fixture(loop_scope="session")
async def patient_user(db_session) -> User:
    return await create_user(
        db_session,
        role=UserRole.PATIENT,
        email="patient@test.com",
        phone="0911111111",
        full_name="Patient Test User",
    )


@pytest_asyncio.fixture(loop_scope="session")
async def doctor_user(db_session) -> User:
    return await create_user(
        db_session,
        role=UserRole.DOCTOR,
        email="doctor@test.com",
        phone="0922222222",
        full_name="Doctor Test User",
        university_id="UNI-001",
        is_verified_by_admin=True,
    )


@pytest_asyncio.fixture(loop_scope="session")
async def admin_user(db_session) -> User:
    return await create_user(
        db_session,
        role=UserRole.ADMIN,
        email="admin@test.com",
        phone="0933333333",
        full_name="Admin Test User",
    )


# ═══════════════════════════════════════════════════════════════
# Authenticated clients
# ═══════════════════════════════════════════════════════════════
def _attach_auth(base_client: AsyncClient, user: User) -> AsyncClient:
    token = create_access_token(str(user.id))
    base_client.headers["Authorization"] = f"Bearer {token}"
    return base_client


@pytest_asyncio.fixture(loop_scope="session")
async def patient_client(client, patient_user):
    return _attach_auth(client, patient_user)


@pytest_asyncio.fixture(loop_scope="session")
async def doctor_client(client, doctor_user):
    return _attach_auth(client, doctor_user)


@pytest_asyncio.fixture(loop_scope="session")
async def admin_client(client, admin_user):
    return _attach_auth(client, admin_user)