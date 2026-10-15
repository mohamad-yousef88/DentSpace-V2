"""
User repository implementation using SQLAlchemy.
"""
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.user import User as UserEntity
from app.domain.entities.user import UserRole, Gender
from app.domain.repositories.user_repository import UserRepository
from app.infrastructure.database.models.user_model import User as UserModel
from app.infrastructure.database.models.user_model import (
    UserRole as UserRoleModel,
    Gender as GenderModel,
)


# ═══════════════════════════════════════════════════════════════
# Mappers
# ═══════════════════════════════════════════════════════════════
def _to_entity(model: UserModel) -> UserEntity:
    return UserEntity(
        id=model.id,
        full_name=model.full_name,
        email=model.email,
        phone=model.phone,
        hashed_password=model.hashed_password,
        role=UserRole(model.role.value),
        gender=Gender(model.gender.value) if model.gender else None,
        age=model.age,
        profile_image_url=model.profile_image_url,
        university_id=model.university_id,
        created_by_admin_id=model.created_by_admin_id,
        is_verified_by_admin=model.is_verified_by_admin,
        fcm_token=model.fcm_token,
        is_active=model.is_active,
        is_email_verified=model.is_email_verified,
        password_changed_at=model.password_changed_at,
        created_at=model.created_at,
        updated_at=model.updated_at,
    )


def _to_model(entity: UserEntity) -> UserModel:
    return UserModel(
        id=entity.id,
        full_name=entity.full_name,
        email=entity.email,
        phone=entity.phone,
        hashed_password=entity.hashed_password,
        role=UserRoleModel(entity.role.value),
        gender=GenderModel(entity.gender.value) if entity.gender else None,
        age=entity.age,
        profile_image_url=entity.profile_image_url,
        university_id=entity.university_id,
        created_by_admin_id=entity.created_by_admin_id,
        is_verified_by_admin=entity.is_verified_by_admin,
        fcm_token=entity.fcm_token,
        is_active=entity.is_active,
        is_email_verified=entity.is_email_verified,
        password_changed_at=entity.password_changed_at or datetime.now(timezone.utc),
    )


# ═══════════════════════════════════════════════════════════════
# Repository
# ═══════════════════════════════════════════════════════════════
class UserRepositoryImpl(UserRepository):
    """Concrete UserRepository backed by SQLAlchemy."""

    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, user_id: int) -> UserEntity | None:
        result = await self._session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        model = result.scalar_one_or_none()
        return _to_entity(model) if model else None

    async def get_by_email(self, email: str) -> UserEntity | None:
        result = await self._session.execute(
            select(UserModel).where(UserModel.email == email.lower().strip())
        )
        model = result.scalar_one_or_none()
        return _to_entity(model) if model else None

    async def get_by_phone(self, phone: str) -> UserEntity | None:
        result = await self._session.execute(
            select(UserModel).where(UserModel.phone == phone.strip())
        )
        model = result.scalar_one_or_none()
        return _to_entity(model) if model else None

    async def get_by_university_id(self, university_id: str) -> UserEntity | None:
        result = await self._session.execute(
            select(UserModel).where(UserModel.university_id == university_id.strip())
        )
        model = result.scalar_one_or_none()
        return _to_entity(model) if model else None

    async def get_many_by_ids(self, user_ids: set[int]) -> dict[int, UserEntity]:
        """Batch fetch — returns {id: user}. Empty set → empty dict."""
        if not user_ids:
            return {}
        result = await self._session.execute(
            select(UserModel).where(UserModel.id.in_(user_ids))
        )
        return {m.id: _to_entity(m) for m in result.scalars().all()}

    async def create(self, user: UserEntity) -> UserEntity:
        model = _to_model(user)
        model.id = None  # let DB assign
        self._session.add(model)
        await self._session.flush()   # assign ID
        await self._session.refresh(model)
        return _to_entity(model)

    async def update(self, user: UserEntity) -> UserEntity:
        if user.id is None:
            raise ValueError("Cannot update user without id")
        result = await self._session.execute(
            select(UserModel).where(UserModel.id == user.id)
        )
        model = result.scalar_one()
        model.full_name = user.full_name
        model.email = user.email
        model.phone = user.phone
        model.hashed_password = user.hashed_password
        model.role = UserRoleModel(user.role.value)
        model.gender = GenderModel(user.gender.value) if user.gender else None
        model.age = user.age
        model.profile_image_url = user.profile_image_url
        model.university_id = user.university_id
        model.is_verified_by_admin = user.is_verified_by_admin
        model.fcm_token = user.fcm_token
        model.is_active = user.is_active
        model.is_email_verified = user.is_email_verified
        if user.password_changed_at is not None:
            model.password_changed_at = user.password_changed_at
        await self._session.flush()
        await self._session.refresh(model)
        return _to_entity(model)

    async def delete(self, user_id: int) -> None:
        result = await self._session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        model = result.scalar_one_or_none()
        if model:
            await self._session.delete(model)

    async def exists_by_email(self, email: str) -> bool:
        result = await self._session.execute(
            select(UserModel.id).where(UserModel.email == email.lower().strip())
        )
        return result.scalar_one_or_none() is not None

    async def exists_by_phone(self, phone: str) -> bool:
        result = await self._session.execute(
            select(UserModel.id).where(UserModel.phone == phone.strip())
        )
        return result.scalar_one_or_none() is not None
    async def list_users(
        self, *, role=None, is_active=None, search=None,
        offset=0, limit=20,
    ):
        from sqlalchemy import or_
        s = select(UserModel)
        if role is not None:
            s = s.where(UserModel.role == UserRoleModel(role.value))
        if is_active is not None:
            s = s.where(UserModel.is_active.is_(is_active))
        if search:
            like = f"%{search.strip()}%"
            s = s.where(or_(
                UserModel.full_name.ilike(like),
                UserModel.email.ilike(like),
                UserModel.phone.ilike(like),
                UserModel.university_id.ilike(like),
            ))
        s = s.order_by(UserModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def count_by_role(self) -> dict[str, int]:
        from sqlalchemy import func
        r = await self._session.execute(
            select(UserModel.role, func.count(UserModel.id))
            .group_by(UserModel.role)
        )
        return {role.value: int(count) for role, count in r.all()}