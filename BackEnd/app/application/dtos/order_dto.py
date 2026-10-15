"""Order DTOs."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.domain.entities.order import OrderStatus
from app.domain.entities.tool import ToolStatus


class CreateOrderRequest(BaseModel):
    tool_id: int = Field(..., gt=0)
    message: Optional[str] = Field(None, max_length=1000)


class OrderToolBrief(BaseModel):
    id: int
    name: str
    category: str
    condition: str
    price: float
    image_urls: list[str]
    status: ToolStatus


class OrderUserBrief(BaseModel):
    id: int
    full_name: str
    phone: str


class OrderResponse(BaseModel):
    id: int
    status: OrderStatus
    message: Optional[str] = None
    responded_at: Optional[datetime] = None
    created_at: datetime

    tool: Optional[OrderToolBrief] = None
    buyer: Optional[OrderUserBrief] = None
    seller: Optional[OrderUserBrief] = None

    model_config = {"from_attributes": True}


class OrderListResponse(BaseModel):
    items: list[OrderResponse]
    count: int
    offset: int
    limit: int