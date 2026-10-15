"""Admin DTOs — user management, statistics, case verification."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.domain.entities.patient_case import CaseStatus, CaseUrgency
from app.domain.entities.user import Gender, UserRole


# ═══════════════════════════════════════════════════════════════
# Users
# ═══════════════════════════════════════════════════════════════
class AdminUserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    phone: str
    role: UserRole
    gender: Optional[Gender] = None
    age: Optional[int] = None
    university_id: Optional[str] = None
    is_active: bool
    is_email_verified: bool
    is_verified_by_admin: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class AdminUserListResponse(BaseModel):
    items: list[AdminUserResponse]
    count: int
    offset: int
    limit: int


class ToggleUserActiveRequest(BaseModel):
    is_active: bool


# ═══════════════════════════════════════════════════════════════
# Cases for admin review
# ═══════════════════════════════════════════════════════════════
class AdminCaseResponse(BaseModel):
    id: int
    patient_id: int
    doctor_id: Optional[int] = None

    symptoms: list[str]
    suspected_condition: str
    image_urls: list[str]
    location: str
    pain_level: float
    swelling_level: float
    diagnosis_confidence: float
    urgency: CaseUrgency
    red_flags: list[str]

    status: CaseStatus
    completed_at: Optional[datetime] = None
    verified_at: Optional[datetime] = None
    verification_notes: Optional[str] = None

    # Enriched
    patient_name: Optional[str] = None
    patient_phone: Optional[str] = None
    doctor_name: Optional[str] = None
    doctor_university_id: Optional[str] = None

    created_at: datetime


class AdminCaseListResponse(BaseModel):
    items: list[AdminCaseResponse]
    count: int
    offset: int
    limit: int


# ═══════════════════════════════════════════════════════════════
# Statistics
# ═══════════════════════════════════════════════════════════════
class StatsResponse(BaseModel):
    users: dict[str, int]              # {role: count}
    cases: dict[str, int]              # {status: count}
    appointments: dict[str, int]       # {status: count}
    orders: dict[str, int]             # {status: count}
    tools: dict[str, int]              # {status: count}
    pending_verifications: int         # cases awaiting admin review