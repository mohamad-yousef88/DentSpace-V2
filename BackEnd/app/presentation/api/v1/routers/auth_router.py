"""
Auth router — registration, email verification, login, refresh,
password reset, profile management, and admin-only doctor creation.

Endpoints that handle credentials are rate-limited via slowapi. Every
limited handler must accept a `request` parameter (slowapi requirement).
"""
from typing import Annotated

from fastapi import (
    APIRouter,
    Depends,
    File,
    Request,
    UploadFile,
    status,
)

from app.application.dtos.auth_dto import (
    AuthResponse,
    CreateDoctorRequest,
    ForgotPasswordRequest,
    LoginRequest,
    MessageResponse,
    RefreshTokenRequest,
    RegisterPatientRequest,
    ResendOtpRequest,
    ResetPasswordRequest,
    TokenResponse,
    UpdateFcmTokenRequest,
    UpdateProfileRequest,
    UserResponse,
    VerifyEmailRequest,
)
from app.core.config import settings
from app.core.dependencies import (
    AuthSvc,
    AvatarSvc,
    CurrentUser,
    require_role,
)
from app.core.exceptions import NotFoundException
from app.core.rate_limit import limiter
from app.domain.entities.user import User, UserRole

router = APIRouter()


# ═══════════════════════════════════════════════════════════════
# Public — registration & verification
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/register",
    response_model=MessageResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new patient account",
)
@limiter.limit(settings.rate_limit_auth)
async def register_patient(
    request: Request,
    payload: RegisterPatientRequest,
    auth: AuthSvc,
):
    user = await auth.register_patient(payload)
    return MessageResponse(
        message=(
            f"Account created. A 6-digit code was sent to {user.email}. "
            f"Please verify to continue."
        )
    )


@router.post(
    "/verify-email",
    response_model=AuthResponse,
    summary="Verify email with OTP and receive tokens",
)
@limiter.limit(settings.rate_limit_auth)
async def verify_email(
    request: Request,
    payload: VerifyEmailRequest,
    auth: AuthSvc,
):
    user = await auth.verify_email(payload.email, payload.otp_code)
    tokens = auth._issue_tokens(user)
    return AuthResponse(
        user=UserResponse.model_validate(user.__dict__),
        tokens=TokenResponse(**tokens),
    )


@router.post(
    "/resend-otp",
    response_model=MessageResponse,
    summary="Resend OTP code to email",
)
@limiter.limit(settings.rate_limit_auth)
async def resend_otp(
    request: Request,
    payload: ResendOtpRequest,
    auth: AuthSvc,
):
    await auth.resend_otp(payload.email)
    return MessageResponse(message="A new code was sent to your email.")


# ═══════════════════════════════════════════════════════════════
# Public — login & tokens
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Login with email and password",
)
@limiter.limit(settings.rate_limit_auth)
async def login(
    request: Request,
    payload: LoginRequest,
    auth: AuthSvc,
):
    user, tokens = await auth.login(payload)
    return AuthResponse(
        user=UserResponse.model_validate(user.__dict__),
        tokens=TokenResponse(**tokens),
    )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Refresh access token using refresh token",
)
async def refresh_token(
    payload: RefreshTokenRequest,
    auth: AuthSvc,
):
    tokens = await auth.refresh_access_token(payload.refresh_token)
    return TokenResponse(**tokens)


# ═══════════════════════════════════════════════════════════════
# Public — password reset
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    summary="Request a password-reset OTP",
)
@limiter.limit(settings.rate_limit_auth)
async def forgot_password(
    request: Request,
    payload: ForgotPasswordRequest,
    auth: AuthSvc,
):
    await auth.forgot_password(payload.email)
    return MessageResponse(
        message=(
            "If the email is registered, a reset code has been sent. "
            "Check your inbox."
        )
    )


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    summary="Reset password using OTP",
)
@limiter.limit(settings.rate_limit_auth)
async def reset_password(
    request: Request,
    payload: ResetPasswordRequest,
    auth: AuthSvc,
):
    await auth.reset_password(
        payload.email, payload.otp_code, payload.new_password,
    )
    return MessageResponse(
        message="Password has been reset. You can now log in."
    )


