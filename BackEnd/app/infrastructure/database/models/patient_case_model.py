"""
PatientCase ORM model.

Design notes:
- `symptoms`, `image_urls`, `alternate_conditions`, `red_flags` use
  PostgreSQL ARRAY columns — no join tables, no N+1.
- Composite indexes cover the three main read patterns.
- Diagnosis snapshot columns are frozen at creation time so the
  historical record survives engine improvements.
"""
import enum
from datetime import datetime

from sqlalchemy import (
    ARRAY, Enum as SAEnum, Float, ForeignKey, Index, Integer, String, Text, DateTime,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.database.base import Base, TimestampMixin


class CaseStatusEnum(str, enum.Enum):
    PENDING = "pending"
    BOOKED = "booked"
    COMPLETED = "completed"
    VERIFIED = "verified"


class CaseUrgencyEnum(str, enum.Enum):
    ROUTINE = "routine"
    SOON = "soon"
    URGENT = "urgent"
    EMERGENCY = "emergency"


class PatientCaseModel(Base, TimestampMixin):
    __tablename__ = "patient_cases"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    patient_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True,
    )
    doctor_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True,
    )

    # Clinical data
    symptoms: Mapped[list[str]] = mapped_column(
        ARRAY(String(200)), nullable=False, default=list,
    )
    suspected_condition: Mapped[str] = mapped_column(
        String(100), nullable=False, index=True,
    )
    image_urls: Mapped[list[str]] = mapped_column(
        ARRAY(Text), nullable=False, default=list,
    )

    location: Mapped[str] = mapped_column(String(50), nullable=False)
    pain_level: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    swelling_level: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)

    # Diagnosis snapshot (frozen at creation)
    diagnosis_confidence: Mapped[float] = mapped_column(
        Float, nullable=False, default=0.0,
    )
    alternate_conditions: Mapped[list[str]] = mapped_column(
        ARRAY(String(100)), nullable=False, default=list,
    )
    urgency: Mapped[CaseUrgencyEnum] = mapped_column(
        SAEnum(
            CaseUrgencyEnum,
            name="case_urgency_enum",
            values_callable=lambda x: [e.value for e in x],  # ★
        ),
        default=CaseUrgencyEnum.ROUTINE,
        nullable=False,
    )

    red_flags: Mapped[list[str]] = mapped_column(
        ARRAY(String(200)), nullable=False, default=list,
    )
    # ─── Completion / verification lifecycle ───────────────
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, index=True,
    )
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True,
    )
    verified_by_admin_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    verification_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Lifecycle
    status: Mapped[CaseStatusEnum] = mapped_column(
        SAEnum(
            CaseStatusEnum,
            name="case_status_enum",
            values_callable=lambda x: [e.value for e in x],  # ★
        ),
        default=CaseStatusEnum.PENDING,
        nullable=False,
    )

    __table_args__ = (
        Index("ix_cases_status_created", "status", "created_at"),
        Index("ix_cases_patient_status", "patient_id", "status"),
        Index("ix_cases_doctor_status", "doctor_id", "status"),
        Index("ix_cases_urgency", "urgency"),
        Index("ix_cases_verified_at", "verified_at"),
        Index("ix_cases_completed_at", "completed_at"),
    )

    def __repr__(self) -> str:
        return (
            f"<PatientCase id={self.id} patient={self.patient_id} "
            f"status={self.status.value}>"
        )