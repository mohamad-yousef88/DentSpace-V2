"""Orders router."""
from fastapi import APIRouter, Query, status

from app.application.dtos.order_dto import (
    CreateOrderRequest, OrderListResponse, OrderResponse,
)
from app.core.dependencies import CurrentUser, OrderSvc
from app.domain.entities.order import OrderStatus

router = APIRouter()


@router.post(
    "", response_model=OrderResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a purchase order (buyer)",
)
async def create_order(
    payload: CreateOrderRequest, user: CurrentUser, orders: OrderSvc,
):
    order = await orders.create_order(user, payload.tool_id, payload.message)
    enriched = await orders.enrich([order])
    return enriched[0]


@router.get("", response_model=OrderListResponse, summary="List orders")
async def list_orders(
    user: CurrentUser,
    orders: OrderSvc,
    role: str = Query("seller", pattern="^(seller|buyer)$"),
    status_filter: OrderStatus | None = Query(None, alias="status"),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    items = await orders.list_orders(
        user, role_filter=role, status=status_filter,
        offset=offset, limit=limit,
    )
    enriched = await orders.enrich(items)
    return OrderListResponse(
        items=enriched, count=len(enriched), offset=offset, limit=limit,
    )


@router.get(
    "/{order_id}", response_model=OrderResponse,
    summary="Get one order",
)
async def get_order(order_id: int, user: CurrentUser, orders: OrderSvc):
    order = await orders.get_order(user, order_id)
    enriched = await orders.enrich([order])
    return enriched[0]


@router.post(
    "/{order_id}/approve", response_model=OrderResponse,
    summary="Approve an order (seller only)",
)
async def approve(order_id: int, user: CurrentUser, orders: OrderSvc):
    o = await orders.approve(user, order_id)
    enriched = await orders.enrich([o])
    return enriched[0]


@router.post(
    "/{order_id}/reject", response_model=OrderResponse,
    summary="Reject an order (seller only)",
)
async def reject(order_id: int, user: CurrentUser, orders: OrderSvc):
    o = await orders.reject(user, order_id)
    enriched = await orders.enrich([o])
    return enriched[0]


@router.post(
    "/{order_id}/complete", response_model=OrderResponse,
    summary="Mark an order as completed (seller only)",
)
async def complete(order_id: int, user: CurrentUser, orders: OrderSvc):
    o = await orders.complete(user, order_id)
    enriched = await orders.enrich([o])
    return enriched[0]


@router.delete(
    "/{order_id}", status_code=status.HTTP_204_NO_CONTENT,
    summary="Cancel an order (either party)",
)
async def cancel(order_id: int, user: CurrentUser, orders: OrderSvc):
    await orders.cancel(user, order_id)