"""Tool ORM model."""
import enum

from sqlalchemy import (
    ARRAY, Enum as SAEnum, Float, ForeignKey, Index, Integer,
    Numeric, String, Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.database.base import Base, TimestampMixin


class ToolStatusEnum(str, enum.Enum):
    AVAILABLE = "available"
    RESERVED = "reserved"
    SOLD = "sold"
    ARCHIVED = "archived"


class ToolModel(Base, TimestampMixin):
    __tablename__ = "tools"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    seller_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False, index=True,
    )

    name: Mapped[str] = mapped_column(String(150), nullable=False, index=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(String(80), nullable=False, index=True)
    condition: Mapped[str] = mapped_column(String(80), nullable=False)
    price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    image_urls: Mapped[list[str]] = mapped_column(
        ARRAY(Text), nullable=False, default=list,
    )

    status: Mapped[ToolStatusEnum] = mapped_column(
        SAEnum(
            ToolStatusEnum,
            name="tool_status_enum",
            values_callable=lambda x: [e.value for e in x],
        ),
        default=ToolStatusEnum.AVAILABLE,
        nullable=False,
    )

    __table_args__ = (
        Index("ix_tools_status_created", "status", "created_at"),
        Index("ix_tools_seller_status", "seller_id", "status"),
        Index("ix_tools_category_status", "category", "status"),
    )