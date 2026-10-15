"""Notification DTOs."""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.domain.entities.notification import NotificationType


class NotificationResponse(BaseModel):
    id: int
    title: str
    body: Optional[str] = None
    type: NotificationType
    payload: Optional[dict] = None
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationListResponse(BaseModel):
    items: list[NotificationResponse]
    count: int
    unread_count: int


class MessageResponse(BaseModel):
    message: str