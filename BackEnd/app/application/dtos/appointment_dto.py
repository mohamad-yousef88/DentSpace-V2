"""Appointment DTOs."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.domain.entities.appointment import AppointmentStatus
from app.domain.entities.patient_case import CaseStatus, CaseUrgency


# ═══════════════════════════════════════════════════════════════
# Requests
# ═══════════════════════════════════════════════════════════════
class CreateAppointmentRequest(BaseModel):
    case_id: int = Field(..., gt=0)


# ═══════════════════════════════════════════════════════════════
# Responses
# ═══════════════════════════════════════════════════════════════
class AppointmentCaseBrief(BaseModel):
    """Compact case info attached to every appointment response."""
    id: int
    suspected_condition: str
    location: str
    urgency: CaseUrgency
    status: CaseStatus
    image_urls: list[str]


class AppointmentUserBrief(BaseModel):
    id: int
    full_name: str
    phone: str


class AppointmentResponse(BaseModel):
    id: int
    status: AppointmentStatus
    responded_at: Optional[datetime] = None
    created_at: datetime

    case: AppointmentCaseBrief
    patient: Optional[AppointmentUserBrief] = None
    doctor: Optional[AppointmentUserBrief] = None

    model_config = {"from_attributes": True}


class AppointmentListResponse(BaseModel):
    items: list[AppointmentResponse]
    count: int
    offset: int
    limit: int
class DoctorStatsResponse(BaseModel):
    """
    Doctor dashboard counters.

    Definitions (product-agreed):
      • active_requests  — appointments awaiting patient response.
      • ongoing_bookings — approved OR completed-but-not-yet-verified.
      • verified_cases   — cases verified by admin.
    """
    active_requests: int
    ongoing_bookings: int
    verified_cases: int