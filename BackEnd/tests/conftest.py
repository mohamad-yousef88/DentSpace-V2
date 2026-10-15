"""
Common fixtures for ALL tests.

The env-file override MUST happen before any `app.*` import, hence
the import of `app` modules is deliberately deferred.
"""
import os
from pathlib import Path

# ─── Force .env.test BEFORE any `app.*` import ─────────────────
_PROJECT_ROOT = Path(__file__).resolve().parents[1]
_TEST_ENV = _PROJECT_ROOT / ".env.test"
os.environ["ENV_FILE"] = str(_TEST_ENV)   # force, not setdefault
os.environ["APP_ENV"] = "testing"

import pytest  # noqa: E402


# ═══════════════════════════════════════════════════════════════
# Sanity check — fail fast if the test DB is being misused
# ═══════════════════════════════════════════════════════════════
@pytest.fixture(scope="session", autouse=True)
def _verify_test_env():
    from app.core.config import settings

    assert settings.app_env == "testing", (
        f"Tests are running against APP_ENV={settings.app_env!r}. "
        f"Expected 'testing'. Check ENV_FILE={os.environ.get('ENV_FILE')}."
    )
    assert settings.database_url.endswith("dent_space_test"), (
        f"Tests are running against {settings.database_url!r}. "
        f"Expected DB name 'dent_space_test'."
    )


# ═══════════════════════════════════════════════════════════════
# External service mocks — autouse, apply to every test
# ═══════════════════════════════════════════════════════════════
@pytest.fixture(autouse=True)
def mock_cloudinary(monkeypatch):
    import cloudinary.uploader
    from tests.helpers.mocks import fake_destroy, fake_upload

    monkeypatch.setattr(cloudinary.uploader, "upload", fake_upload)
    monkeypatch.setattr(cloudinary.uploader, "destroy", fake_destroy)


@pytest.fixture(autouse=True)
def mock_fcm(monkeypatch):
    from app.infrastructure.external import push_service as ps_module
    from tests.helpers.mocks import fake_fcm_send

    monkeypatch.setattr(ps_module.messaging, "send", fake_fcm_send)
    monkeypatch.setattr(ps_module, "is_enabled", lambda: True)


@pytest.fixture(autouse=True)
def disable_smtp(monkeypatch):
    from app.application.services.email_service import EmailService

    async def _noop_send(self, to, subject, html_body):
        return None

    async def _noop_otp(self, to, otp, purpose):
        return None

    monkeypatch.setattr(EmailService, "_send", _noop_send)
    monkeypatch.setattr(EmailService, "send_otp_email", _noop_otp)