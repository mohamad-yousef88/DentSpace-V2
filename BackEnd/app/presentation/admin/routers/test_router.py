"""Test routes — verifies the design system works end-to-end."""
from __future__ import annotations

from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse

from app.presentation.admin.context import base_context
from app.presentation.admin.templates import templates

router = APIRouter()


@router.get("/test", response_class=HTMLResponse, include_in_schema=False)
async def test_page(request: Request) -> HTMLResponse:
    """Render the design-system test page."""
    return templates.TemplateResponse(
        request=request,
        name="pages/test.html",
        context=base_context(request),
    )