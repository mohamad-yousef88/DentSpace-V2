"""Routers package — aggregates all v1 sub-routers."""
from fastapi import APIRouter

from app.presentation.api.v1.routers import (
    admin_router,
    appointments_router,
    auth_router,
    cases_router,
    notifications_router,
    orders_router,
    tools_router,
)

api_router = APIRouter()

api_router.include_router(auth_router.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(cases_router.router, prefix="/cases", tags=["Patient Cases"])
api_router.include_router(
    appointments_router.router, prefix="/appointments", tags=["Appointments"],
)
api_router.include_router(
    notifications_router.router, prefix="/notifications", tags=["Notifications"],
)
api_router.include_router(tools_router.router, prefix="/tools", tags=["Tools Marketplace"])
api_router.include_router(orders_router.router, prefix="/orders", tags=["Orders"])
api_router.include_router(admin_router.router, prefix="/admin", tags=["Admin"])