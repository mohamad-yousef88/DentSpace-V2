"""
Email service — sends OTP and notification emails via SMTP (Gmail).
"""
import logging
from email.message import EmailMessage

import aiosmtplib

from app.core.config import settings

logger = logging.getLogger(__name__)


class EmailService:
    """Async SMTP email sender."""

    def __init__(self) -> None:
        self._host = settings.smtp_host
        self._port = settings.smtp_port
        self._user = settings.smtp_user
        self._password = settings.smtp_password
        self._from_name = settings.smtp_from_name

    @property
    def is_configured(self) -> bool:
        return bool(self._user and self._password)

    async def _send(self, to: str, subject: str, html_body: str) -> None:
        if not self.is_configured:
            logger.warning(
                "SMTP not configured — skipping email to %s (subject: %s)",
                to, subject,
            )
            return

        message = EmailMessage()
        message["From"] = f"{self._from_name} <{self._user}>"
        message["To"] = to
        message["Subject"] = subject
        message.set_content("Please use an HTML-capable email client.")
        message.add_alternative(html_body, subtype="html")

        try:
            await aiosmtplib.send(
                message,
                hostname=self._host,
                port=self._port,
                start_tls=True,
                username=self._user,
                password=self._password,
                timeout=15,
            )
            logger.info("Email sent to %s — %s", to, subject)
        except Exception as exc:  # pragma: no cover
            logger.error("Failed to send email to %s: %s", to, exc)
            raise

    async def send_otp_email(self, to: str, otp: str, purpose: str) -> None:
        """Send a 6-digit OTP for email verification or password reset."""
        subject_map = {
            "verify": "DentSpace — Email Verification Code",
            "reset": "DentSpace — Password Reset Code",
        }
        subject = subject_map.get(purpose, "DentSpace — Verification Code")

        html = f"""
        <div style="font-family: Arial, sans-serif; max-width: 500px;
                    margin: auto; padding: 24px; border-radius: 12px;
                    background: #F8FAFC; border: 1px solid #E2E8F0;">
          <h2 style="color: #0D6EFD; text-align: center;">DentSpace</h2>
          <p style="color: #1A1A1A; font-size: 15px;">
            Your verification code is:
          </p>
          <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px;
                      text-align: center; color: #0D6EFD; padding: 16px;
                      background: #FFFFFF; border-radius: 8px;
                      border: 1px dashed #0D6EFD;">
            {otp}
          </div>
          <p style="color: #6B7280; font-size: 13px; margin-top: 16px;">
            This code expires in {settings.otp_expire_minutes} minutes.
            If you didn't request this, ignore this email.
          </p>
        </div>
        """
        await self._send(to, subject, html)


# Singleton
email_service = EmailService()