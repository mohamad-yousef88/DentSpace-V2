"""
Avatar service — upload / replace / delete user profile images.

Security:
  • Magic-byte validation before upload — Content-Type header is
    informational only and cannot be trusted.
"""
import logging
from typing import BinaryIO

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import BadRequestException, NotFoundException
from app.domain.entities.user import User
from app.infrastructure.external.cloudinary_client import (
    CloudinaryError,
    cloudinary_client,
    extract_public_id,
)
from app.infrastructure.external.image_validator import validate_image_bytes
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl

logger = logging.getLogger(__name__)


# ─── Constants ─────────────────────────────────────────────────
AVATAR_FOLDER = "dentspace/avatars"
MAX_AVATAR_BYTES = 5 * 1024 * 1024          # 5 MB
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
}


class AvatarService:

    def __init__(self, session: AsyncSession):
        self._session = session
        self._users = UserRepositoryImpl(session)

    # ═══════════════════════════════════════════════════════
    # Upload / Replace
    # ═══════════════════════════════════════════════════════
    async def upload_avatar(
        self,
        user_id: int,
        file: BinaryIO,
        content_type: str | None,
        file_size: int | None,
    ) -> User:
        # 1. Size + Content-Type gate
        if content_type not in ALLOWED_CONTENT_TYPES:
            raise BadRequestException(
                f"Unsupported image type '{content_type}'. "
                f"Allowed: JPEG, PNG, WEBP."
            )
        if file_size is not None and file_size > MAX_AVATAR_BYTES:
            raise BadRequestException(
                f"Image too large. Max size is "
                f"{MAX_AVATAR_BYTES // (1024 * 1024)} MB."
            )

        # 2. ★ Magic-byte check — reads the first 16 bytes
        try:
            file.seek(0)
            header = file.read(16)
            file.seek(0)
        except Exception:
            header = b""
        validate_image_bytes(header, declared_type=content_type)

        # 3. Fetch user
        user = await self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundException("User not found.")

        # 4. Remember old public_id
        old_public_id = extract_public_id(user.profile_image_url)

        # 5. Upload to Cloudinary
        new_public_id = f"user_{user.id}"
        try:
            result = cloudinary_client.upload_image(
                file=file,
                folder=AVATAR_FOLDER,
                public_id=new_public_id,
            )
        except CloudinaryError as exc:
            raise BadRequestException(str(exc))

        # 6. Save URL in DB — compensating action on failure
        user.profile_image_url = result.url
        try:
            updated = await self._users.update(user)
        except Exception:
            cloudinary_client.delete_image(result.public_id)
            raise

        # 7. Best-effort delete of the old file
        if old_public_id and old_public_id != result.public_id:
            cloudinary_client.delete_image(old_public_id)

        return updated

    # ═══════════════════════════════════════════════════════
    # Delete
    # ═══════════════════════════════════════════════════════
    async def delete_avatar(self, user_id: int) -> User:
        user = await self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundException("User not found.")

        public_id = extract_public_id(user.profile_image_url)
        if not public_id and not user.profile_image_url:
            raise BadRequestException("User has no avatar to delete.")

        if public_id:
            cloudinary_client.delete_image(public_id)

        user.profile_image_url = None
        return await self._users.update(user)