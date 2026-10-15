"""Order domain entity (tool purchase)."""
from dataclasses import dataclass
from datetime import datetime
from enum import Enum


class OrderStatus(str, Enum):
    PENDING   = "pending"      # buyer requested; seller hasn't responded
    APPROVED  = "approved"     # seller accepted; awaiting completion
    REJECTED  = "rejected"     # seller refused
    CANCELLED = "cancelled"    # either party cancelled
    COMPLETED = "completed"    # seller completed; tool is sold


@dataclass
class Order:
    tool_id: int
    buyer_id: int
    seller_id: int
    status: OrderStatus = OrderStatus.PENDING

    id: int | None = None
    buyer_phone: str | None = None       # snapshot at order time
    message: str | None = None
    responded_at: datetime | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    rejection_reason: str | None = None

    @property
    def is_pending(self) -> bool:
        return self.status == OrderStatus.PENDING

    @property
    def is_active(self) -> bool:
        return self.status in (OrderStatus.PENDING, OrderStatus.APPROVED)