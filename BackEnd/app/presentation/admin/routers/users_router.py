"""Admin users management — list, detail, toggle, reset password, delete."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Form, Query, Request
from fastapi.responses import HTMLResponse, RedirectResponse

from app.application.services.admin_service import AdminService
from app.core.security import hash_password
from app.domain.entities.user import UserRole
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl
from app.presentation.admin.context import base_context, flash
from app.presentation.admin.dependencies import CurrentAdmin
from app.presentation.admin.templates import templates


router = APIRouter()

PAGE_SIZE = 20


@router.get("", response_class=HTMLResponse, include_in_schema=False)
async def list_users(
    request: Request,
    admin: CurrentAdmin,
    role: str | None = Query(None),
    is_active: str | None = Query(None),
    search: str | None = Query(None),
    offset: int = Query(0, ge=0),
    limit: int = Query(PAGE_SIZE, ge=1, le=100),
) -> HTMLResponse:
    role_enum = UserRole(role) if role in {r.value for r in UserRole} else None
    active_bool = True if is_active == "true" else (False if is_active == "false" else None)

    async with AsyncSessionLocal() as db:
        svc = AdminService(db)
        users = await svc.list_users(
            role=role_enum, is_active=active_bool, search=search,
            offset=offset, limit=limit,
        )
        # Count for pagination
        from sqlalchemy import func, select, or_
        from app.infrastructure.database.models.user_model import User as UserModel
        from app.infrastructure.database.models.user_model import UserRole as UserRoleModel

        count_stmt = select(func.count(UserModel.id))
        if role_enum is not None:
            count_stmt = count_stmt.where(UserModel.role == UserRoleModel(role_enum.value))
        if active_bool is not None:
            count_stmt = count_stmt.where(UserModel.is_active.is_(active_bool))
        if search:
            like = f"%{search.strip()}%"
            count_stmt = count_stmt.where(or_(
                UserModel.full_name.ilike(like),
                UserModel.email.ilike(like),
                UserModel.phone.ilike(like),
            ))
        r = await db.execute(count_stmt)
        total_count = int(r.scalar() or 0)

    ctx = base_context(request)
    ctx.update({
        "current_admin": admin,
        "users": users,
        "role_filter": role or "",
        "is_active_filter": is_active or "",
        "search_query": search or "",
        "offset": offset,
        "limit": limit,
        "total_count": total_count,
        "base_url": str(request.url).split("?")[0] + (
            "?" + str(request.url.query) if request.url.query else ""
        ),
    })
    return templates.TemplateResponse(
        request=request, name="pages/users/list.html", context=ctx,
    )


@router.get("/{user_id}", response_class=HTMLResponse, include_in_schema=False)
async def user_detail(
    request: Request,
    admin: CurrentAdmin,
    user_id: int,
) -> HTMLResponse:
    async with AsyncSessionLocal() as db:
        user = await UserRepositoryImpl(db).get_by_id(user_id)

    if user is None:
        flash(request, "User not found", "error")
        return RedirectResponse("/admin/users", status_code=303)

    ctx = base_context(request)
    ctx.update({"current_admin": admin, "user": user})
    return templates.TemplateResponse(
        request=request, name="pages/users/detail.html", context=ctx,
    )


@router.post("/{user_id}/toggle", include_in_schema=False)
async def toggle_user(request: Request, user_id: int, admin: CurrentAdmin):
    is_ar = request.cookies.get("dentspace_locale", "ar") == "ar"
    async with AsyncSessionLocal() as db:
        repo = UserRepositoryImpl(db)
        target = await repo.get_by_id(user_id)
        if target is None:
            flash(request, "User not found", "error")
            return RedirectResponse("/admin/users", status_code=303)
        try:
            await AdminService(db).toggle_user_active(
                admin, user_id, not target.is_active,
            )
            await db.commit()
            flash(
                request,
                ("تم تحديث الحالة" if is_ar else "Status updated"),
                "success",
            )
        except Exception as exc:
            flash(request, str(exc), "error")
    return RedirectResponse("/admin/users", status_code=303)


@router.post("/{user_id}/reset-password", include_in_schema=False)
async def reset_user_password(
    request: Request,
    user_id: int,
    admin: CurrentAdmin,
    new_password: str = Form(...),
):
    is_ar = request.cookies.get("dentspace_locale", "ar") == "ar"
    if len(new_password) < 12:
        flash(
            request,
            "كلمة المرور يجب أن تكون 12 حرفاً على الأقل" if is_ar
            else "Password must be at least 12 characters",
            "error",
        )
        return RedirectResponse("/admin/users", status_code=303)

    async with AsyncSessionLocal() as db:
        repo = UserRepositoryImpl(db)
        target = await repo.get_by_id(user_id)
        if target is None:
            flash(request, "User not found", "error")
            return RedirectResponse("/admin/users", status_code=303)
        try:
            target.hashed_password = hash_password(new_password)
            target.password_changed_at = datetime.now(timezone.utc) + timedelta(seconds=1)
            await repo.update(target)
            await db.commit()
            flash(
                request,
                (f"تم تغيير كلمة مرور {target.full_name}" if is_ar
                 else f"Password reset for {target.full_name}"),
                "success",
            )
        except Exception as exc:
            flash(request, str(exc), "error")
    return RedirectResponse("/admin/users", status_code=303)


@router.post("/{user_id}/delete", include_in_schema=False)
async def delete_user(request: Request, user_id: int, admin: CurrentAdmin):
    is_ar = request.cookies.get("dentspace_locale", "ar") == "ar"
    if user_id == admin.id:
        flash(request, "You cannot delete your own account", "error")
        return RedirectResponse("/admin/users", status_code=303)

    async with AsyncSessionLocal() as db:
        repo = UserRepositoryImpl(db)
        target = await repo.get_by_id(user_id)
        if target is None:
            flash(request, "User not found", "error")
            return RedirectResponse("/admin/users", status_code=303)
        try:
            name = target.full_name
            await repo.delete(user_id)
            await db.commit()
            flash(
                request,
                (f"تم حذف {name}" if is_ar else f"Deleted {name}"),
                "success",
            )
        except Exception as exc:
            flash(request, str(exc), "error")
    return RedirectResponse("/admin/users", status_code=303)