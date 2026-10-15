"""Tool repository interface."""
from abc import ABC, abstractmethod

from app.domain.entities.tool import Tool, ToolStatus


class ToolRepository(ABC):

    @abstractmethod
    async def get_by_id(self, tool_id: int) -> Tool | None: ...

    @abstractmethod
    async def create(self, tool: Tool) -> Tool: ...

    @abstractmethod
    async def update(self, tool: Tool) -> Tool: ...

    @abstractmethod
    async def delete(self, tool_id: int) -> None: ...

    @abstractmethod
    async def count_by_seller_and_status(
        self, seller_id: int, status: ToolStatus,
    ) -> int: ...

    @abstractmethod
    async def list_for_seller(
        self, seller_id: int, *,
        status: ToolStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[Tool]: ...

    @abstractmethod
    async def list_available(
        self, *,
        search: str | None = None,
        category: str | None = None,
        exclude_seller_id: int | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[Tool]: ...