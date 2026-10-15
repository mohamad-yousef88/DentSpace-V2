"""
User ORM model.

Design notes:
- `email`, `phone`, `university_id` are unique (indexed for fast lookup).
- `role` is an Enum to prevent invalid values.
- `created_by_admin_id` references the admin who created the account.
- `is_verified_by_admin` gates doctor accounts (admin must approve).
- Composite indexes speed up role-filtered queries.
"""
import enum
from datetime import datetime

from sqlalchemy import Boolean, Enum as SAEnum, ForeignKey, Index, Integer, String, DateTime, func
from sqlalchemy.orm import Mapped, mapped_column

from app.infrastructure.database.base import Base, TimestampMixin


# ═══════════════════════════════════════════════════════════════
# Enums
# ═══════════════════════════════════════════════════════════════
class UserRole(str, enum.Enum):
    PATIENT = "patient"
    DOCTOR = "doctor"
    ADMIN = "admin"


class Gender(str, enum.Enum):
    MALE = "male"
    FEMALE = "female"


# ═══════════════════════════════════════════════════════════════
# Model
# ═══════════════════════════════════════════════════════════════
class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)

    # ─── Identity ─────────────────────────────────────────
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, index=True, nullable=False
    )
    phone: Mapped[str] = mapped_column(
        String(20), unique=True, index=True, nullable=False
    )
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)

    # ─── Profile ──────────────────────────────────────────
    role: Mapped[UserRole] = mapped_column(
        SAEnum(
            UserRole,
            name="user_role_enum",
            values_callable=lambda x: [e.value for e in x],  # ★ يُصلح المشكلة
        ),
        default=UserRole.PATIENT,
        nullable=False,
    )
    gender: Mapped[Gender | None] = mapped_column(
        SAEnum(
            Gender,
            name="gender_enum",
            values_callable=lambda x: [e.value for e in x],  # ★
        ),
        nullable=True,
    )
    age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    profile_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # ─── University / Admin link (doctors only) ───────────
    university_id: Mapped[str | None] = mapped_column(
        String(50), unique=True, index=True, nullable=True
    )
    created_by_admin_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    is_verified_by_admin: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )

    # ─── Push notifications ───────────────────────────────
    fcm_token: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # ─── Status ───────────────────────────────────────────
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_email_verified: Mapped[bool] = mapped_column(
        Boolean, default=False, nullable=False
    )
    password_changed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    # ─── Composite indexes ────────────────────────────────
    __table_args__ = (
        Index("ix_users_role_active", "role", "is_active"),
        Index("ix_users_created_at", "created_at"),
        Index("ix_users_role_verified", "role", "is_verified_by_admin"),
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email} role={self.role.value}>"