"""Aggregates all admin UI routers."""
from fastapi import APIRouter

from .auth_router import router as auth_router
from .cases_router import router as cases_router
from .dashboard_router import router as dashboard_router
from .doctors_router import router as doctors_router
from .profile_router import router as profile_router
from .users_router import router as users_router


admin_router = APIRouter()

admin_router.include_router(auth_router, tags=["Admin Auth"])
admin_router.include_router(dashboard_router, tags=["Admin Dashboard"])
admin_router.include_router(users_router, prefix="/users", tags=["Admin Users"])
admin_router.include_router(doctors_router, prefix="/doctors", tags=["Admin Doctors"])
admin_router.include_router(cases_router, prefix="/cases", tags=["Admin Cases"])
admin_router.include_router(profile_router, prefix="/profile", tags=["Admin Profile"])