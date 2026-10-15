"""Notification repository implementation."""
from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.notification import Notification, NotificationType
from app.domain.repositories.notification_repository import NotificationRepository
from app.infrastructure.database.models.notification_model import (
    NotificationModel, NotificationTypeEnum,
)


def _to_entity(m: NotificationModel) -> Notification:
    return Notification(
        id=m.id,
        user_id=m.user_id,
        title=m.title,
        body=m.body,
        type=NotificationType(m.type.value),
        payload=m.payload,
        is_read=m.is_read,
        created_at=m.created_at,
        updated_at=m.updated_at,
    )


class NotificationRepositoryImpl(NotificationRepository):

    def __init__(self, session: AsyncSession):
        self._session = session

    async def create(self, n: Notification) -> Notification:
        m = NotificationModel(
            user_id=n.user_id,
            title=n.title,
            body=n.body,
            type=NotificationTypeEnum(n.type.value),
            payload=n.payload,
            is_read=False,
        )
        self._session.add(m)
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def get_by_id(self, notification_id: int) -> Notification | None:
        r = await self._session.execute(
            select(NotificationModel).where(NotificationModel.id == notification_id)
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def list_for_user(self, user_id, *, offset=0, limit=50):
        r = await self._session.execute(
            select(NotificationModel)
            .where(NotificationModel.user_id == user_id)
            .order_by(NotificationModel.created_at.desc())
            .offset(offset).limit(limit)
        )
        return [_to_entity(m) for m in r.scalars().all()]

    async def mark_as_read(self, notification_id: int) -> None:
        await self._session.execute(
            update(NotificationModel)
            .where(NotificationModel.id == notification_id)
            .values(is_read=True)
        )

    async def mark_all_as_read(self, user_id: int) -> int:
        r = await self._session.execute(
            update(NotificationModel)
            .where(
                NotificationModel.user_id == user_id,
                NotificationModel.is_read.is_(False),
            )
            .values(is_read=True)
        )
        return r.rowcount or 0

    async def delete(self, notification_id: int) -> None:
        await self._session.execute(
            delete(NotificationModel).where(NotificationModel.id == notification_id)
        )

    async def delete_all_read(self, user_id: int) -> int:
        r = await self._session.execute(
            delete(NotificationModel).where(
                NotificationModel.user_id == user_id,
                NotificationModel.is_read.is_(True),
            )
        )
        return r.rowcount or 0