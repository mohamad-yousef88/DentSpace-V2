"""
Firebase Admin SDK bootstrap.

Loads `firebase-credentials.json` once and exposes helpers.

Design:
- Idempotent init: safe to call from multiple entry points.
- Fails soft: if the credentials file is missing, FCM is disabled but
  the rest of the app keeps working (notifications still land in DB).
"""
import logging
from pathlib import Path

import firebase_admin
from firebase_admin import credentials

from app.core.config import settings

logger = logging.getLogger(__name__)

_initialized = False


def init_firebase() -> bool:
    """Initialise the default Firebase app. Returns True on success."""
    global _initialized
    if _initialized:
        return True

    cred_path = Path(settings.firebase_credentials_path)
    if not cred_path.is_absolute():
        # Resolve relative to the project root (BackEnd/)
        cred_path = Path(__file__).resolve().parents[3] / cred_path

    if not cred_path.exists():
        logger.warning(
            "Firebase credentials not found at %s — push disabled.",
            cred_path,
        )
        return False

    try:
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)
        _initialized = True
        logger.info("Firebase Admin initialised (%s)", cred_path.name)
        return True
    except Exception as exc:
        logger.error("Failed to initialise Firebase: %s", exc)
        return False


def is_enabled() -> bool:
    return _initialized