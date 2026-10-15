"""
User repository interface (port).

Defines the contract for user persistence.
Implementation lives in the infrastructure layer.
"""
from abc import ABC, abstractmethod

from app.domain.entities.user import User, UserRole


class UserRepository(ABC):
    """Abstract user repository."""

    @abstractmethod
    async def get_by_id(self, user_id: int) -> User | None: ...

    @abstractmethod
    async def get_by_email(self, email: str) -> User | None: ...

    @abstractmethod
    async def get_by_phone(self, phone: str) -> User | None: ...

    @abstractmethod
    async def get_by_university_id(self, university_id: str) -> User | None: ...

    @abstractmethod
    async def create(self, user: User) -> User: ...

    @abstractmethod
    async def update(self, user: User) -> User: ...
    @abstractmethod
    async def get_many_by_ids(self, user_ids: set[int]) -> dict[int, User]: ...
    @abstractmethod
    async def list_users(
        self, *,
        role: UserRole | None = None,
        is_active: bool | None = None,
        search: str | None = None,
        offset: int = 0,
        limit: int = 20,
    ) -> list[User]: ...

    @abstractmethod
    async def count_by_role(self) -> dict[str, int]: ...

    @abstractmethod
    async def delete(self, user_id: int) -> None: ...

    @abstractmethod
    async def exists_by_email(self, email: str) -> bool: ...

    @abstractmethod
    async def exists_by_phone(self, phone: str) -> bool: ...