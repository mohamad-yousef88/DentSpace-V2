"""
Order service — full lifecycle for tool purchases.

Race-safe: approve() uses SELECT ... FOR UPDATE on the order row.
"""
import logging
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dtos.order_dto import (
    OrderResponse, OrderToolBrief, OrderUserBrief,
)
from app.application.services.notification_service import NotificationService
from app.core.exceptions import (
    BadRequestException, ConflictException, ForbiddenException, NotFoundException,
)
from app.domain.entities.notification import NotificationType
from app.domain.entities.order import Order, OrderStatus
from app.domain.entities.tool import ToolStatus
from app.domain.entities.user import User, UserRole
from app.infrastructure.repositories.order_repository_impl import OrderRepositoryImpl
from app.infrastructure.repositories.tool_repository_impl import ToolRepositoryImpl
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl

logger = logging.getLogger(__name__)

MAX_ACTIVE_ORDERS_PER_BUYER = 5


class OrderService:

    def __init__(self, session: AsyncSession):
        self._session = session
        self._orders = OrderRepositoryImpl(session)
        self._tools = ToolRepositoryImpl(session)
        self._users = UserRepositoryImpl(session)
        self._notif = NotificationService(session)

    # ─── Create ────────────────────────────────────────────
    async def create_order(
        self, requester: User, tool_id: int, message: str | None,
    ) -> Order:
        if requester.role not in (UserRole.DOCTOR, UserRole.ADMIN):
            raise ForbiddenException("Only doctors can buy tools.")

        tool = await self._tools.get_by_id(tool_id)
        if tool is None:
            raise NotFoundException("Tool not found.")
        if tool.seller_id == requester.id:
            raise ForbiddenException("You cannot buy your own tool.")
        if tool.status != ToolStatus.AVAILABLE:
            raise BadRequestException("This tool is no longer available.")

        existing = await self._orders.find_active_by_buyer_and_tool(
            requester.id, tool_id,
        )
        if existing is not None:
            raise ConflictException("You already have an active order for this tool.")

        active = await self._orders.count_active_for_buyer(requester.id)
        if active >= MAX_ACTIVE_ORDERS_PER_BUYER:
            raise BadRequestException(
                f"You cannot have more than {MAX_ACTIVE_ORDERS_PER_BUYER} "
                f"active orders."
            )

        order = Order(
            tool_id=tool_id,
            buyer_id=requester.id,
            seller_id=tool.seller_id,
            buyer_phone=requester.phone,
            message=(message or "").strip() or None,
            status=OrderStatus.PENDING,
        )
        created = await self._orders.create(order)

        await self._notif.create(
            user_id=tool.seller_id,
            title="طلب شراء جديد",
            body=f"الطبيب {requester.full_name} يريد شراء '{tool.name}'.",
            type=NotificationType.TOOL_ORDER_REQUEST,
            payload={"order_id": created.id, "tool_id": tool_id},
        )
        logger.info("Order created: id=%s buyer=%s tool=%s",
                    created.id, requester.id, tool_id)
        return created

    # ─── Seller actions ────────────────────────────────────
    async def approve(self, requester: User, order_id: int) -> Order:
        # ★ Lock the order row
        order = await self._orders.get_by_id_for_update(order_id)
        if order is None:
            raise NotFoundException("Order not found.")
        if order.seller_id != requester.id and requester.role != UserRole.ADMIN:
            raise ForbiddenException("Only the seller can manage this order.")
        if not order.is_pending:
            raise BadRequestException("Only pending orders can be approved.")

        # ★ Lock the tool row
        tool = await self._tools.get_by_id(order.tool_id)
        if tool is None:
            raise NotFoundException("Tool not found.")
        if tool.status != ToolStatus.AVAILABLE:
            raise BadRequestException("Tool is no longer available.")

        order.status = OrderStatus.APPROVED
        order.responded_at = datetime.now(timezone.utc)
        updated = await self._orders.update(order)

        tool.status = ToolStatus.RESERVED
        await self._tools.update(tool)

        rejected = await self._orders.delete_all_active_for_tool_except(
            tool.id, order.id,
        )
        for r in rejected:
            await self._notif.create(
                user_id=r.buyer_id,
                title="تم رفض طلب الشراء",
                body=f"تمت الموافقة على مشترٍ آخر للأداة '{tool.name}'.",
                type=NotificationType.TOOL_ORDER_REJECTED,
                payload={"order_id": r.id, "tool_id": tool.id},
            )

        await self._notif.create(
            user_id=order.buyer_id,
            title="تمت الموافقة على طلب الشراء",
            body=f"وافق البائع على طلبك لشراء '{tool.name}'.",
            type=NotificationType.TOOL_ORDER_APPROVED,
            payload={"order_id": order.id, "tool_id": tool.id},
        )
        logger.info("Order approved: id=%s", order.id)
        return updated

    async def reject(self, requester: User, order_id: int) -> Order:
        order = await self._get_order_for_seller(requester, order_id)
        if not order.is_pending:
            raise BadRequestException("Only pending orders can be rejected.")

        order.status = OrderStatus.REJECTED
        order.responded_at = datetime.now(timezone.utc)
        updated = await self._orders.update(order)

        await self._notif.create(
            user_id=order.buyer_id,
            title="تم رفض طلب الشراء",
            body="قام البائع برفض طلب الشراء.",
            type=NotificationType.TOOL_ORDER_REJECTED,
            payload={"order_id": order.id, "tool_id": order.tool_id},
        )
        logger.info("Order rejected: id=%s", order.id)
        return updated

    async def complete(self, requester: User, order_id: int) -> Order:
        order = await self._get_order_for_seller(requester, order_id)
        if order.status != OrderStatus.APPROVED:
            raise BadRequestException("Only approved orders can be completed.")

        order.status = OrderStatus.COMPLETED
        order.responded_at = datetime.now(timezone.utc)
        updated = await self._orders.update(order)

        tool = await self._tools.get_by_id(order.tool_id)
        if tool is not None:
            tool.status = ToolStatus.SOLD
            await self._tools.update(tool)

            others = await self._orders.delete_all_active_for_tool_except(
                tool.id, order.id,
            )
            for o in others:
                await self._notif.create(
                    user_id=o.buyer_id,
                    title="تم بيع الأداة",
                    body=f"تم بيع '{tool.name}' لمشترٍ آخر.",
                    type=NotificationType.TOOL_ORDER_REJECTED,
                    payload={"order_id": o.id, "tool_id": tool.id},
                )

        await self._notif.create(
            user_id=order.buyer_id,
            title="تم البيع",
            body=f"أكمل البائع عملية بيع '{tool.name if tool else ''}'. شكراً!",
            type=NotificationType.TOOL_SOLD,
            payload={"order_id": order.id, "tool_id": order.tool_id},
        )
        logger.info("Order completed: id=%s", order.id)
        return updated

    # ─── Either party ──────────────────────────────────────
    async def cancel(self, requester: User, order_id: int) -> None:
        order = await self._orders.get_by_id_for_update(order_id)
        if order is None:
            raise NotFoundException("Order not found.")
        if requester.id not in (order.buyer_id, order.seller_id):
            raise ForbiddenException("You cannot cancel this order.")
        if not order.is_active:
            raise BadRequestException("Only active orders can be cancelled.")

        was_approved = order.status == OrderStatus.APPROVED

        order.status = OrderStatus.CANCELLED
        order.responded_at = datetime.now(timezone.utc)
        await self._orders.update(order)

        if was_approved:
            tool = await self._tools.get_by_id(order.tool_id)
            if tool is not None and tool.status == ToolStatus.RESERVED:
                tool.status = ToolStatus.AVAILABLE
                await self._tools.update(tool)

        other_id = order.seller_id if requester.id == order.buyer_id else order.buyer_id
        canceller = "المشتري" if requester.id == order.buyer_id else "البائع"
        await self._notif.create(
            user_id=other_id,
            title="تم إلغاء طلب الشراء",
            body=f"قام {canceller} بإلغاء الطلب.",
            type=NotificationType.TOOL_ORDER_CANCELLED,
            payload={"order_id": order.id, "tool_id": order.tool_id},
        )
        logger.info("Order cancelled: id=%s by=%s", order.id, canceller)

    # ─── List ──────────────────────────────────────────────
    async def list_orders(
        self, requester: User, *,
        role_filter: str, status: OrderStatus | None,
        offset: int, limit: int,
    ) -> list[Order]:
        if requester.role == UserRole.ADMIN:
            return await self._orders.list_all(
                status=status, offset=offset, limit=limit,
            )
        if role_filter == "buyer":
            return await self._orders.list_for_buyer(
                requester.id, status=status, offset=offset, limit=limit,
            )
        return await self._orders.list_for_seller(
            requester.id, status=status, offset=offset, limit=limit,
        )

    async def get_order(self, requester: User, order_id: int) -> Order:
        order = await self._orders.get_by_id(order_id)
        if order is None:
            raise NotFoundException("Order not found.")
        if requester.role != UserRole.ADMIN and requester.id not in (
            order.buyer_id, order.seller_id,
        ):
            raise ForbiddenException("You cannot view this order.")
        return order

    # ─── Enrichment ────────────────────────────────────────
    async def enrich(self, orders: list[Order]) -> list[OrderResponse]:
        if not orders:
            return []

        # ★ Batch fetch users
        user_ids: set[int] = set()
        tool_ids: set[int] = set()
        for o in orders:
            user_ids.add(o.buyer_id)
            user_ids.add(o.seller_id)
            tool_ids.add(o.tool_id)

        users_map = await self._users.get_many_by_ids(user_ids)
        tools_map: dict[int, object] = {}
        for tid in tool_ids:
            t = await self._tools.get_by_id(tid)
            if t is not None:
                tools_map[tid] = t

        out: list[OrderResponse] = []
        for o in orders:
            tool = tools_map.get(o.tool_id)
            buyer = users_map.get(o.buyer_id)
            seller = users_map.get(o.seller_id)
            out.append(OrderResponse(
                id=o.id,
                status=o.status,
                message=o.message,
                responded_at=o.responded_at,
                created_at=o.created_at,
                tool=OrderToolBrief(
                    id=tool.id, name=tool.name, category=tool.category,
                    condition=tool.condition, price=tool.price,
                    image_urls=list(tool.image_urls), status=tool.status,
                ) if tool else None,
                buyer=OrderUserBrief(
                    id=buyer.id, full_name=buyer.full_name, phone=buyer.phone,
                ) if buyer else None,
                seller=OrderUserBrief(
                    id=seller.id, full_name=seller.full_name, phone=seller.phone,
                ) if seller else None,
            ))
        return out

    # ─── Helpers ───────────────────────────────────────────
    async def _get_order_for_seller(self, requester: User, order_id: int) -> Order:
        order = await self._orders.get_by_id(order_id)
        if order is None:
            raise NotFoundException("Order not found.")
        if order.seller_id != requester.id and requester.role != UserRole.ADMIN:
            raise ForbiddenException("Only the seller can manage this order.")
        return order