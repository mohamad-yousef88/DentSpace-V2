"""
User domain entity.

Pure Python — no ORM, no framework.
Represents a user in the business domain.
"""
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum


class UserRole(str, Enum):
    PATIENT = "patient"
    DOCTOR = "doctor"
    ADMIN = "admin"


class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"


@dataclass
class User:
    """Domain representation of a user."""

    full_name: str
    email: str
    phone: str
    hashed_password: str
    role: UserRole = UserRole.PATIENT

    id: int | None = None
    gender: Gender | None = None
    age: int | None = None
    profile_image_url: str | None = None

    # University / Admin link
    university_id: str | None = None
    created_by_admin_id: int | None = None
    is_verified_by_admin: bool = False

    # Push notifications
    fcm_token: str | None = None

    # Status
    is_active: bool = True
    is_email_verified: bool = False

    created_at: datetime | None = None
    updated_at: datetime | None = None
    password_changed_at: datetime | None = None

    # ─── Helpers ──────────────────────────────────────────
    @property
    def is_doctor(self) -> bool:
        return self.role == UserRole.DOCTOR

    @property
    def is_patient(self) -> bool:
        return self.role == UserRole.PATIENT

    @property
    def is_admin(self) -> bool:
        return self.role == UserRole.ADMIN