"""Notification router."""
from fastapi import APIRouter, Query, status

from app.application.dtos.notification_dto import (
    MessageResponse, NotificationListResponse, NotificationResponse,
)
from app.core.dependencies import CurrentUser, NotificationSvc

router = APIRouter()


@router.get(
    "",
    response_model=NotificationListResponse,
    summary="List my notifications",
)
async def list_notifications(
    user: CurrentUser,
    svc: NotificationSvc,
    offset: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
):
    items, unread = await svc.list_for_requester(user, offset=offset, limit=limit)
    return NotificationListResponse(
        items=[NotificationResponse.model_validate(n.__dict__) for n in items],
        count=len(items),
        unread_count=unread,
    )


@router.post(
    "/{notification_id}/read",
    response_model=MessageResponse,
    summary="Mark one notification as read",
)
async def mark_read(
    notification_id: int, user: CurrentUser, svc: NotificationSvc,
):
    await svc.mark_read(user, notification_id)
    return MessageResponse(message="Notification marked as read.")


@router.post(
    "/read-all",
    response_model=MessageResponse,
    summary="Mark all my notifications as read",
)
async def mark_all_read(user: CurrentUser, svc: NotificationSvc):
    count = await svc.mark_all_read(user)
    return MessageResponse(message=f"Marked {count} notifications as read.")


@router.delete(
    "/{notification_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete one notification",
)
async def delete_notification(
    notification_id: int, user: CurrentUser, svc: NotificationSvc,
):
    await svc.delete(user, notification_id)


@router.delete(
    "",
    response_model=MessageResponse,
    summary="Delete all read notifications",
)
async def delete_read(user: CurrentUser, svc: NotificationSvc):
    count = await svc.delete_read(user)
    return MessageResponse(message=f"Deleted {count} read notifications.")