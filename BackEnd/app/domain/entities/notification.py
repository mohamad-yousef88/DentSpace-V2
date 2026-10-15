"""Notification domain entity."""
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum


class NotificationType(str, Enum):
    # Appointment lifecycle
    APPOINTMENT_REQUEST   = "appointment_request"
    APPOINTMENT_APPROVED  = "appointment_approved"
    APPOINTMENT_REJECTED  = "appointment_rejected"
    APPOINTMENT_CANCELLED = "appointment_cancelled"
    # Case lifecycle
    CASE_COMPLETED        = "case_completed"
    CASE_VERIFIED         = "case_verified"
    CASE_REJECTED         = "case_rejected"
    # Tool order lifecycle
    TOOL_ORDER_REQUEST    = "tool_order_request"
    TOOL_ORDER_APPROVED   = "tool_order_approved"
    TOOL_ORDER_REJECTED   = "tool_order_rejected"
    TOOL_ORDER_CANCELLED  = "tool_order_cancelled"
    TOOL_SOLD             = "tool_sold"
    # Generic
    SYSTEM                = "system"


@dataclass
class Notification:
    user_id: int
    title: str
    type: NotificationType
    body: str | None = None
    payload: dict | None = None       # JSONB — contextual data

    id: int | None = None
    is_read: bool = False
    created_at: datetime | None = None
    updated_at: datetime | None = None