# ═══════════════════════════════════════════════════════════════
# Authenticated — profile
# ═══════════════════════════════════════════════════════════════
@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current authenticated user profile",
)
async def get_me(user: CurrentUser):
    return UserResponse.model_validate(user.__dict__)


@router.patch(
    "/me",
    response_model=UserResponse,
    summary="Update current user profile (partial)",
)
async def update_profile(
    payload: UpdateProfileRequest,
    user: CurrentUser,
    auth: AuthSvc,
):
    updated = await auth.update_profile(user.id, payload)
    return UserResponse.model_validate(updated.__dict__)


@router.patch(
    "/me/fcm-token",
    response_model=MessageResponse,
    summary="Update FCM token for push notifications",
)
async def update_fcm_token(
    payload: UpdateFcmTokenRequest,
    user: CurrentUser,
    auth: AuthSvc,
):
    await auth.update_fcm_token(user.id, payload.fcm_token)
    return MessageResponse(message="FCM token updated.")


@router.post(
    "/logout-all",
    response_model=MessageResponse,
    summary="Invalidate every active session for the current user",
)
async def logout_all(user: CurrentUser, auth: AuthSvc):
    await auth.logout_all_sessions(user.id)
    return MessageResponse(
        message="All sessions have been invalidated. Please log in again."
    )


# ═══════════════════════════════════════════════════════════════
# Authenticated — avatar
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/me/avatar",
    response_model=UserResponse,
    summary="Upload or replace current user avatar",
)
async def upload_avatar(
    user: CurrentUser,
    avatars: AvatarSvc,
    file: UploadFile = File(..., description="JPEG, PNG, or WEBP — max 5 MB"),
):
    size: int | None = None
    try:
        await file.seek(0)
        content = await file.read()
        size = len(content)
        await file.seek(0)
    except Exception:
        size = None

    updated = await avatars.upload_avatar(
        user_id=user.id,
        file=file.file,
        content_type=file.content_type,
        file_size=size,
    )
    return UserResponse.model_validate(updated.__dict__)


@router.delete(
    "/me/avatar",
    response_model=UserResponse,
    summary="Delete current user avatar",
)
async def delete_avatar(
    user: CurrentUser,
    avatars: AvatarSvc,
):
    updated = await avatars.delete_avatar(user.id)
    return UserResponse.model_validate(updated.__dict__)


# ═══════════════════════════════════════════════════════════════
# Admin only
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/admin/create-doctor",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="[Admin] Create a doctor account",
)
async def admin_create_doctor(
    payload: CreateDoctorRequest,
    admin: Annotated[User, Depends(require_role(UserRole.ADMIN))],
    auth: AuthSvc,
):
    doctor = await auth.create_doctor(payload, admin_id=admin.id)
    return UserResponse.model_validate(doctor.__dict__)


# ═══════════════════════════════════════════════════════════════
# DEBUG ONLY — automatically disabled in production
# ═══════════════════════════════════════════════════════════════
if settings.debug:

    @router.get(
        "/debug/last-otp/{email}",
        summary="[DEBUG ONLY] Get the latest OTP code for an email",
        tags=["Authentication", "Debug"],
    )
    async def debug_get_last_otp(email: str, auth: AuthSvc):
        otp = await auth.get_last_otp_for_debug(email)
        if otp is None:
            raise NotFoundException("No active OTP found for this email.")
        return {"email": email, "otp_code": otp}

    @router.post(
        "/debug/test-push",
        summary="[DEBUG ONLY] Send a test push to the current user",
        tags=["Authentication", "Debug"],
    )
    async def debug_test_push(user: CurrentUser, auth: AuthSvc):
        return await auth.send_test_push(user.id)