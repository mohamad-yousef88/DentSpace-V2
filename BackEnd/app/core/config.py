"""
Application configuration.
"""
from functools import lru_cache
from pathlib import Path
from typing import Annotated, List

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict

import os

PROJECT_ROOT = Path(__file__).resolve().parents[2]
ENV_FILE = Path(os.getenv("ENV_FILE", str(PROJECT_ROOT / ".env")))


class Settings(BaseSettings):
    """Strongly-typed application settings."""

    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ─── App ───────────────────────────────────────────────
    app_name: str = "DentSpace API"
    app_env: str = "development"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"

    # ─── Security ──────────────────────────────────────────
    secret_key: str = Field(..., min_length=32)
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    # ─── Database ──────────────────────────────────────────
    database_url: str
    database_url_sync: str

    # ─── Cloudinary ────────────────────────────────────────
    cloudinary_cloud_name: str
    cloudinary_api_key: str
    cloudinary_api_secret: str
    cloudinary_upload_preset: str

    # ─── Firebase ──────────────────────────────────────────
    firebase_credentials_path: str = "./firebase-credentials.json"

    # ─── SMTP ──────────────────────────────────────────────
    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from_name: str = "DentSpace"

    # ─── OTP ───────────────────────────────────────────────
    otp_expire_minutes: int = 10

    # ─── CORS ──────────────────────────────────────────────
    allowed_origins: Annotated[List[str], NoDecode] = ["*"]

    # ─── Rate limiting ─────────────────────────────────────
    rate_limit_enabled: bool = True
    rate_limit_default: str = "120/minute"        # global fallback
    rate_limit_auth: str = "10/minute"            # stricter on /auth

    # ─── Security ──────────────────────────────────────────
    max_otp_attempts: int = 5
    sentry_dsn: str | None = None

    # ─── Admin Panel ───────────────────────────────────────
    session_secret: str = Field(
        ...,
        min_length=32,
        description="Secret key for signing admin session cookies",
    )
    admin_session_max_age: int = 8 * 3600  # 8 hours

    @field_validator("allowed_origins", mode="before")
    @classmethod
    def _split_origins(cls, v):
        if isinstance(v, str):
            return [o.strip() for o in v.split(",") if o.strip()]
        return v

    @property
    def is_production(self) -> bool:
        return self.app_env.lower() == "production"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()


settings = get_settings()