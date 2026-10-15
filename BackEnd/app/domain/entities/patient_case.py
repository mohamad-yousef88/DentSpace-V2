"""
PatientCase domain entity + CaseStatus enum.

Pure Python — no ORM, no framework.

Design note:
    The diagnosis snapshot (condition, confidence, alternatives, urgency,
    red_flags) is stored at creation time. This preserves a historical
    record even if the diagnostic engine improves later.
"""
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum


class CaseStatus(str, Enum):
    PENDING = "pending"        # قيد الانتظار — بانتظار طبيب
    BOOKED = "booked"          # تم الحجز — طبيب قبلها
    COMPLETED = "completed"    # انتهى العلاج (الطالب أكّد)
    VERIFIED = "verified"      # تم تأكيد العلاج (الأدمن وافق)


class CaseUrgency(str, Enum):
    ROUTINE = "routine"        # روتيني — يمكن الانتظار
    SOON = "soon"              # خلال أيام
    URGENT = "urgent"          # خلال 24-48 ساعة
    EMERGENCY = "emergency"    # فوراً — توجه للطوارئ


@dataclass
class PatientCase:
    """A patient's dental case."""

    # Required at creation
    patient_id: int
    symptoms: list[str]
    suspected_condition: str
    location: str

    # Optional clinical data
    pain_level: float = 0.0
    swelling_level: float = 0.0

    # Diagnosis snapshot (from the analyzer at creation time)
    diagnosis_confidence: float = 0.0           # 0.0 – 1.0
    alternate_conditions: list[str] = field(default_factory=list)
    urgency: CaseUrgency = CaseUrgency.ROUTINE
    red_flags: list[str] = field(default_factory=list)

    # Identity
    id: int | None = None
    doctor_id: int | None = None
    image_urls: list[str] = field(default_factory=list)
    status: CaseStatus = CaseStatus.PENDING

    # Audit
    created_at: datetime | None = None
    updated_at: datetime | None = None
    completed_at: datetime | None = None
    verified_at: datetime | None = None
    verified_by_admin_id: int | None = None
    verification_notes: str | None = None

    # ─── Helpers ──────────────────────────────────────────
    @property
    def has_pain(self) -> bool:
        return self.pain_level > 0

    @property
    def has_swelling(self) -> bool:
        return self.swelling_level > 0

    @property
    def is_pending(self) -> bool:
        return self.status == CaseStatus.PENDING

    @property
    def is_booked(self) -> bool:
        return self.status == CaseStatus.BOOKED

    @property
    def is_emergency(self) -> bool:
        return self.urgency == CaseUrgency.EMERGENCY
    @property
    def is_completed(self) -> bool:
        return self.status == CaseStatus.COMPLETED

    @property
    def is_verified(self) -> bool:
        return self.status == CaseStatus.VERIFIED