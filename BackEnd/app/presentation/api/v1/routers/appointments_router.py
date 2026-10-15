"""Appointment router."""
from fastapi import APIRouter, Query, status

from app.application.dtos.appointment_dto import (
    AppointmentListResponse, AppointmentResponse, CreateAppointmentRequest,
)
from app.core.dependencies import AppointmentSvc, CurrentUser
from app.domain.entities.appointment import AppointmentStatus

router = APIRouter()


@router.post(
    "",
    response_model=AppointmentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create an appointment request (doctor only)",
)
async def create_appointment(
    payload: CreateAppointmentRequest,
    user: CurrentUser,
    svc: AppointmentSvc,
):
    appt = await svc.create_appointment(user, payload.case_id)
    enriched = await svc.enrich([appt])
    return enriched[0]


@router.get(
    "",
    response_model=AppointmentListResponse,
    summary="List appointments (role-aware)",
)
async def list_appointments(
    user: CurrentUser,
    svc: AppointmentSvc,
    mine: bool = Query(True, description="Doctor: limit to my own"),
    status_filter: AppointmentStatus | None = Query(None, alias="status"),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    items = await svc.list_appointments(
        user, mine=mine, status=status_filter,
        offset=offset, limit=limit,
    )
    enriched = await svc.enrich(items)
    return AppointmentListResponse(
        items=enriched, count=len(enriched), offset=offset, limit=limit,
    )
from app.application.dtos.appointment_dto import (
    AppointmentListResponse, AppointmentResponse,
    CreateAppointmentRequest, DoctorStatsResponse,
)

# ═══════════════════════════════════════════════════════════════
# Doctor — dashboard counters
# ═══════════════════════════════════════════════════════════════
@router.get(
    "/me/stats",
    response_model=DoctorStatsResponse,
    summary="Doctor dashboard counters",
)
async def doctor_stats(user: CurrentUser, svc: AppointmentSvc):
    return DoctorStatsResponse(**await svc.get_doctor_stats(user))
async def get_appointment(
    appointment_id: int, user: CurrentUser, svc: AppointmentSvc,
):
    appt = await svc.get_appointment(user, appointment_id)
    enriched = await svc.enrich([appt])
    return enriched[0]


# ═══════════════════════════════════════════════════════════════
# Patient actions
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/{appointment_id}/approve",
    response_model=AppointmentResponse,
    summary="Approve a pending request (patient only)",
)
async def approve(
    appointment_id: int, user: CurrentUser, svc: AppointmentSvc,
):
    appt = await svc.approve(user, appointment_id)
    enriched = await svc.enrich([appt])
    return enriched[0]


@router.post(
    "/{appointment_id}/reject",
    response_model=AppointmentResponse,
    summary="Reject a pending request (patient only)",
)
async def reject(
    appointment_id: int, user: CurrentUser, svc: AppointmentSvc,
):
    appt = await svc.reject(user, appointment_id)
    enriched = await svc.enrich([appt])
    return enriched[0]


# ═══════════════════════════════════════════════════════════════
# Doctor action — complete treatment
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/{appointment_id}/complete",
    response_model=AppointmentResponse,
    summary="Mark treatment as completed (assigned doctor only)",
)
async def complete(
    appointment_id: int, user: CurrentUser, svc: AppointmentSvc,
):
    appt = await svc.complete(user, appointment_id)
    enriched = await svc.enrich([appt])
    return enriched[0]


# ═══════════════════════════════════════════════════════════════
# Either party — cancel
# ═══════════════════════════════════════════════════════════════
@router.delete(
    "/{appointment_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Cancel an appointment (either party)",
)
async def cancel(
    appointment_id: int, user: CurrentUser, svc: AppointmentSvc,
):
    await svc.cancel(user, appointment_id)