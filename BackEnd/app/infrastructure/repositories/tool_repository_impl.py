"""Tool repository implementation."""
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.tool import Tool, ToolStatus
from app.domain.repositories.tool_repository import ToolRepository
from app.infrastructure.database.models.tool_model import ToolModel, ToolStatusEnum


def _to_entity(m: ToolModel) -> Tool:
    return Tool(
        id=m.id,
        seller_id=m.seller_id,
        name=m.name,
        description=m.description,
        category=m.category,
        condition=m.condition,
        price=float(m.price),
        image_urls=list(m.image_urls or []),
        status=ToolStatus(m.status.value),
        created_at=m.created_at,
        updated_at=m.updated_at,
    )


def _to_enum(s: ToolStatus) -> ToolStatusEnum:
    return ToolStatusEnum(s.value)


class ToolRepositoryImpl(ToolRepository):

    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, tool_id: int) -> Tool | None:
        r = await self._session.execute(
            select(ToolModel).where(ToolModel.id == tool_id)
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def create(self, tool: Tool) -> Tool:
        m = ToolModel(
            seller_id=tool.seller_id,
            name=tool.name,
            description=tool.description,
            category=tool.category,
            condition=tool.condition,
            price=tool.price,
            image_urls=list(tool.image_urls),
            status=_to_enum(tool.status),
        )
        self._session.add(m)
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def update(self, tool: Tool) -> Tool:
        if tool.id is None:
            raise ValueError("Cannot update tool without id")
        r = await self._session.execute(
            select(ToolModel).where(ToolModel.id == tool.id)
        )
        m = r.scalar_one()
        m.name = tool.name
        m.description = tool.description
        m.category = tool.category
        m.condition = tool.condition
        m.price = tool.price
        m.image_urls = list(tool.image_urls)
        m.status = _to_enum(tool.status)
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def delete(self, tool_id: int) -> None:
        r = await self._session.execute(
            select(ToolModel).where(ToolModel.id == tool_id)
        )
        m = r.scalar_one_or_none()
        if m:
            await self._session.delete(m)

    async def count_by_seller_and_status(
        self, seller_id: int, status: ToolStatus,
    ) -> int:
        r = await self._session.execute(
            select(func.count(ToolModel.id)).where(
                ToolModel.seller_id == seller_id,
                ToolModel.status == _to_enum(status),
            )
        )
        return int(r.scalar() or 0)

    async def list_for_seller(self, seller_id, *, status=None, offset=0, limit=20):
        s = select(ToolModel).where(ToolModel.seller_id == seller_id)
        if status:
            s = s.where(ToolModel.status == _to_enum(status))
        s = s.order_by(ToolModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def list_available(
        self, *, search=None, category=None,
        exclude_seller_id=None, offset=0, limit=20,
    ):
        s = select(ToolModel).where(ToolModel.status == ToolStatusEnum.AVAILABLE)
        if exclude_seller_id is not None:
            s = s.where(ToolModel.seller_id != exclude_seller_id)
        if category:
            s = s.where(ToolModel.category == category)
        if search:
            like = f"%{search.strip()}%"
            s = s.where(or_(
                ToolModel.name.ilike(like),
                ToolModel.description.ilike(like),
            ))
        s = s.order_by(ToolModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]