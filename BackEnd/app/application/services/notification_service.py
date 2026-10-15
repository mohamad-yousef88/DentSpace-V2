"""
Notification service — create, list, mark-read, delete.
Push delivery (FCM) is handled separately in a future batch.
"""
import logging

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ForbiddenException, NotFoundException
from app.domain.entities.notification import Notification, NotificationType
from app.domain.entities.user import User, UserRole
from app.infrastructure.repositories.notification_repository_impl import (
    NotificationRepositoryImpl,
)
from app.infrastructure.external.push_service import push_service
from app.infrastructure.repositories.user_repository_impl import (
    UserRepositoryImpl,
)
logger = logging.getLogger(__name__)


class NotificationService:

    def __init__(self, session: AsyncSession):
        self._session = session
        self._repo = NotificationRepositoryImpl(session)

    # ─── Create (used internally by other services) ────────
    async def create(
            self,
            *,
            user_id: int,
            title: str,
            type: NotificationType,
            body: str | None = None,
            payload: dict | None = None,
    ) -> Notification:
        # 1) Persist to DB — always
        n = Notification(
            user_id=user_id,
            title=title,
            type=type,
            body=body,
            payload=payload,
        )
        created = await self._repo.create(n)

        # 2) Best-effort push — never crashes the request
        try:
            users = UserRepositoryImpl(self._session)
            user = await users.get_by_id(user_id)
            if user and user.fcm_token:
                result = push_service.send_to_token(
                    user.fcm_token,
                    title=title,
                    body=body,
                    data={
                        "type": type.value,
                        "notification_id": str(created.id),
                        **(payload or {}),
                    },
                )
                # 3) If the token is dead, clear it
                if not result.success and result.reason == "unregistered":
                    user.fcm_token = None
                    await users.update(user)
        except Exception as exc:
            logger.warning("Push delivery skipped: %s", exc)

        logger.info(
            "Notification created: id=%s user=%s type=%s",
            created.id, user_id, type.value,
        )
        return created

    # ─── User-facing ───────────────────────────────────────
    async def list_for_requester(
        self, requester: User, *, offset: int = 0, limit: int = 50,
    ) -> tuple[list[Notification], int]:
        items = await self._repo.list_for_user(
            requester.id, offset=offset, limit=limit,
        )
        unread = sum(1 for n in items if not n.is_read)
        return items, unread

    async def mark_read(self, requester: User, notification_id: int) -> None:
        n = await self._repo.get_by_id(notification_id)
        if n is None:
            raise NotFoundException("Notification not found.")
        if n.user_id != requester.id:
            raise ForbiddenException("You can only modify your own notifications.")
        await self._repo.mark_as_read(notification_id)

    async def mark_all_read(self, requester: User) -> int:
        return await self._repo.mark_all_as_read(requester.id)

    async def delete(self, requester: User, notification_id: int) -> None:
        n = await self._repo.get_by_id(notification_id)
        if n is None:
            raise NotFoundException("Notification not found.")
        if n.user_id != requester.id:
            raise ForbiddenException("You can only delete your own notifications.")
        await self._repo.delete(notification_id)

    async def delete_read(self, requester: User) -> int:
        return await self._repo.delete_all_read(requester.id)