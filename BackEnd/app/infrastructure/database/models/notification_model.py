"""Notification ORM model."""
import enum

from sqlalchemy import (
    Boolean, Enum as SAEnum, ForeignKey, Index, Integer, String, Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.database.base import Base, TimestampMixin


class NotificationTypeEnum(str, enum.Enum):
    APPOINTMENT_REQUEST = "appointment_request"
    APPOINTMENT_APPROVED = "appointment_approved"
    APPOINTMENT_REJECTED = "appointment_rejected"
    APPOINTMENT_CANCELLED = "appointment_cancelled"
    # Case lifecycle
    CASE_COMPLETED = "case_completed"
    CASE_VERIFIED = "case_verified"
    CASE_REJECTED = "case_rejected"
    # Tool order lifecycle
    TOOL_ORDER_REQUEST = "tool_order_request"
    TOOL_ORDER_APPROVED = "tool_order_approved"
    TOOL_ORDER_REJECTED = "tool_order_rejected"
    TOOL_ORDER_CANCELLED = "tool_order_cancelled"
    TOOL_SOLD = "tool_sold"
    # Generic
    SYSTEM = "system"


class NotificationModel(Base, TimestampMixin):
    __tablename__ = "notifications"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True,
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    body: Mapped[str | None] = mapped_column(Text, nullable=True)
    type: Mapped[NotificationTypeEnum] = mapped_column(
        SAEnum(
            NotificationTypeEnum,
            name="notification_type_enum",
            values_callable=lambda x: [e.value for e in x],
        ),
        nullable=False,
    )
    payload: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    is_read: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, index=True,
    )

    __table_args__ = (
        Index("ix_notifications_user_read", "user_id", "is_read"),
        Index("ix_notifications_user_created", "user_id", "created_at"),
    )