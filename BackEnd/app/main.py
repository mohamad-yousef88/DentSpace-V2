"""
FastAPI application entry point.

Run with:
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
"""
import asyncio
import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from sqlalchemy import text
from starlette.middleware.sessions import SessionMiddleware

from app.core.config import settings
from app.core.exceptions import register_exception_handlers
from app.core.logging import setup_logging
from app.core.rate_limit import limiter
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.external.firebase_admin import init_firebase
from app.infrastructure.jobs.scheduler import (
    shutdown_scheduler,
    start_scheduler,
)
from app.presentation.admin.context import base_context
from app.presentation.admin.routers import admin_router
from app.presentation.admin.templates import templates as admin_templates
from app.presentation.api.v1.routers import api_router
from app.presentation.middleware.request_id import RequestIDMiddleware

logger = logging.getLogger(__name__)

PROJECT_ROOT = Path(__file__).resolve().parents[1]
STATIC_DIR = PROJECT_ROOT / "static"

_RATE_LIMIT_CLEANUP_INTERVAL = 6 * 3600


async def _periodic_limiter_cleanup() -> None:
    while True:
        try:
            await asyncio.sleep(_RATE_LIMIT_CLEANUP_INTERVAL)
            storage = getattr(limiter, "_storage", None)
            if storage is None:
                continue
            cleared = False
            for attr in ("storage", "_storage"):
                inner = getattr(storage, attr, None)
                if isinstance(inner, dict):
                    inner.clear()
                    cleared = True
                    break
        except asyncio.CancelledError:
            raise
        except Exception as exc:
            logger.warning("[limiter_cleanup] unexpected error: %s", exc)


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging("DEBUG" if settings.debug else "INFO")
    init_firebase()
    start_scheduler()
    limiter_cleanup_task = asyncio.create_task(_periodic_limiter_cleanup())

    yield

    limiter_cleanup_task.cancel()
    try:
        await limiter_cleanup_task
    except asyncio.CancelledError:
        pass
    shutdown_scheduler()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version="1.0.0",
        description="DentSpace — Dental care platform API",
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
        openapi_url="/openapi.json" if settings.debug else None,
        lifespan=lifespan,
    )

    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    app.add_middleware(RequestIDMiddleware)

    app.add_middleware(
        SessionMiddleware,
        secret_key=settings.session_secret,
        session_cookie="dentspace_admin_session",
        max_age=settings.admin_session_max_age,
        same_site="lax",
        https_only=settings.is_production,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    register_exception_handlers(app)

    # ─── Mobile API ───────────────────────────────────────
    app.include_router(api_router, prefix=settings.api_v1_prefix)

    # ─── Static ───────────────────────────────────────────
    STATIC_DIR.mkdir(parents=True, exist_ok=True)
    (STATIC_DIR / "uploads" / "avatars").mkdir(parents=True, exist_ok=True)
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

    # ─── Admin UI ─────────────────────────────────────────
    app.include_router(admin_router, prefix="/admin")

    # ─── Admin 404 handler (HTML for admin routes) ────────
    @app.exception_handler(404)
    async def not_found_handler(request: Request, exc):
        if request.url.path.startswith("/admin") and "text/html" in request.headers.get("accept", ""):
            return HTMLResponse(
                content=admin_templates.get_template("errors/404.html").render(
                    base_context(request)
                ),
                status_code=404,
            )
        # Let default JSON handler take over
        from fastapi.exception_handlers import http_exception_handler
        from fastapi.exceptions import HTTPException as FastHTTPException
        return await http_exception_handler(
            request, FastHTTPException(status_code=404, detail="Not Found")
        )

    # ─── Health ───────────────────────────────────────────
    @app.get("/health", tags=["Health"], summary="Liveness probe")
    async def health():
        return {"status": "ok", "app": settings.app_name}

    @app.get("/health/ready", tags=["Health"], summary="Readiness probe")
    async def readiness():
        try:
            async with AsyncSessionLocal() as session:
                await session.execute(text("SELECT 1"))
            return {"status": "ready", "database": "ok"}
        except Exception as exc:
            return {"status": "not_ready", "database": "unreachable", "error": str(exc)}

    return app


app = create_app()
