"""
Scheduled cleanup jobs — prevent unbounded DB growth.

Retention policy:
    READ_NOTIFICATIONS_RETENTION_DAYS      = 7
    UNREAD_NOTIFICATIONS_RETENTION_DAYS    = 90
    CANCELLED_APPOINTMENTS_RETENTION_DAYS  = 30
    CANCELLED_ORDERS_RETENTION_DAYS        = 30
    OTP_RETENTION_HOURS                    = 24

Permanent records (intentionally NEVER deleted):
    • verified patient cases       (academic audit trail)
    • completed appointments       (linked to verified cases)
    • completed orders             (sales history for tools)
    • sold tools                   (referenced by completed orders)
    • all users                    (referenced by everything)

Every job:
- Runs in its own session.
- Logs how many rows it removed.
- Never crashes the scheduler (catches + logs).
"""
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import delete, or_

from app.infrastructure.database.models.appointment_model import (
    AppointmentModel, AppointmentStatusEnum,
)
from app.infrastructure.database.models.email_verification_model import (
    EmailVerification,
)
from app.infrastructure.database.models.notification_model import NotificationModel
from app.infrastructure.database.models.order_model import (
    OrderModel, OrderStatusEnum,
)
from app.infrastructure.database.session import AsyncSessionLocal

logger = logging.getLogger(__name__)


# ═══════════════════════════════════════════════════════════════
# Retention windows (days unless otherwise noted)
# ═══════════════════════════════════════════════════════════════
READ_NOTIF_DAYS = 7
UNREAD_NOTIF_DAYS = 90
APPOINTMENT_DAYS = 30
ORDER_DAYS = 30
OTP_HOURS = 24


# ═══════════════════════════════════════════════════════════════
# Job 1 — notifications
# ═══════════════════════════════════════════════════════════════
async def cleanup_notifications() -> None:
    """
    Delete old notifications:
      • read notifications        older than READ_NOTIF_DAYS
      • unread notifications      older than UNREAD_NOTIF_DAYS
    """
    now = datetime.now(timezone.utc)
    read_cutoff = now - timedelta(days=READ_NOTIF_DAYS)
    unread_cutoff = now - timedelta(days=UNREAD_NOTIF_DAYS)

    async with AsyncSessionLocal() as session:
        try:
            result = await session.execute(
                delete(NotificationModel).where(
                    or_(
                        (NotificationModel.is_read.is_(True))
                        & (NotificationModel.updated_at < read_cutoff),
                        (NotificationModel.is_read.is_(False))
                        & (NotificationModel.created_at < unread_cutoff),
                    )
                )
            )
            removed = result.rowcount or 0
            await session.commit()
            logger.info("[cleanup_notifications] removed %d rows", removed)
        except Exception as exc:
            await session.rollback()
            logger.exception("[cleanup_notifications] failed: %s", exc)


# ═══════════════════════════════════════════════════════════════
# Job 2 — cancelled / rejected appointments
# ═══════════════════════════════════════════════════════════════
async def cleanup_appointments() -> None:
    """
    Delete cancelled or rejected appointments older than APPOINTMENT_DAYS.

    Completed appointments are NEVER touched — they form part of the
    academic record for the assigned doctor.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(days=APPOINTMENT_DAYS)

    async with AsyncSessionLocal() as session:
        try:
            result = await session.execute(
                delete(AppointmentModel).where(
                    AppointmentModel.status.in_([
                        AppointmentStatusEnum.CANCELLED,
                        AppointmentStatusEnum.REJECTED,
                    ]),
                    AppointmentModel.updated_at < cutoff,
                )
            )
            removed = result.rowcount or 0
            await session.commit()
            logger.info("[cleanup_appointments] removed %d rows", removed)
        except Exception as exc:
            await session.rollback()
            logger.exception("[cleanup_appointments] failed: %s", exc)


# ═══════════════════════════════════════════════════════════════
# Job 3 — cancelled / rejected tool orders
# ═══════════════════════════════════════════════════════════════
async def cleanup_orders() -> None:
    """
    Delete cancelled or rejected tool orders older than ORDER_DAYS.

    Completed orders are NEVER touched — they form part of the sales
    history for the seller and the buyer.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(days=ORDER_DAYS)

    async with AsyncSessionLocal() as session:
        try:
            result = await session.execute(
                delete(OrderModel).where(
                    OrderModel.status.in_([
                        OrderStatusEnum.CANCELLED,
                        OrderStatusEnum.REJECTED,
                    ]),
                    OrderModel.updated_at < cutoff,
                )
            )
            removed = result.rowcount or 0
            await session.commit()
            logger.info("[cleanup_orders] removed %d rows", removed)
        except Exception as exc:
            await session.rollback()
            logger.exception("[cleanup_orders] failed: %s", exc)


# ═══════════════════════════════════════════════════════════════
# Job 4 — expired / used OTPs
# ═══════════════════════════════════════════════════════════════
async def cleanup_otps() -> None:
    """
    Delete used OTPs or OTPs expired more than OTP_HOURS ago.
    """
    cutoff = datetime.now(timezone.utc) - timedelta(hours=OTP_HOURS)

    async with AsyncSessionLocal() as session:
        try:
            result = await session.execute(
                delete(EmailVerification).where(
                    or_(
                        EmailVerification.is_used.is_(True),
                        EmailVerification.expires_at < cutoff,
                    )
                )
            )
            removed = result.rowcount or 0
            await session.commit()
            logger.info("[cleanup_otps] removed %d rows", removed)
        except Exception as exc:
            await session.rollback()
            logger.exception("[cleanup_otps] failed: %s", exc)