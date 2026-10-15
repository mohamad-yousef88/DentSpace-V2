"""Shared template context — locale, theme, flash, helpers."""
from __future__ import annotations

from datetime import datetime
from typing import Any

from fastapi import Request


SUPPORTED_LOCALES = ("ar", "en")
DEFAULT_LOCALE = "ar"

SUPPORTED_THEMES = ("light", "dark")
DEFAULT_THEME = "light"


def get_locale(request: Request) -> str:
    locale = request.cookies.get("dentspace_locale", DEFAULT_LOCALE)
    return locale if locale in SUPPORTED_LOCALES else DEFAULT_LOCALE


def get_theme(request: Request) -> str:
    theme = request.cookies.get("dentspace_theme", DEFAULT_THEME)
    return theme if theme in SUPPORTED_THEMES else DEFAULT_THEME


def get_flash(request: Request) -> list[dict[str, str]]:
    """Pop flash messages from the session."""
    return request.session.pop("_flash", [])


def flash(request: Request, message: str, kind: str = "info") -> None:
    """Queue a flash message for the next request."""
    msgs = request.session.setdefault("_flash", [])
    msgs.append({"message": message, "kind": kind})


def base_context(request: Request) -> dict[str, Any]:
    """Context injected into every template render."""
    locale = get_locale(request)
    return {
        "request": request,
        "locale": locale,
        "theme": get_theme(request),
        "is_arabic": locale == "ar",
        "flash": get_flash(request),
        "now_year": datetime.now().year,
    }