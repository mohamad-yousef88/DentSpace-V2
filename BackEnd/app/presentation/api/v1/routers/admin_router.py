"""
Admin router — user management, case verification, statistics.

Every endpoint in this router requires UserRole.ADMIN.
"""
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.application.dtos.admin_dto import (
    AdminCaseListResponse,
    AdminUserListResponse,
    AdminUserResponse,
    StatsResponse,
    ToggleUserActiveRequest,
)
from app.application.dtos.case_dto import VerifyTreatmentRequest
from app.application.dtos.auth_dto import MessageResponse
from app.core.dependencies import AdminSvc, require_role
from app.domain.entities.patient_case import CaseStatus
from app.domain.entities.user import User, UserRole

router = APIRouter(
    dependencies=[Depends(require_role(UserRole.ADMIN))],
)


# ═══════════════════════════════════════════════════════════════
# Users
# ═══════════════════════════════════════════════════════════════
@router.get(
    "/users",
    response_model=AdminUserListResponse,
    summary="List users (filterable)",
)
async def list_users(
    admin: AdminSvc,
    role: UserRole | None = Query(None),
    is_active: bool | None = Query(None),
    search: str | None = Query(None),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    users = await admin.list_users(
        role=role, is_active=is_active, search=search,
        offset=offset, limit=limit,
    )
    return AdminUserListResponse(
        items=[AdminUserResponse.model_validate(u.__dict__) for u in users],
        count=len(users), offset=offset, limit=limit,
    )


@router.patch(
    "/users/{user_id}/active",
    response_model=AdminUserResponse,
    summary="Enable or disable a user account",
)
async def toggle_user_active(
    user_id: int,
    payload: ToggleUserActiveRequest,
    admin: Annotated[User, Depends(require_role(UserRole.ADMIN))],
    svc: AdminSvc,
):
    user = await svc.toggle_user_active(admin, user_id, payload.is_active)
    return AdminUserResponse.model_validate(user.__dict__)


# ═══════════════════════════════════════════════════════════════
# Cases
# ═══════════════════════════════════════════════════════════════
@router.get(
    "/cases",
    response_model=AdminCaseListResponse,
    summary="List cases for review",
)
async def list_cases(
    admin: AdminSvc,
    status_filter: CaseStatus | None = Query(None, alias="status"),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    items = await admin.list_cases(
        status=status_filter, offset=offset, limit=limit,
    )
    return AdminCaseListResponse(
        items=items, count=len(items), offset=offset, limit=limit,
    )


@router.post(
    "/cases/{case_id}/verify",
    response_model=MessageResponse,
    summary="Approve or reject a completed case",
)
async def verify_case(
    case_id: int,
    payload: VerifyTreatmentRequest,
    admin: Annotated[User, Depends(require_role(UserRole.ADMIN))],
    svc: AdminSvc,
):
    await svc.verify_case(admin, case_id, payload.approve, payload.notes)
    msg = "Case verified." if payload.approve else "Case returned to the doctor."
    return MessageResponse(message=msg)


# ═══════════════════════════════════════════════════════════════
# Statistics
# ═══════════════════════════════════════════════════════════════
@router.get(
    "/stats",
    response_model=StatsResponse,
    summary="Dashboard statistics",
)
async def get_stats(admin: AdminSvc):
    return StatsResponse(**await admin.get_stats())