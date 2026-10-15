"""Admin profile — view, edit, avatar upload."""
from __future__ import annotations

import shutil
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, File, Form, Request, UploadFile
from fastapi.responses import HTMLResponse, RedirectResponse

from app.core.exceptions import ConflictException
from app.domain.entities.user import Gender
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl
from app.presentation.admin.context import base_context, flash
from app.presentation.admin.dependencies import CurrentAdmin
from app.presentation.admin.templates import templates


router = APIRouter()

# Avatar storage
PROJECT_ROOT = Path(__file__).resolve().parents[4]
AVATAR_DIR = PROJECT_ROOT / "static" / "uploads" / "avatars"
AVATAR_DIR.mkdir(parents=True, exist_ok=True)

ALLOWED_MIME = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
MAX_AVATAR_SIZE = 5 * 1024 * 1024  # 5 MB


@router.get("", response_class=HTMLResponse, include_in_schema=False)
async def profile(request: Request, admin: CurrentAdmin) -> HTMLResponse:
    ctx = base_context(request)
    ctx["current_admin"] = admin
    return templates.TemplateResponse(
        request=request, name="pages/profile/index.html", context=ctx,
    )


@router.post("", include_in_schema=False)
async def update_profile(
    request: Request,
    admin: CurrentAdmin,
    full_name: str = Form(...),
    phone: str = Form(...),
    gender: str = Form(""),
    age: str = Form(""),
):
    is_ar = request.cookies.get("dentspace_locale", "ar") == "ar"
    async with AsyncSessionLocal() as db:
        repo = UserRepositoryImpl(db)
        user = await repo.get_by_id(admin.id)
        if user is None:
            flash(request, "User not found", "error")
            return RedirectResponse("/admin/profile", status_code=303)
        try:
            if phone.strip() != user.phone:
                existing = await repo.get_by_phone(phone.strip())
                if existing is not None and existing.id != user.id:
                    raise ConflictException("Phone already in use")

            user.full_name = full_name.strip()
            user.phone = phone.strip()
            if gender in ("male", "female"):
                user.gender = Gender(gender)
            if age.isdigit() and 18 <= int(age) <= 80:
                user.age = int(age)

            await repo.update(user)
            await db.commit()
            flash(
                request,
                ("تم تحديث الملف" if is_ar else "Profile updated"),
                "success",
            )
        except Exception as exc:
            flash(request, str(exc), "error")
    return RedirectResponse("/admin/profile", status_code=303)


@router.post("/avatar", include_in_schema=False)
async def upload_avatar(
    request: Request,
    admin: CurrentAdmin,
    avatar: UploadFile = File(...),
):
    is_ar = request.cookies.get("dentspace_locale", "ar") == "ar"

    if avatar.content_type not in ALLOWED_MIME:
        flash(
            request,
            ("صيغة الصورة غير مدعومة" if is_ar else "Unsupported image format"),
            "error",
        )
        return RedirectResponse("/admin/profile", status_code=303)

    contents = await avatar.read()
    if len(contents) > MAX_AVATAR_SIZE:
        flash(
            request,
            ("حجم الصورة يتجاوز 5 ميغابايت" if is_ar else "Image exceeds 5 MB"),
            "error",
        )
        return RedirectResponse("/admin/profile", status_code=303)

    ext_map = {"image/jpeg": ".jpg", "image/jpg": ".jpg", "image/png": ".png", "image/webp": ".webp"}
    ext = ext_map.get(avatar.content_type, ".jpg")
    filename = f"admin_{admin.id}_{uuid4().hex[:8]}{ext}"
    file_path = AVATAR_DIR / filename

    with file_path.open("wb") as f:
        f.write(contents)

    public_url = f"/static/uploads/avatars/{filename}"

    async with AsyncSessionLocal() as db:
        repo = UserRepositoryImpl(db)
        user = await repo.get_by_id(admin.id)
        if user is None:
            flash(request, "User not found", "error")
            return RedirectResponse("/admin/profile", status_code=303)
        try:
            # Delete old file
            if user.profile_image_url and user.profile_image_url.startswith("/static/uploads/avatars/"):
                old = PROJECT_ROOT / user.profile_image_url.lstrip("/")
                if old.exists() and old.is_file():
                    try:
                        old.unlink()
                    except OSError:
                        pass

            user.profile_image_url = public_url
            await repo.update(user)
            await db.commit()
            flash(
                request,
                ("تم تحديث الصورة" if is_ar else "Avatar updated"),
                "success",
            )
        except Exception as exc:
            flash(request, str(exc), "error")
    return RedirectResponse("/admin/profile", status_code=303)