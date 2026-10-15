"""Admin cases review."""
from __future__ import annotations

from fastapi import APIRouter, Form, Query, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from app.application.services.admin_service import AdminService
from app.domain.entities.patient_case import CaseStatus
from app.infrastructure.database.session import AsyncSessionLocal
from app.presentation.admin.context import base_context, flash
from app.presentation.admin.dependencies import CurrentAdmin
from app.presentation.admin.templates import templates


router = APIRouter()


@router.get("", response_class=HTMLResponse, include_in_schema=False)
async def list_cases(
    request: Request,
    admin: CurrentAdmin,
    status: str | None = Query(None),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
) -> HTMLResponse:
    status_enum = None
    if status and status in {s.value for s in CaseStatus}:
        status_enum = CaseStatus(status)

    async with AsyncSessionLocal() as db:
        svc = AdminService(db)
        cases = await svc.list_cases(
            status=status_enum,
            offset=offset,
            limit=limit,
        )

    ctx = base_context(request)
    ctx.update({
        "current_admin": admin,
        "cases": cases,
        "status_filter": status or "",
        "offset": offset,
        "limit": limit,
    })
    return templates.TemplateResponse(
        request=request,
        name="pages/cases/list.html",
        context=ctx,
    )


@router.get("/{case_id}", response_class=HTMLResponse, include_in_schema=False)
async def case_detail(
    request: Request,
    admin: CurrentAdmin,
    case_id: int,
) -> HTMLResponse:
    from app.infrastructure.repositories.case_repository_impl import (
        CaseRepositoryImpl,
    )
    from app.infrastructure.repositories.user_repository_impl import (
        UserRepositoryImpl,
    )

    async with AsyncSessionLocal() as db:
        case = await CaseRepositoryImpl(db).get_by_id(case_id)
        if case is None:
            flash(request, "Case not found", "error")
            return RedirectResponse(url="/admin/cases", status_code=303)

        users = UserRepositoryImpl(db)
        patient = await users.get_by_id(case.patient_id)
        doctor = await users.get_by_id(case.doctor_id) if case.doctor_id else None

    ctx = base_context(request)
    ctx.update({
        "current_admin": admin,
        "case": case,
        "patient": patient,
        "doctor": doctor,
    })
    return templates.TemplateResponse(
        request=request,
        name="pages/cases/detail.html",
        context=ctx,
    )


@router.post("/{case_id}/verify", include_in_schema=False)
async def verify_case(
    request: Request,
    admin: CurrentAdmin,
    case_id: int,
    approve: str = Form(...),
    notes: str = Form(""),
):
    approved = approve.lower() in ("true", "1", "yes", "approve")

    async with AsyncSessionLocal() as db:
        svc = AdminService(db)
        try:
            await svc.verify_case(admin, case_id, approved, notes.strip() or None)
            await db.commit()
            flash(
                request,
                "Case verified" if approved else "Case returned",
                "success",
            )
        except Exception as exc:
            flash(request, str(exc), "error")

    return RedirectResponse(url="/admin/cases", status_code=303)