"""
OTP service — generate, store, and validate email OTP codes.

Brute-force protection:
  • Each wrong guess increments `attempts` on the current OTP.
  • After MAX_OTP_ATTEMPTS wrong guesses, the OTP is invalidated.
  • Wrong guesses return the SAME error as expired codes, so attackers
    cannot distinguish the two cases.
"""
import secrets
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import BadRequestException
from app.infrastructure.database.models.email_verification_model import (
    EmailVerification,
)

MAX_OTP_ATTEMPTS = 5


class OtpService:
    """Manages OTP lifecycle for a user."""

    def __init__(self, session: AsyncSession):
        self._session = session

    def generate(self) -> str:
        """Return a 6-digit zero-padded code."""
        return f"{secrets.randbelow(1_000_000):06d}"

    async def create_for_user(self, user_id: int) -> str:
        """Invalidate old codes and create a new one. Returns the code."""
        # Mark previous unused codes as used
        await self._session.execute(
            update(EmailVerification)
            .where(
                EmailVerification.user_id == user_id,
                EmailVerification.is_used.is_(False),
            )
            .values(is_used=True)
        )

        code = self.generate()
        expires_at = datetime.now(timezone.utc) + timedelta(
            minutes=settings.otp_expire_minutes
        )
        self._session.add(
            EmailVerification(
                user_id=user_id,
                otp_code=code,
                expires_at=expires_at,
                is_used=False,
                attempts=0,
            )
        )
        await self._session.flush()
        return code

    async def verify(self, user_id: int, code: str) -> None:
        """
        Validate an OTP.

        Brute-force protection:
          • Every wrong guess increments `attempts`.
          • After MAX_OTP_ATTEMPTS wrong guesses the code is invalidated.
          • Wrong guesses return the SAME error as expired codes so an
            attacker cannot distinguish the two cases.

        IMPORTANT — we commit the counter increment BEFORE raising.
        FastAPI calls `session.rollback()` on any uncaught exception,
        which would otherwise discard the increment and let an attacker
        guess forever.
        """
        result = await self._session.execute(
            select(EmailVerification)
            .where(
                EmailVerification.user_id == user_id,
                EmailVerification.is_used.is_(False),
            )
            .order_by(EmailVerification.created_at.desc())
            .limit(1)
        )
        row = result.scalar_one_or_none()

        if row is None:
            raise BadRequestException("Invalid or expired OTP code.")

        now = datetime.now(timezone.utc)

        # Expired → invalidate, reject
        if row.expires_at < now:
            row.is_used = True
            await self._session.commit()
            raise BadRequestException("Invalid or expired OTP code.")

        # Already exhausted attempts → invalidate, reject
        if row.attempts >= MAX_OTP_ATTEMPTS:
            row.is_used = True
            await self._session.commit()
            raise BadRequestException(
                "Too many incorrect attempts. Please request a new code."
            )

        # Wrong code → increment (and invalidate on last allowed try)
        if row.otp_code != code:
            row.attempts += 1
            if row.attempts >= MAX_OTP_ATTEMPTS:
                row.is_used = True
            # ★ COMMIT before raising — otherwise the increment is lost.
            await self._session.commit()
            raise BadRequestException("Invalid or expired OTP code.")

        # Correct code → mark as used
        row.is_used = True
        await self._session.flush()
    async def get_latest_unused(self, user_id: int) -> str | None:
        """[DEBUG ONLY] Return the latest unused, unexpired OTP for a user."""
        result = await self._session.execute(
            select(EmailVerification)
            .where(
                EmailVerification.user_id == user_id,
                EmailVerification.is_used.is_(False),
                EmailVerification.expires_at > datetime.now(timezone.utc),
            )
            .order_by(EmailVerification.created_at.desc())
            .limit(1)
        )
        row = result.scalar_one_or_none()
        return row.otp_code if row else None