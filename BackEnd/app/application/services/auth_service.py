"""
Authentication service — business logic for register, verify, login, etc.
"""
import logging
from datetime import datetime, timezone, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dtos.auth_dto import (
    CreateAdminRequest,
    CreateDoctorRequest,
    LoginRequest,
    RegisterPatientRequest,
)
from app.application.services.email_service import email_service
from app.application.services.otp_service import OtpService
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
    UnauthorizedException,
)
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.domain.entities.user import User, UserRole
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl

logger = logging.getLogger(__name__)


class AuthService:
    def __init__(self, session: AsyncSession):
        self._session = session
        self._users = UserRepositoryImpl(session)
        self._otp = OtpService(session)

    # ═══════════════════════════════════════════════════════
    # Patient Registration
    # ═══════════════════════════════════════════════════════
    async def register_patient(self, data: RegisterPatientRequest) -> User:
        email = data.email.lower().strip()

        if await self._users.exists_by_email(email):
            raise ConflictException("Email is already registered.")
        if await self._users.exists_by_phone(data.phone):
            raise ConflictException("Phone number is already registered.")

        user = User(
            full_name=data.full_name.strip(),
            email=email,
            phone=data.phone.strip(),
            hashed_password=hash_password(data.password),
            role=UserRole.PATIENT,
            gender=data.gender,
            age=data.age,
            is_active=True,
            is_email_verified=False,
            password_changed_at=datetime.now(timezone.utc),
        )
        created = await self._users.create(user)

        code = await self._otp.create_for_user(created.id)
        try:
            await email_service.send_otp_email(created.email, code, "verify")
        except Exception as exc:
            logger.error("Failed to send OTP to %s: %s", created.email, exc)

        logger.info("Patient registered: %s (id=%s)", created.email, created.id)
        return created

    # ═══════════════════════════════════════════════════════
    # Email Verification
    # ═══════════════════════════════════════════════════════
    async def verify_email(self, email: str, otp_code: str) -> User:
        user = await self._users.get_by_email(email)
        if user is None:
            raise NotFoundException("User not found.")

        if user.is_email_verified:
            raise BadRequestException("Email is already verified.")

        await self._otp.verify(user.id, otp_code)

        user.is_email_verified = True
        return await self._users.update(user)

    async def resend_otp(self, email: str) -> None:
        user = await self._users.get_by_email(email)
        if user is None:
            raise NotFoundException("User not found.")
        if user.is_email_verified:
            raise BadRequestException("Email is already verified.")

        code = await self._otp.create_for_user(user.id)
        try:
            await email_service.send_otp_email(user.email, code, "verify")
        except Exception as exc:
            logger.error("Failed to send OTP email to %s: %s", user.email, exc)

    # ═══════════════════════════════════════════════════════
    # Login / Tokens
    # ═══════════════════════════════════════════════════════
    async def login(self, data: LoginRequest) -> tuple[User, dict]:
        email = data.email.lower().strip()
        user = await self._users.get_by_email(email)

        if user is None or not verify_password(data.password, user.hashed_password):
            raise UnauthorizedException("Invalid email or password.")

        if not user.is_active:
            raise ForbiddenException("Account is disabled.")
        if data.platform == "mobile" and user.role == UserRole.ADMIN:
            raise ForbiddenException(
                "Admin accounts cannot sign in from the mobile app. "
                "Please use the web admin panel."
            )

        if not user.is_email_verified:
            raise ForbiddenException(
                "Email is not verified. Please verify it first."
            )

        tokens = self._issue_tokens(user)
        logger.info("Login success: %s", user.email)
        return user, tokens

    async def refresh_access_token(self, refresh_token: str) -> dict:
        payload = decode_token(refresh_token, expected_type="refresh")
        user_id = int(payload["sub"])

        user = await self._users.get_by_id(user_id)
        if user is None or not user.is_active:
            raise UnauthorizedException("User no longer valid.")

        # Revocation check — reject tokens issued before password change
        if user.password_changed_at is not None:
            token_iat = int(payload.get("iat", 0))
            if token_iat < int(user.password_changed_at.timestamp()):
                raise UnauthorizedException("Session expired. Please log in again.")

        return self._issue_tokens(user)

    def _issue_tokens(self, user: User) -> dict:
        from app.core.config import settings
        return {
            "access_token": create_access_token(str(user.id)),
            "refresh_token": create_refresh_token(str(user.id)),
            "token_type": "bearer",
            "expires_in": settings.access_token_expire_minutes * 60,
        }

    # ═══════════════════════════════════════════════════════
    # Admin: create doctor
    # ═══════════════════════════════════════════════════════
    async def create_doctor(
        self, data: CreateDoctorRequest, admin_id: int
    ) -> User:
        email = data.email.lower().strip()

        if await self._users.exists_by_email(email):
            raise ConflictException("Email is already registered.")
        if await self._users.exists_by_phone(data.phone):
            raise ConflictException("Phone number is already registered.")
        if await self._users.get_by_university_id(data.university_id):
            raise ConflictException("University ID is already in use.")

        doctor = User(
            full_name=data.full_name.strip(),
            email=email,
            phone=data.phone.strip(),
            hashed_password=hash_password(data.password),
            role=UserRole.DOCTOR,
            gender=data.gender,
            age=data.age,
            university_id=data.university_id.strip(),
            created_by_admin_id=admin_id,
            is_verified_by_admin=True,
            is_email_verified=True,
            is_active=True,
            password_changed_at=datetime.now(timezone.utc),
        )
        created = await self._users.create(doctor)
        logger.info(
            "Doctor created by admin %s: %s (university_id=%s)",
            admin_id, created.email, created.university_id,
        )
        return created

    # ═══════════════════════════════════════════════════════
    # Bootstrap: create first admin (CLI only)
    # ═══════════════════════════════════════════════════════
    async def create_admin(self, data: CreateAdminRequest) -> User:
        email = data.email.lower().strip()

        if await self._users.exists_by_email(email):
            raise ConflictException("Email is already registered.")
        if await self._users.exists_by_phone(data.phone):
            raise ConflictException("Phone number is already registered.")

        admin = User(
            full_name=data.full_name.strip(),
            email=email,
            phone=data.phone.strip(),
            hashed_password=hash_password(data.password),
            role=UserRole.ADMIN,
            gender=data.gender,
            age=data.age,
            is_verified_by_admin=True,
            is_email_verified=True,
            is_active=True,
            password_changed_at=datetime.now(timezone.utc),
        )
        created = await self._users.create(admin)
        logger.info("Admin created: %s (id=%s)", created.email, created.id)
        return created

    # ═══════════════════════════════════════════════════════
    # Profile
    # ═══════════════════════════════════════════════════════
    async def get_by_id(self, user_id: int) -> User:
        user = await self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundException("User not found.")
        return user

    async def update_fcm_token(self, user_id: int, fcm_token: str) -> None:
        user = await self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundException("User not found.")
        user.fcm_token = fcm_token
        await self._users.update(user)

    async def get_last_otp_for_debug(self, email: str) -> str | None:
        """[DEBUG ONLY] Return latest unused OTP for testing."""
        user = await self._users.get_by_email(email)
        if user is None:
            return None
        return await self._otp.get_latest_unused(user.id)

    # ═══════════════════════════════════════════════════════
    # Password Reset
    # ═══════════════════════════════════════════════════════
    async def forgot_password(self, email: str) -> None:
        user = await self._users.get_by_email(email)

        if user is None:
            logger.info("Password reset requested for unknown email: %s", email)
            return  # silent success — prevents enumeration

        if not user.is_active:
            raise ForbiddenException("Account is disabled.")

        code = await self._otp.create_for_user(user.id)
        try:
            await email_service.send_otp_email(user.email, code, "reset")
        except Exception as exc:
            logger.error(
                "Failed to send password reset email to %s: %s",
                user.email, exc,
            )

    async def reset_password(
        self, email: str, otp_code: str, new_password: str
    ) -> None:
        user = await self._users.get_by_email(email)
        if user is None:
            raise NotFoundException("User not found.")

        await self._otp.verify(user.id, otp_code)

        user.hashed_password = hash_password(new_password)
        # Same +1s buffer as logout-all — old tokens must be rejected.
        user.password_changed_at = (
                datetime.now(timezone.utc) + timedelta(seconds=1)
        )
        await self._users.update(user)
        logger.info("Password reset successful for %s", user.email)
    async def logout_all_sessions(self, user_id: int) -> None:
        """Invalidate every JWT issued before now."""
        user = await self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundException("User not found.")

        # +1-second buffer: JWT `iat` is stored at second precision, so a
        # token issued in the same wall-clock second as the logout would
        # pass an `iat < pwd_ts` check. Adding 1s guarantees that every
        # token minted before the logout is rejected. New logins succeed
        # because their `iat` will be >= pwd_ts once the next second
        # elapses (typically < 1s after the user action).
        user.password_changed_at = (
            datetime.now(timezone.utc) + timedelta(seconds=1)
        )
        await self._users.update(user)
        logger.info("All sessions invalidated for user=%s", user_id)

    # ═══════════════════════════════════════════════════════
    # Profile
    # ═══════════════════════════════════════════════════════
    async def update_profile(self, user_id: int, data) -> User:
        """Partially update the current user's profile."""
        from app.application.dtos.auth_dto import UpdateProfileRequest

        assert isinstance(data, UpdateProfileRequest)

        user = await self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundException("User not found.")

        if data.phone is not None and data.phone != user.phone:
            existing = await self._users.get_by_phone(data.phone)
            if existing is not None and existing.id != user.id:
                raise ConflictException("Phone number is already registered.")
            user.phone = data.phone.strip()

        if data.full_name is not None:
            user.full_name = data.full_name.strip()
        if data.gender is not None:
            user.gender = data.gender
        if data.age is not None:
            user.age = data.age

        return await self._users.update(user)

    # ═══════════════════════════════════════════════════════
    # DEBUG: test push
    # ═══════════════════════════════════════════════════════
    async def send_test_push(self, user_id: int) -> dict:
        """[DEBUG ONLY] Send a test push to the current user's FCM token."""
        from app.infrastructure.external.push_service import push_service

        user = await self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundException("User not found.")
        if not user.fcm_token:
            return {
                "sent": False,
                "reason": "no_token",
                "message": "User has no FCM token registered.",
            }

        result = push_service.send_to_token(
            user.fcm_token,
            title="DentSpace — Test Push",
            body="If you see this, push notifications work correctly.",
            data={"test": "true"},
        )

        # Clean up dead tokens
        if not result.success and result.reason == "unregistered":
            user.fcm_token = None
            await self._users.update(user)

        return {
            "sent": result.success,
            "reason": result.reason or "ok",
            "token_preview": f"{user.fcm_token[:20]}..." if user.fcm_token else None,
        }