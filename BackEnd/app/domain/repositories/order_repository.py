"""Order repository interface."""
from abc import ABC, abstractmethod

from app.domain.entities.order import Order, OrderStatus


class OrderRepository(ABC):

    @abstractmethod
    async def get_by_id(self, order_id: int) -> Order | None: ...

    @abstractmethod
    async def create(self, order: Order) -> Order: ...

    @abstractmethod
    async def update(self, order: Order) -> Order: ...
    @abstractmethod
    async def get_by_id_for_update(self, order_id: int) -> Order | None: ...

    @abstractmethod
    async def delete(self, order_id: int) -> None: ...

    @abstractmethod
    async def find_active_by_buyer_and_tool(
        self, buyer_id: int, tool_id: int,
    ) -> Order | None: ...

    @abstractmethod
    async def list_active_for_tool(self, tool_id: int) -> list[Order]: ...

    @abstractmethod
    async def count_active_for_buyer(self, buyer_id: int) -> int: ...

    @abstractmethod
    async def list_for_buyer(
        self, buyer_id: int, *,
        status: OrderStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[Order]: ...

    @abstractmethod
    async def list_for_seller(
        self, seller_id: int, *,
        status: OrderStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[Order]: ...

    @abstractmethod
    async def list_all(
        self, *, status: OrderStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[Order]: ...

    @abstractmethod
    async def delete_all_active_for_tool_except(
        self, tool_id: int, keep_order_id: int,
    ) -> list[Order]: ...
    """Delete (or mark rejected) all active orders on a tool except one.
    Returns the affected orders for notification."""