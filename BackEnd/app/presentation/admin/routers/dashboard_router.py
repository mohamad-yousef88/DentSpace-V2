"""Admin dashboard — platform statistics (hardened)."""
from __future__ import annotations

import logging
import traceback
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from sqlalchemy import func, select

from app.application.services.admin_service import AdminService
from app.infrastructure.database.session import AsyncSessionLocal
from app.presentation.admin.context import base_context
from app.presentation.admin.dependencies import CurrentAdmin
from app.presentation.admin.templates import templates

logger = logging.getLogger(__name__)
router = APIRouter()


def _to_int_dict(d) -> dict[str, int]:
    """Force any stat mapping to be {str: int} — never crash the template."""
    if not isinstance(d, dict):
        return {}
    out: dict[str, int] = {}
    for k, v in d.items():
        try:
            out[str(k)] = int(v or 0)
        except (TypeError, ValueError):
            out[str(k)] = 0
    return out


def _safe_stats(raw: dict | None) -> dict:
    raw = raw or {}
    return {
        "users": _to_int_dict(raw.get("users")),
        "cases": _to_int_dict(raw.get("cases")),
        "appointments": _to_int_dict(raw.get("appointments")),
        "orders": _to_int_dict(raw.get("orders")),
        "tools": _to_int_dict(raw.get("tools")),
        "pending_verifications": int(raw.get("pending_verifications") or 0),
    }


async def _safe_case_counts(db, days: list[datetime]) -> list[int]:
    """Best-effort daily counts — returns [0,0,...] on any failure."""
    try:
        from app.infrastructure.database.models.patient_case_model import (
            PatientCaseModel,
        )
    except Exception:
        logger.warning("PatientCaseModel import failed — charts will show 0")
        return [0] * len(days)

    counts: list[int] = []
    for d in days:
        try:
            next_d = d + timedelta(days=1)
            r = await db.execute(
                select(func.count(PatientCaseModel.id)).where(
                    PatientCaseModel.created_at >= d,
                    PatientCaseModel.created_at < next_d,
                )
            )
            counts.append(int(r.scalar() or 0))
        except Exception as exc:
            logger.warning("case_count for %s failed: %s", d.date(), exc)
            counts.append(0)
    return counts


@router.get("/dashboard", response_class=HTMLResponse, include_in_schema=False)
async def dashboard(request: Request, admin: CurrentAdmin) -> HTMLResponse:
    raw_stats: dict | None = None
    case_counts: list[int] = []
    today = datetime.now(timezone.utc).replace(
        hour=0, minute=0, second=0, microsecond=0,
    )
    days = [today - timedelta(days=i) for i in range(6, -1, -1)]

    try:
        async with AsyncSessionLocal() as db:
            svc = AdminService(db)
            raw_stats = await svc.get_stats()
            case_counts = await _safe_case_counts(db, days)
    except Exception:
        logger.exception("Dashboard stats fetch failed")
        traceback.print_exc()
        raw_stats = {}
        case_counts = [0] * len(days)

    stats = _safe_stats(raw_stats)

    users_map = stats["users"]
    cases_map = stats["cases"]

    ctx = base_context(request)
    ctx.update({
        "current_admin": admin,
        "stats": stats,
        "chart_days": [d.strftime("%m-%d") for d in days],
        "chart_cases": case_counts,
        "chart_users": [
            users_map.get("patient", 0),
            users_map.get("doctor", 0),
            users_map.get("admin", 0),
        ],
        "chart_cases_status": [
            cases_map.get("pending", 0),
            cases_map.get("booked", 0),
            cases_map.get("completed", 0),
            cases_map.get("verified", 0),
        ],
    })

    return templates.TemplateResponse(
        request=request,
        name="pages/dashboard/index.html",
        context=ctx,
    )