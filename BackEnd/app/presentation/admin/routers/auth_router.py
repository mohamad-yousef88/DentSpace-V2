"""Admin authentication — login, logout."""
from __future__ import annotations

from fastapi import APIRouter, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from app.application.services.auth_service import AuthService
from app.core.exceptions import UnauthorizedException
from app.core.security import verify_password
from app.domain.entities.user import UserRole
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl
from app.presentation.admin.context import base_context, flash
from app.presentation.admin.dependencies import SESSION_USER_KEY
from app.presentation.admin.templates import templates


router = APIRouter()


@router.get("/", include_in_schema=False)
async def root_redirect() -> RedirectResponse:
    return RedirectResponse(url="/admin/dashboard", status_code=302)


@router.get("/login", response_class=HTMLResponse, include_in_schema=False)
async def login_page(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request=request,
        name="pages/auth/login.html",
        context=base_context(request),
    )


@router.post("/login", include_in_schema=False)
async def login_submit(
    request: Request,
    email: str = Form(...),
    password: str = Form(...),
):
    email = email.strip().lower()

    async with AsyncSessionLocal() as db:
        repo = UserRepositoryImpl(db)
        user = await repo.get_by_email(email)

        if (
            user is None
            or not verify_password(password, user.hashed_password)
            or user.role != UserRole.ADMIN
            or not user.is_active
        ):
            flash(
                request,
                "البريد الإلكتروني أو كلمة المرور غير صحيحة"
                if request.cookies.get("dentspace_locale") == "ar"
                else "Invalid email or password",
                "error",
            )
            return RedirectResponse(url="/admin/login", status_code=303)

        # Success — persist user id in signed session cookie
        request.session[SESSION_USER_KEY] = user.id

    return RedirectResponse(url="/admin/dashboard", status_code=303)


@router.post("/logout", include_in_schema=False)
async def logout(request: Request):
    request.session.clear()
    return RedirectResponse(url="/admin/login", status_code=303)