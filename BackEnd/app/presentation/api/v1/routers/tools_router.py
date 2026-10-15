"""Tools marketplace router."""
from fastapi import APIRouter, File, Query, UploadFile, status

from app.application.dtos.tool_dto import (
    CreateToolRequest, ToolListResponse, ToolResponse, UpdateToolRequest,
)
from app.core.dependencies import CurrentUser, ToolSvc
from app.domain.entities.tool import ToolStatus

router = APIRouter()


@router.post(
    "", response_model=ToolResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new tool listing (doctor only)",
)
async def create_tool(
    payload: CreateToolRequest, user: CurrentUser, tools: ToolSvc,
):
    tool = await tools.create_tool(user, payload)
    enriched = await tools.enrich([tool])
    return enriched[0]


@router.get("", response_model=ToolListResponse, summary="List tools")
async def list_tools(
    user: CurrentUser,
    tools: ToolSvc,
    mine: bool = Query(False, description="Limit to my listings"),
    search: str | None = Query(None),
    category: str | None = Query(None),
    status_filter: ToolStatus | None = Query(None, alias="status"),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    items = await tools.list_tools(
        user, mine=mine, search=search, category=category,
        status=status_filter, offset=offset, limit=limit,
    )
    enriched = await tools.enrich(items)
    return ToolListResponse(
        items=enriched, count=len(enriched), offset=offset, limit=limit,
    )


@router.get("/{tool_id}", response_model=ToolResponse, summary="Get a tool")
async def get_tool(tool_id: int, user: CurrentUser, tools: ToolSvc):
    tool = await tools.get_tool(tool_id)
    enriched = await tools.enrich([tool])
    return enriched[0]


@router.patch(
    "/{tool_id}", response_model=ToolResponse,
    summary="Update a tool (owner only)",
)
async def update_tool(
    tool_id: int, payload: UpdateToolRequest,
    user: CurrentUser, tools: ToolSvc,
):
    tool = await tools.update_tool(user, tool_id, payload)
    enriched = await tools.enrich([tool])
    return enriched[0]


@router.delete(
    "/{tool_id}", status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a tool (owner only, no active orders)",
)
async def delete_tool(tool_id: int, user: CurrentUser, tools: ToolSvc):
    await tools.delete_tool(user, tool_id)


@router.post(
    "/{tool_id}/images", response_model=ToolResponse,
    summary="Upload one image to a tool",
)
async def add_image(
    tool_id: int, user: CurrentUser, tools: ToolSvc,
    file: UploadFile = File(...),
):
    size = None
    try:
        await file.seek(0)
        content = await file.read()
        size = len(content)
        await file.seek(0)
    except Exception:
        size = None
    tool = await tools.add_image(
        user, tool_id, file.file, file.content_type, size,
    )
    enriched = await tools.enrich([tool])
    return enriched[0]


@router.delete(
    "/{tool_id}/images/{index}", response_model=ToolResponse,
    summary="Remove one image from a tool by index",
)
async def remove_image(
    tool_id: int, index: int, user: CurrentUser, tools: ToolSvc,
):
    tool = await tools.delete_image(user, tool_id, index)
    enriched = await tools.enrich([tool])
    return enriched[0]