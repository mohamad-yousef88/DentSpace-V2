"""Appointment ORM model."""
import enum
from datetime import datetime

from sqlalchemy import (
    DateTime, Enum as SAEnum, ForeignKey, Index, Integer, Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.database.base import Base, TimestampMixin


class AppointmentStatusEnum(str, enum.Enum):
    PENDING   = "pending"
    APPROVED  = "approved"
    REJECTED  = "rejected"
    CANCELLED = "cancelled"
    COMPLETED = "completed"


class AppointmentModel(Base, TimestampMixin):
    __tablename__ = "appointments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    case_id: Mapped[int] = mapped_column(
        ForeignKey("patient_cases.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )
    patient_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )
    doctor_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )

    status: Mapped[AppointmentStatusEnum] = mapped_column(
        SAEnum(
            AppointmentStatusEnum,
            name="appointment_status_enum",
            values_callable=lambda x: [e.value for e in x],
        ),
        default=AppointmentStatusEnum.PENDING,
        nullable=False,
    )
    responded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True,
    )
    rejection_reason: Mapped[str | None] = mapped_column(
        Text, nullable=True,
    )

    __table_args__ = (
        Index("ix_appointments_case_status", "case_id", "status"),
        Index("ix_appointments_patient_status", "patient_id", "status"),
        Index("ix_appointments_doctor_status", "doctor_id", "status"),
    )

    def __repr__(self) -> str:
        return (
            f"<Appointment id={self.id} case={self.case_id} "
            f"doctor={self.doctor_id} status={self.status.value}>"
        )