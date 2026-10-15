"""
Async SQLAlchemy engine + session factory.

Usage in FastAPI:
    async def endpoint(db: AsyncSession = Depends(get_db)):
        ...
"""
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.config import settings

# ─── Engine (single instance for the whole app) ────────────────
engine = create_async_engine(
    settings.database_url,
    echo=False,               # Set True to debug SQL
    future=True,
    pool_pre_ping=True,       # Verify connections before using them
    pool_size=10,
    max_overflow=20,
    pool_recycle=3600,
)

# ─── Session factory ───────────────────────────────────────────
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,   # Keep objects usable after commit
    autoflush=False,
)


# ─── Dependency ────────────────────────────────────────────────
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency that yields a database session."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()