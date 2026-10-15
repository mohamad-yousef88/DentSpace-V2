"""Admin doctors — list, detail, create."""
from __future__ import annotations

from fastapi import APIRouter, Form, Query, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from app.application.dtos.auth_dto import CreateDoctorRequest
from app.application.services.auth_service import AuthService
from app.domain.entities.user import Gender, UserRole
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl
from app.presentation.admin.context import base_context, flash
from app.presentation.admin.dependencies import CurrentAdmin
from app.presentation.admin.templates import templates


router = APIRouter()


@router.get("", response_class=HTMLResponse, include_in_schema=False)
async def list_doctors(
    request: Request,
    admin: CurrentAdmin,
    search: str | None = Query(None),
) -> HTMLResponse:
    async with AsyncSessionLocal() as db:
        doctors = await UserRepositoryImpl(db).list_users(
            role=UserRole.DOCTOR, is_active=None, search=search,
            offset=0, limit=100,
        )

    ctx = base_context(request)
    ctx.update({
        "current_admin": admin,
        "doctors": doctors,
        "search_query": search or "",
    })
    return templates.TemplateResponse(
        request=request, name="pages/doctors/list.html", context=ctx,
    )


@router.get("/new", response_class=HTMLResponse, include_in_schema=False)
async def new_doctor(request: Request, admin: CurrentAdmin) -> HTMLResponse:
    ctx = base_context(request)
    ctx["current_admin"] = admin
    return templates.TemplateResponse(
        request=request, name="pages/doctors/create.html", context=ctx,
    )


@router.get("/{doctor_id}", response_class=HTMLResponse, include_in_schema=False)
async def doctor_detail(
    request: Request,
    admin: CurrentAdmin,
    doctor_id: int,
) -> HTMLResponse:
    async with AsyncSessionLocal() as db:
        doctor = await UserRepositoryImpl(db).get_by_id(doctor_id)

    if doctor is None or doctor.role != UserRole.DOCTOR:
        flash(request, "Doctor not found", "error")
        return RedirectResponse("/admin/doctors", status_code=303)

    ctx = base_context(request)
    ctx.update({"current_admin": admin, "doctor": doctor})
    return templates.TemplateResponse(
        request=request, name="pages/doctors/detail.html", context=ctx,
    )


@router.post("/new", include_in_schema=False)
async def create_doctor(
    request: Request,
    admin: CurrentAdmin,
    full_name: str = Form(...),
    email: str = Form(...),
    phone: str = Form(...),
    password: str = Form(...),
    university_id: str = Form(...),
    gender: str = Form(...),
    age: int = Form(...),
):
    is_ar = request.cookies.get("dentspace_locale", "ar") == "ar"
    try:
        payload = CreateDoctorRequest(
            full_name=full_name.strip(),
            email=email.strip().lower(),
            phone=phone.strip(),
            password=password,
            university_id=university_id.strip(),
            gender=Gender(gender),
            age=age,
        )
        async with AsyncSessionLocal() as db:
            doctor = await AuthService(db).create_doctor(payload, admin_id=admin.id)
            await db.commit()

        flash(
            request,
            (f"تم إنشاء حساب الطبيب: {doctor.full_name}" if is_ar
             else f"Doctor created: {doctor.full_name}"),
            "success",
        )
        return RedirectResponse("/admin/doctors", status_code=303)
    except Exception as exc:
        flash(request, str(exc), "error")
        return RedirectResponse("/admin/doctors/new", status_code=303)