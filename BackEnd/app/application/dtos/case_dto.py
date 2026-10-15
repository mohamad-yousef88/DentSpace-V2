"""
PatientCase DTOs — reflect the enriched diagnosis snapshot.
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.domain.entities.patient_case import CaseStatus, CaseUrgency


# ═══════════════════════════════════════════════════════════════
# Requests
# ═══════════════════════════════════════════════════════════════
class PreviewDiagnosisRequest(BaseModel):
    symptoms: list[str] = Field(..., min_length=1)
    location: str = Field(..., min_length=1, max_length=50)
    has_pain: bool
    pain_severity: Optional[str] = None
    has_swelling: bool
    swelling_severity: Optional[str] = None


class CreateCaseRequest(PreviewDiagnosisRequest):
    """Same shape as preview — patient confirms and saves."""
    suspected_condition: Optional[str] = Field(None, max_length=100)


class UpdateCaseRequest(BaseModel):
    symptoms: Optional[list[str]] = None
    location: Optional[str] = Field(None, min_length=1, max_length=50)
    has_pain: Optional[bool] = None
    pain_severity: Optional[str] = None
    has_swelling: Optional[bool] = None
    swelling_severity: Optional[str] = None
    suspected_condition: Optional[str] = Field(None, max_length=100)
class CompleteTreatmentRequest(BaseModel):
    """Doctor marks the treatment as done."""
    notes: Optional[str] = Field(None, max_length=1000)


class VerifyTreatmentRequest(BaseModel):
    """Admin approves or rejects the treatment."""
    approve: bool
    notes: Optional[str] = Field(None, max_length=1000)


# ═══════════════════════════════════════════════════════════════
# Responses
# ═══════════════════════════════════════════════════════════════
class DiagnosisMatchDTO(BaseModel):
    key: str
    name_ar: str
    confidence: float
    confidence_pct: int
    category: str
    urgency: CaseUrgency
    notes_ar: str
    recommendation_ar: str


class DiagnosisPreviewResponse(BaseModel):
    primary: DiagnosisMatchDTO
    alternatives: list[DiagnosisMatchDTO]
    urgency: CaseUrgency
    red_flags: list[str]
    warnings: list[str]
    emergency_instructions: list[str]


class CaseResponse(BaseModel):
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
    alternate_conditions: list[str]
    urgency: CaseUrgency
    red_flags: list[str]
    completed_at: Optional[datetime] = None
    verified_at: Optional[datetime] = None
    verification_notes: Optional[str] = None

    status: CaseStatus
    created_at: datetime
    updated_at: datetime

    patient_name: Optional[str] = None
    patient_phone: Optional[str] = None

    model_config = {"from_attributes": True}


class CaseListResponse(BaseModel):
    items: list[CaseResponse]
    count: int
    offset: int
    limit: int