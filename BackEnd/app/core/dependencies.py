"""
FastAPI dependencies for authentication & authorization.
"""
from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.services.auth_service import AuthService
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.core.security import decode_token
from app.domain.entities.user import User, UserRole
from app.infrastructure.database.session import get_db

# ─── Bearer scheme ─────────────────────────────────────────────
_bearer = HTTPBearer(auto_error=False)


async def get_auth_service(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> AuthService:
    return AuthService(session)


async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)],
    auth: Annotated[AuthService, Depends(get_auth_service)],
) -> User:
    if credentials is None:
        raise UnauthorizedException("Missing authorization header.")

    # Decode and validate signature/exp
    from app.core.security import decode_token
    payload = decode_token(credentials.credentials, expected_type="access")
    user_id = int(payload["sub"])

    user = await auth.get_by_id(user_id)

    if not user.is_active:
        raise ForbiddenException("Account is disabled.")

    # ★ JWT revocation after password change / logout-all
    if user.password_changed_at is not None:
        token_iat = int(payload.get("iat", 0))
        pwd_ts = int(user.password_changed_at.timestamp())
        if token_iat < pwd_ts:
            raise UnauthorizedException(
                "Session expired. Please log in again."
            )

    return user


async def get_current_active_user(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    if not user.is_active:
        raise ForbiddenException("Account is disabled.")
    return user


def require_role(*roles: UserRole):
    """Factory: require the current user to have one of the given roles."""

    async def _checker(
        user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        if user.role not in roles:
            raise ForbiddenException(
                f"This action requires role: {', '.join(r.value for r in roles)}"
            )
        return user

    return _checker


# ─── Aliases for readability ───────────────────────────────────
CurrentUser = Annotated[User, Depends(get_current_user)]
CurrentActiveUser = Annotated[User, Depends(get_current_active_user)]
DbSession = Annotated[AsyncSession, Depends(get_db)]
AuthSvc = Annotated[AuthService, Depends(get_auth_service)]
from app.application.services.avatar_service import AvatarService  # noqa: E402


async def get_avatar_service(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> AvatarService:
    return AvatarService(session)


AvatarSvc = Annotated[AvatarService, Depends(get_avatar_service)]
from app.application.services.case_service import CaseService  # noqa: E402


async def get_case_service(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> CaseService:
    return CaseService(session)


CaseSvc = Annotated[CaseService, Depends(get_case_service)]
from app.application.services.appointment_service import AppointmentService  # noqa: E402
from app.application.services.notification_service import NotificationService  # noqa: E402


async def get_appointment_service(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> AppointmentService:
    return AppointmentService(session)


async def get_notification_service(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> NotificationService:
    return NotificationService(session)


AppointmentSvc = Annotated[AppointmentService, Depends(get_appointment_service)]
NotificationSvc = Annotated[NotificationService, Depends(get_notification_service)]
from app.application.services.order_service import OrderService  # noqa: E402
from app.application.services.tool_service import ToolService  # noqa: E402


async def get_tool_service(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> ToolService:
    return ToolService(session)


async def get_order_service(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> OrderService:
    return OrderService(session)


ToolSvc = Annotated[ToolService, Depends(get_tool_service)]
OrderSvc = Annotated[OrderService, Depends(get_order_service)]
from app.application.services.admin_service import AdminService  # noqa: E402


async def get_admin_service(
    session: Annotated[AsyncSession, Depends(get_db)],
) -> AdminService:
    return AdminService(session)


AdminSvc = Annotated[AdminService, Depends(get_admin_service)]