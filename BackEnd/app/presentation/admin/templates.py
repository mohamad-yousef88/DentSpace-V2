from __future__ import annotations

from pathlib import Path

from fastapi.templating import Jinja2Templates


def _find_project_root(start: Path) -> Path:
    """Walk up until we find `package.json` (BackEnd marker)."""
    for candidate in (start, *start.parents):
        if (candidate / "package.json").exists():
            return candidate
    return start.parents[3]


PROJECT_ROOT = _find_project_root(Path(__file__).resolve())
TEMPLATES_DIR = PROJECT_ROOT / "templates"

templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


# ─── Global helpers available to every template ──────────
def _min_filter(a, b):
    return min(a, b)


templates.env.filters["min"] = _min_filter