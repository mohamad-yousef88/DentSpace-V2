"""Appointment domain entity."""
from dataclasses import dataclass
from datetime import datetime
from enum import Enum


class AppointmentStatus(str, Enum):
    PENDING   = "pending"      # بانتظار رد المريض
    APPROVED  = "approved"     # المريض وافق
    REJECTED  = "rejected"     # المريض رفض
    CANCELLED = "cancelled"    # أحد الطرفين ألغى
    COMPLETED = "completed"    # انتهى العلاج (يُحدَّث مع الحالة)


@dataclass
class Appointment:
    case_id: int
    patient_id: int
    doctor_id: int
    status: AppointmentStatus = AppointmentStatus.PENDING
    rejection_reason: str | None = None

    id: int | None = None
    responded_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None

    @property
    def is_pending(self) -> bool:
        return self.status == AppointmentStatus.PENDING

    @property
    def is_approved(self) -> bool:
        return self.status == AppointmentStatus.APPROVED