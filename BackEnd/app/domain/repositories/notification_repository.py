"""Notification repository interface."""
from abc import ABC, abstractmethod

from app.domain.entities.notification import Notification


class NotificationRepository(ABC):

    @abstractmethod
    async def create(self, notification: Notification) -> Notification: ...

    @abstractmethod
    async def get_by_id(self, notification_id: int) -> Notification | None: ...

    @abstractmethod
    async def list_for_user(
        self, user_id: int, *, offset: int = 0, limit: int = 50,
    ) -> list[Notification]: ...

    @abstractmethod
    async def mark_as_read(self, notification_id: int) -> None: ...

    @abstractmethod
    async def mark_all_as_read(self, user_id: int) -> int: ...

    @abstractmethod
    async def delete(self, notification_id: int) -> None: ...

    @abstractmethod
    async def delete_all_read(self, user_id: int) -> int: ...