"""Admin session dependencies — signed-cookie auth."""
from __future__ import annotations

from typing import Annotated

from fastapi import Depends, HTTPException, Request, status

from app.domain.entities.user import User, UserRole
from app.infrastructure.database.session import AsyncSessionLocal
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl


SESSION_USER_KEY = "admin_user_id"


async def get_current_admin(request: Request) -> User:
    """Fetch the current admin, or redirect to /admin/login."""
    user_id = request.session.get(SESSION_USER_KEY)

    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_307_TEMPORARY_REDIRECT,
            headers={"Location": "/admin/login"},
        )

    async with AsyncSessionLocal() as db:
        repo = UserRepositoryImpl(db)
        user = await repo.get_by_id(int(user_id))

    if (
        user is None
        or not user.is_active
        or user.role != UserRole.ADMIN
    ):
        request.session.clear()
        raise HTTPException(
            status_code=status.HTTP_307_TEMPORARY_REDIRECT,
            headers={"Location": "/admin/login"},
        )

    return user


CurrentAdmin = Annotated[User, Depends(get_current_admin)]