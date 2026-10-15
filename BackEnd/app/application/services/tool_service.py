"""
Tool marketplace service.
"""
import asyncio
import logging
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dtos.tool_dto import (
    CreateToolRequest, ToolResponse, ToolSellerBrief, UpdateToolRequest,
)
from app.core.exceptions import (
    BadRequestException, ForbiddenException, NotFoundException,
)
from app.domain.entities.tool import Tool, ToolStatus
from app.domain.entities.user import User, UserRole
from app.infrastructure.external.cloudinary_client import (
    CloudinaryError, cloudinary_client, extract_public_id,
)
from app.infrastructure.repositories.order_repository_impl import OrderRepositoryImpl
from app.infrastructure.repositories.tool_repository_impl import ToolRepositoryImpl
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl

logger = logging.getLogger(__name__)

TOOL_FOLDER = "dentspace/tools"
MAX_IMAGES_PER_TOOL = 5
MAX_AVAILABLE_TOOLS_PER_SELLER = 5
MAX_IMAGE_BYTES = 5 * 1024 * 1024


class ToolService:

    def __init__(self, session: AsyncSession):
        self._session = session
        self._tools = ToolRepositoryImpl(session)
        self._orders = OrderRepositoryImpl(session)
        self._users = UserRepositoryImpl(session)

    # ─── Create ────────────────────────────────────────────
    async def create_tool(self, requester: User, data: CreateToolRequest) -> Tool:
        if requester.role not in (UserRole.DOCTOR, UserRole.ADMIN):
            raise ForbiddenException("Only doctors can sell tools.")

        count = await self._tools.count_by_seller_and_status(
            requester.id, ToolStatus.AVAILABLE,
        )
        if count >= MAX_AVAILABLE_TOOLS_PER_SELLER:
            raise BadRequestException(
                f"You cannot have more than {MAX_AVAILABLE_TOOLS_PER_SELLER} "
                f"available tools at the same time."
            )

        tool = Tool(
            seller_id=requester.id,
            name=data.name.strip(),
            description=data.description.strip(),
            category=data.category.strip(),
            condition=data.condition.strip(),
            price=float(data.price),
            status=ToolStatus.AVAILABLE,
            image_urls=[],
        )
        created = await self._tools.create(tool)
        logger.info("Tool created: id=%s seller=%s", created.id, requester.id)
        return created

    # ─── Read ──────────────────────────────────────────────
    async def get_tool(self, tool_id: int) -> Tool:
        tool = await self._tools.get_by_id(tool_id)
        if tool is None:
            raise NotFoundException("Tool not found.")
        return tool

    async def list_tools(
        self, requester: User, *,
        mine: bool, search: str | None, category: str | None,
        status: ToolStatus | None, offset: int, limit: int,
    ) -> list[Tool]:
        if mine:
            return await self._tools.list_for_seller(
                requester.id, status=status, offset=offset, limit=limit,
            )
        return await self._tools.list_available(
            search=search, category=category,
            exclude_seller_id=requester.id,
            offset=offset, limit=limit,
        )

    # ─── Update ────────────────────────────────────────────
    async def update_tool(
        self, requester: User, tool_id: int, data: UpdateToolRequest,
    ) -> Tool:
        tool = await self._tools.get_by_id(tool_id)
        if tool is None:
            raise NotFoundException("Tool not found.")
        if tool.seller_id != requester.id and requester.role != UserRole.ADMIN:
            raise ForbiddenException("You can only edit your own tools.")
        if tool.status == ToolStatus.SOLD:
            raise BadRequestException("Sold tools cannot be edited.")

        if data.name is not None:
            tool.name = data.name.strip()
        if data.description is not None:
            tool.description = data.description.strip()
        if data.category is not None:
            tool.category = data.category.strip()
        if data.condition is not None:
            tool.condition = data.condition.strip()
        if data.price is not None:
            tool.price = float(data.price)

        return await self._tools.update(tool)

    # ─── Delete ────────────────────────────────────────────
    async def delete_tool(self, requester: User, tool_id: int) -> None:
        tool = await self._tools.get_by_id(tool_id)
        if tool is None:
            raise NotFoundException("Tool not found.")
        if tool.seller_id != requester.id and requester.role != UserRole.ADMIN:
            raise ForbiddenException("You can only delete your own tools.")

        # Guard: no active orders
        active = await self._orders.list_active_for_tool(tool_id)
        if active:
            raise BadRequestException(
                "Cannot delete a tool with active orders. "
                "Cancel or complete them first."
            )

        # Cleanup images
        for url in tool.image_urls:
            pid = extract_public_id(url)
            if pid:
                cloudinary_client.delete_image(pid)

        await self._tools.delete(tool_id)
        logger.info("Tool deleted: id=%s (images cleaned)", tool_id)

    # ─── Images ────────────────────────────────────────────
    async def add_image(
        self, requester: User, tool_id: int,
        file, content_type: str | None, file_size: int | None,
    ) -> Tool:
        tool = await self._tools.get_by_id(tool_id)
        if tool is None:
            raise NotFoundException("Tool not found.")
        if tool.seller_id != requester.id:
            raise ForbiddenException("You can only modify your own tools.")
        if tool.status == ToolStatus.SOLD:
            raise BadRequestException("Sold tools cannot be modified.")
        if len(tool.image_urls) >= MAX_IMAGES_PER_TOOL:
            raise BadRequestException(
                f"A tool cannot have more than {MAX_IMAGES_PER_TOOL} images."
            )
        if content_type not in {"image/jpeg", "image/jpg", "image/png", "image/webp"}:
            raise BadRequestException("Only JPEG, PNG, or WEBP images are allowed.")
        if file_size is not None and file_size > MAX_IMAGE_BYTES:
            raise BadRequestException("Image too large. Max size is 5 MB.")

        folder = f"{TOOL_FOLDER}/{requester.id}"
        public_id = f"tool_{tool_id}_{uuid.uuid4().hex[:8]}"
        try:
            result = await asyncio.to_thread(
                cloudinary_client.upload_image, file, folder, public_id,
            )
        except CloudinaryError as exc:
            raise BadRequestException(str(exc))

        tool.image_urls = [*tool.image_urls, result.url]
        return await self._tools.update(tool)

    async def delete_image(
        self, requester: User, tool_id: int, index: int,
    ) -> Tool:
        tool = await self._tools.get_by_id(tool_id)
        if tool is None:
            raise NotFoundException("Tool not found.")
        if tool.seller_id != requester.id:
            raise ForbiddenException("You can only modify your own tools.")
        if index < 0 or index >= len(tool.image_urls):
            raise BadRequestException("Image index out of range.")

        url = tool.image_urls[index]
        pid = extract_public_id(url)
        if pid:
            cloudinary_client.delete_image(pid)

        remaining = list(tool.image_urls)
        remaining.pop(index)
        tool.image_urls = remaining
        return await self._tools.update(tool)

    # ─── Enrichment ────────────────────────────────────────
    async def enrich(self, tools: list[Tool]) -> list[ToolResponse]:
        seller_cache: dict[int, User] = {}
        for t in tools:
            if t.seller_id not in seller_cache:
                u = await self._users.get_by_id(t.seller_id)
                if u is not None:
                    seller_cache[t.seller_id] = u

        out: list[ToolResponse] = []
        for t in tools:
            resp = ToolResponse.model_validate(t.__dict__)
            s = seller_cache.get(t.seller_id)
            if s:
                resp.seller = ToolSellerBrief(
                    id=s.id, full_name=s.full_name, phone=s.phone,
                )
            out.append(resp)
        return out