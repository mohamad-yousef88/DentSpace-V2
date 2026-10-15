"""Tool DTOs."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.domain.entities.tool import ToolStatus


class CreateToolRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=150)
    description: str = Field(..., min_length=5, max_length=2000)
    category: str = Field(..., min_length=1, max_length=80)
    condition: str = Field(..., min_length=1, max_length=80)
    price: float = Field(..., gt=0, le=1_000_000)


class UpdateToolRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=150)
    description: Optional[str] = Field(None, min_length=5, max_length=2000)
    category: Optional[str] = Field(None, min_length=1, max_length=80)
    condition: Optional[str] = Field(None, min_length=1, max_length=80)
    price: Optional[float] = Field(None, gt=0, le=1_000_000)


class ToolSellerBrief(BaseModel):
    id: int
    full_name: str
    phone: str


class ToolResponse(BaseModel):
    id: int
    name: str
    description: str
    category: str
    condition: str
    price: float
    image_urls: list[str]
    status: ToolStatus
    created_at: datetime
    updated_at: datetime

    seller_id: int
    seller: Optional[ToolSellerBrief] = None

    model_config = {"from_attributes": True}


class ToolListResponse(BaseModel):
    items: list[ToolResponse]
    count: int
    offset: int
    limit: int