"""
Cloudinary client — upload, delete, and URL-parsing helpers.

Design notes:
- All Cloudinary HTTP/SDK calls are wrapped here — the rest of the app
  never touches the SDK directly.
- `extract_public_id` is the single source of truth for parsing a
  Cloudinary URL back to its public_id (needed for deletion).
- Failures raise `CloudinaryError` so services can decide what to do.
"""
import logging
import re
import time
from dataclasses import dataclass
from typing import BinaryIO

import cloudinary
import cloudinary.uploader
from cloudinary.exceptions import Error as CloudinarySDKError

from app.core.config import settings

logger = logging.getLogger(__name__)


# ═══════════════════════════════════════════════════════════════
# Config
# ═══════════════════════════════════════════════════════════════
# Global timeout for Cloudinary HTTP requests (seconds)
cloudinary.config(
    cloud_name=settings.cloudinary_cloud_name,
    api_key=settings.cloudinary_api_key,
    api_secret=settings.cloudinary_api_secret,
    secure=True,
)


# ═══════════════════════════════════════════════════════════════
# Types & Errors
# ═══════════════════════════════════════════════════════════════
class CloudinaryError(Exception):
    """Raised when a Cloudinary operation fails."""


@dataclass(frozen=True)
class UploadResult:
    url: str
    public_id: str


# ═══════════════════════════════════════════════════════════════
# URL parsing
# ═══════════════════════════════════════════════════════════════
_PUBLIC_ID_RE = re.compile(
    r"/image/upload/"          # path marker
    r"(?:v\d+/)?",             # optional version segment (v1234567890/)
)


def extract_public_id(url: str | None) -> str | None:
    """
    Extract the Cloudinary `public_id` from a secure URL.

    Example:
        https://res.cloudinary.com/dz7phzja0/image/upload/v1234567890/
        dentspace/avatars/user_1.jpg
        → "dentspace/avatars/user_1"

    Returns None if the URL doesn't look like a Cloudinary image URL.
    """
    if not url or not isinstance(url, str):
        return None
    if "res.cloudinary.com" not in url:
        return None

    match = _PUBLIC_ID_RE.search(url)
    if not match:
        return None

    tail = url[match.end():]
    # Strip query string / fragment
    tail = tail.split("?", 1)[0].split("#", 1)[0]
    # Strip extension
    if "." in tail.rsplit("/", 1)[-1]:
        tail = tail.rsplit(".", 1)[0]
    return tail or None


# ═══════════════════════════════════════════════════════════════
# Client
# ═══════════════════════════════════════════════════════════════
class CloudinaryClient:
    """Thin async-friendly wrapper around the Cloudinary SDK."""

    DEFAULT_FOLDER = "dentspace"

    def upload_image(
            self,
            file: BinaryIO,
            folder: str,
            public_id: str | None = None,
            max_retries: int = 2,
            timeout: int = 30,
    ) -> UploadResult:
        """
        Upload an image file with retries on transient network errors.

        `file` can be a file-like object (FastAPI UploadFile.file).
        `folder` scopes uploads (e.g. "dentspace/avatars").
        `public_id` (optional) forces a specific ID.
        `max_retries` attempts after the first (default: 2 → 3 total).
        `timeout` per-request timeout in seconds.
        """
        last_exc: Exception | None = None

        for attempt in range(1, max_retries + 2):
            try:
                response = cloudinary.uploader.upload(
                    file,
                    folder=folder,
                    public_id=public_id,
                    resource_type="image",
                    overwrite=True,
                    invalidate=True,
                    unique_filename=public_id is None,
                    timeout=timeout,
                )
                logger.info(
                    "Cloudinary upload OK (attempt %d): %s",
                    attempt, response.get("public_id"),
                )
                return UploadResult(
                    url=response["secure_url"],
                    public_id=response["public_id"],
                )
            except (CloudinarySDKError, OSError, TimeoutError) as exc:
                last_exc = exc
                logger.warning(
                    "Cloudinary upload attempt %d/%d failed: %s",
                    attempt, max_retries + 1, exc,
                )
                if attempt <= max_retries:
                    time.sleep(2 ** attempt)  # exponential backoff: 2s, 4s
                    try:
                        file.seek(0)  # reset stream for retry
                    except Exception:
                        pass
            except Exception as exc:
                last_exc = exc
                logger.error("Unexpected Cloudinary upload error: %s", exc)
                break

        raise CloudinaryError(f"Upload failed after {max_retries + 1} attempts: {last_exc}")

    def delete_image(self, public_id: str) -> bool:
        """
        Delete an image by its public_id.

        Returns True if deleted (or already absent), False on failure.
        Never raises — a failed delete must not crash the request.
        """
        if not public_id:
            return False
        try:
            result = cloudinary.uploader.destroy(
                public_id,
                resource_type="image",
                invalidate=True,
            )
            outcome = result.get("result")
            if outcome in ("ok", "not found"):
                return True
            logger.warning("Cloudinary delete non-ok: %s", result)
            return False
        except CloudinarySDKError as exc:
            logger.error("Cloudinary delete failed for %s: %s", public_id, exc)
            return False
        except Exception as exc:
            logger.error("Unexpected Cloudinary delete error: %s", exc)
            return False


# ─── Singleton ─────────────────────────────────────────────────
cloudinary_client = CloudinaryClient()