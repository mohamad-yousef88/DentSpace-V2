"""Order repository implementation."""
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.order import Order, OrderStatus
from app.domain.repositories.order_repository import OrderRepository
from app.infrastructure.database.models.order_model import OrderModel, OrderStatusEnum


def _to_entity(m: OrderModel) -> Order:
    return Order(
        id=m.id,
        tool_id=m.tool_id,
        buyer_id=m.buyer_id,
        seller_id=m.seller_id,
        buyer_phone=m.buyer_phone,
        message=m.message,
        status=OrderStatus(m.status.value),
        responded_at=m.responded_at,
        created_at=m.created_at,
        updated_at=m.updated_at,
    )


def _to_enum(s: OrderStatus) -> OrderStatusEnum:
    return OrderStatusEnum(s.value)


class OrderRepositoryImpl(OrderRepository):

    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, order_id: int) -> Order | None:
        r = await self._session.execute(
            select(OrderModel).where(OrderModel.id == order_id)
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def create(self, order: Order) -> Order:
        m = OrderModel(
            tool_id=order.tool_id,
            buyer_id=order.buyer_id,
            seller_id=order.seller_id,
            buyer_phone=order.buyer_phone,
            message=order.message,
            status=_to_enum(order.status),
        )
        self._session.add(m)
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def update(self, order: Order) -> Order:
        if order.id is None:
            raise ValueError("Cannot update order without id")
        r = await self._session.execute(
            select(OrderModel).where(OrderModel.id == order.id)
        )
        m = r.scalar_one()
        m.status = _to_enum(order.status)
        m.responded_at = order.responded_at
        m.buyer_phone = order.buyer_phone
        m.message = order.message
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def delete(self, order_id: int) -> None:
        r = await self._session.execute(
            select(OrderModel).where(OrderModel.id == order_id)
        )
        m = r.scalar_one_or_none()
        if m:
            await self._session.delete(m)

    async def find_active_by_buyer_and_tool(self, buyer_id: int, tool_id: int):
        r = await self._session.execute(
            select(OrderModel).where(
                OrderModel.buyer_id == buyer_id,
                OrderModel.tool_id == tool_id,
                OrderModel.status.in_([
                    OrderStatusEnum.PENDING,
                    OrderStatusEnum.APPROVED,
                ]),
            ).limit(1)
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def list_active_for_tool(self, tool_id: int) -> list[Order]:
        r = await self._session.execute(
            select(OrderModel).where(
                OrderModel.tool_id == tool_id,
                OrderModel.status.in_([
                    OrderStatusEnum.PENDING,
                    OrderStatusEnum.APPROVED,
                ]),
            )
        )
        return [_to_entity(m) for m in r.scalars().all()]

    async def count_active_for_buyer(self, buyer_id: int) -> int:
        r = await self._session.execute(
            select(func.count(OrderModel.id)).where(
                OrderModel.buyer_id == buyer_id,
                OrderModel.status.in_([
                    OrderStatusEnum.PENDING,
                    OrderStatusEnum.APPROVED,
                ]),
            )
        )
        return int(r.scalar() or 0)

    async def list_for_buyer(self, buyer_id, *, status=None, offset=0, limit=20):
        s = select(OrderModel).where(OrderModel.buyer_id == buyer_id)
        if status:
            s = s.where(OrderModel.status == _to_enum(status))
        s = s.order_by(OrderModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def list_for_seller(self, seller_id, *, status=None, offset=0, limit=20):
        s = select(OrderModel).where(OrderModel.seller_id == seller_id)
        if status:
            s = s.where(OrderModel.status == _to_enum(status))
        s = s.order_by(OrderModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def list_all(self, *, status=None, offset=0, limit=20):
        s = select(OrderModel)
        if status:
            s = s.where(OrderModel.status == _to_enum(status))
        s = s.order_by(OrderModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def delete_all_active_for_tool_except(
            self, tool_id: int, keep_order_id: int,
    ) -> list[Order]:
        r = await self._session.execute(
            select(OrderModel).where(
                OrderModel.tool_id == tool_id,
                OrderModel.id != keep_order_id,
                OrderModel.status.in_([
                    OrderStatusEnum.PENDING,
                    OrderStatusEnum.APPROVED,
                ]),
            )
        )
        models = list(r.scalars().all())
        orders = [_to_entity(m) for m in models]
        for m in models:
            await self._session.delete(m)
        return orders
    async def get_by_id_for_update(self, order_id: int) -> Order | None:
        r = await self._session.execute(
            select(OrderModel).where(OrderModel.id == order_id).with_for_update()
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None