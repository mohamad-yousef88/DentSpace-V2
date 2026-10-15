"""
Authentication DTOs (Data Transfer Objects).
"""
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.core.validators import validate_password_strength
from app.domain.entities.user import Gender, UserRole


# ═══════════════════════════════════════════════════════════════
# Requests
# ═══════════════════════════════════════════════════════════════
class RegisterPatientRequest(BaseModel):
    full_name: str = Field(..., min_length=10, max_length=150)
    email: EmailStr
    phone: str = Field(..., min_length=10, max_length=20)
    password: str = Field(..., min_length=12, max_length=128)
    confirm_password: str = Field(..., min_length=12, max_length=128)
    gender: Gender
    age: int = Field(..., ge=18, le=80)

    @field_validator("phone")
    @classmethod
    def _validate_phone(cls, v: str) -> str:
        v = v.strip()
        if not v.startswith("09") and not v.startswith("+9639"):
            raise ValueError("Phone must start with 09 or +9639")
        if len(v.replace("+", "")) < 10:
            raise ValueError("Phone is too short")
        return v

    @field_validator("password")
    @classmethod
    def _strong_password(cls, v: str) -> str:
        return validate_password_strength(v)

    @field_validator("confirm_password")
    @classmethod
    def _passwords_match(cls, v: str, info) -> str:
        if "password" in info.data and v != info.data["password"]:
            raise ValueError("Passwords do not match")
        return v


class VerifyEmailRequest(BaseModel):
    email: EmailStr
    otp_code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")


class ResendOtpRequest(BaseModel):
    email: EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)
    platform: str | None = Field(
        None,
        description="Client platform hint: 'mobile' | 'web' | None",
    )


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., min_length=10)


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp_code: str = Field(..., min_length=6, max_length=6, pattern=r"^\d{6}$")
    new_password: str = Field(..., min_length=12, max_length=128)

    @field_validator("new_password")
    @classmethod
    def _strong(cls, v: str) -> str:
        return validate_password_strength(v)


class CreateDoctorRequest(BaseModel):
    """Used by admin to create a doctor account."""

    full_name: str = Field(..., min_length=10, max_length=150)
    email: EmailStr
    phone: str = Field(..., min_length=10, max_length=20)
    password: str = Field(..., min_length=12, max_length=128)
    university_id: str = Field(..., min_length=3, max_length=50)
    gender: Gender
    age: int = Field(..., ge=18, le=80)

    @field_validator("phone")
    @classmethod
    def _validate_phone(cls, v: str) -> str:
        v = v.strip()
        if not v.startswith("09") and not v.startswith("+9639"):
            raise ValueError("Phone must start with 09 or +9639")
        if len(v.replace("+", "")) < 10:
            raise ValueError("Phone is too short")
        return v

    @field_validator("password")
    @classmethod
    def _strong_password(cls, v: str) -> str:
        return validate_password_strength(v)


class CreateAdminRequest(BaseModel):
    """Used to bootstrap the first admin account (CLI only)."""

    full_name: str = Field(..., min_length=10, max_length=150)
    email: EmailStr
    phone: str = Field(..., min_length=10, max_length=20)
    password: str = Field(..., min_length=12, max_length=128)
    confirm_password: str = Field(..., min_length=12, max_length=128)
    gender: Optional[Gender] = None
    age: Optional[int] = Field(None, ge=18, le=80)

    @field_validator("phone")
    @classmethod
    def _validate_phone(cls, v: str) -> str:
        v = v.strip()
        if not v.startswith("09") and not v.startswith("+9639"):
            raise ValueError("Phone must start with 09 or +9639")
        if len(v.replace("+", "")) < 10:
            raise ValueError("Phone is too short")
        return v

    @field_validator("password")
    @classmethod
    def _strong_password(cls, v: str) -> str:
        return validate_password_strength(v)

    @field_validator("confirm_password")
    @classmethod
    def _passwords_match(cls, v: str, info) -> str:
        if "password" in info.data and v != info.data["password"]:
            raise ValueError("Passwords do not match")
        return v


class UpdateFcmTokenRequest(BaseModel):
    fcm_token: str = Field(..., min_length=10, max_length=500)


class UpdateProfileRequest(BaseModel):
    """Partial update — all fields optional (PATCH semantics)."""

    full_name: Optional[str] = Field(None, min_length=10, max_length=150)
    phone: Optional[str] = Field(None, min_length=10, max_length=20)
    gender: Optional[Gender] = None
    age: Optional[int] = Field(None, ge=18, le=80)

    @field_validator("phone")
    @classmethod
    def _validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        v = v.strip()
        if not v.startswith("09") and not v.startswith("+9639"):
            raise ValueError("Phone must start with 09 or +9639")
        if len(v.replace("+", "")) < 10:
            raise ValueError("Phone is too short")
        return v


# ═══════════════════════════════════════════════════════════════
# Responses
# ═══════════════════════════════════════════════════════════════
class UserResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    phone: str
    role: UserRole
    gender: Optional[Gender] = None
    age: Optional[int] = None
    profile_image_url: Optional[str] = None
    university_id: Optional[str] = None
    is_active: bool
    is_email_verified: bool
    is_verified_by_admin: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds


class AuthResponse(BaseModel):
    user: UserResponse
    tokens: TokenResponse


class MessageResponse(BaseModel):
    message: str