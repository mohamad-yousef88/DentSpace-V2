"""Tool domain entity (marketplace)."""
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum


class ToolStatus(str, Enum):
    AVAILABLE = "available"
    RESERVED = "reserved"     # an order was approved; pending completion
    SOLD = "sold"
    ARCHIVED = "archived"     # hidden by seller


@dataclass
class Tool:
    seller_id: int
    name: str
    description: str
    category: str
    condition: str            # "new" | "used" | free-text
    price: float
    status: ToolStatus = ToolStatus.AVAILABLE

    id: int | None = None
    image_urls: list[str] = field(default_factory=list)

    created_at: datetime | None = None
    updated_at: datetime | None = None

    @property
    def is_available(self) -> bool:
        return self.status == ToolStatus.AVAILABLE