"""
End-to-end authentication flow tests.
"""
import pytest

from app.domain.entities.user import UserRole
from app.infrastructure.database.models.email_verification_model import (
    EmailVerification,
)
from sqlalchemy import select

from tests.helpers.factories import create_user

pytestmark = pytest.mark.integration


# ═══════════════════════════════════════════════════════════════
# Registration
# ═══════════════════════════════════════════════════════════════
class TestRegistration:

    async def test_register_success(self, client, db_session):
        resp = await client.post("/api/v1/auth/register", json={
            "full_name": "New Patient Test",
            "email": "new@test.com",
            "phone": "0991111111",
            "password": "StrongPass1234!",
            "confirm_password": "StrongPass1234!",
            "gender": "male",
            "age": 25,
        })
        assert resp.status_code == 201, resp.text

        # OTP row created
        result = await db_session.execute(select(EmailVerification))
        rows = result.scalars().all()
        assert len(rows) == 1
        assert len(rows[0].otp_code) == 6

    async def test_register_weak_password_rejected(self, client):
        resp = await client.post("/api/v1/auth/register", json={
            "full_name": "New Patient Test",
            "email": "new@test.com",
            "phone": "0991111111",
            "password": "weak",
            "confirm_password": "weak",
            "gender": "male",
            "age": 25,
        })
        assert resp.status_code == 422

    async def test_register_password_mismatch_rejected(self, client):
        resp = await client.post("/api/v1/auth/register", json={
            "full_name": "New Patient Test",
            "email": "new@test.com",
            "phone": "0991111111",
            "password": "StrongPass1234!",
            "confirm_password": "DifferentPass1234!",
            "gender": "male",
            "age": 25,
        })
        assert resp.status_code == 422

    async def test_register_duplicate_email(self, client, db_session):
        await create_user(
            db_session, email="exists@test.com", phone="0999111111",
        )
        resp = await client.post("/api/v1/auth/register", json={
            "full_name": "Another Patient",
            "email": "exists@test.com",
            "phone": "0991111111",
            "password": "StrongPass1234!",
            "confirm_password": "StrongPass1234!",
            "gender": "male",
            "age": 25,
        })
        assert resp.status_code == 409


# ═══════════════════════════════════════════════════════════════
# Email verification + OTP
# ═══════════════════════════════════════════════════════════════
class TestEmailVerification:

    async def test_verify_email_success(self, client, db_session):
        # Register
        await client.post("/api/v1/auth/register", json={
            "full_name": "Verify Me Please",
            "email": "verify@test.com",
            "phone": "0991111112",
            "password": "StrongPass1234!",
            "confirm_password": "StrongPass1234!",
            "gender": "male",
            "age": 25,
        })
        # Read OTP from DB
        result = await db_session.execute(
            select(EmailVerification).order_by(
                EmailVerification.created_at.desc()
            ).limit(1)
        )
        otp = result.scalar_one().otp_code

        resp = await client.post("/api/v1/auth/verify-email", json={
            "email": "verify@test.com",
            "otp_code": otp,
        })
        assert resp.status_code == 200
        body = resp.json()
        assert body["user"]["is_email_verified"] is True
        assert body["tokens"]["access_token"]
        assert body["tokens"]["refresh_token"]

    async def test_wrong_otp_5_times_invalidates(self, client, db_session):
        await client.post("/api/v1/auth/register", json={
            "full_name": "Brute Force Me",
            "email": "brute@test.com",
            "phone": "0991111113",
            "password": "StrongPass1234!",
            "confirm_password": "StrongPass1234!",
            "gender": "male",
            "age": 25,
        })
        result = await db_session.execute(
            select(EmailVerification).order_by(
                EmailVerification.created_at.desc()
            ).limit(1)
        )
        row = result.scalar_one()
        real_otp = row.otp_code
        wrong = "000000" if real_otp != "000000" else "111111"

        # 5 wrong attempts
        for _ in range(5):
            resp = await client.post("/api/v1/auth/verify-email", json={
                "email": "brute@test.com",
                "otp_code": wrong,
            })
            assert resp.status_code == 400

        # Even the right OTP should now fail — code was invalidated
        resp = await client.post("/api/v1/auth/verify-email", json={
            "email": "brute@test.com",
            "otp_code": real_otp,
        })
        assert resp.status_code == 400


# ═══════════════════════════════════════════════════════════════
# Login / tokens
# ═══════════════════════════════════════════════════════════════
class TestLogin:

    async def test_login_success(self, client, db_session):
        await create_user(
            db_session,
            email="login@test.com",
            phone="0991111114",
            password="StrongPass1234!",
        )
        resp = await client.post("/api/v1/auth/login", json={
            "email": "login@test.com",
            "password": "StrongPass1234!",
        })
        assert resp.status_code == 200
        assert resp.json()["tokens"]["access_token"]

    async def test_login_wrong_password(self, client, db_session):
        await create_user(
            db_session,
            email="login2@test.com",
            phone="0991111115",
            password="StrongPass1234!",
        )
        resp = await client.post("/api/v1/auth/login", json={
            "email": "login2@test.com",
            "password": "WrongPassword1234!",
        })
        assert resp.status_code == 401

    async def test_login_inactive_user_forbidden(self, client, db_session):
        await create_user(
            db_session,
            email="inactive@test.com",
            phone="0991111116",
            password="StrongPass1234!",
            is_active=False,
        )
        resp = await client.post("/api/v1/auth/login", json={
            "email": "inactive@test.com",
            "password": "StrongPass1234!",
        })
        assert resp.status_code == 403

    async def test_login_unverified_email_forbidden(self, client, db_session):
        await create_user(
            db_session,
            email="unverified@test.com",
            phone="0991111117",
            password="StrongPass1234!",
            is_email_verified=False,
        )
        resp = await client.post("/api/v1/auth/login", json={
            "email": "unverified@test.com",
            "password": "StrongPass1234!",
        })
        assert resp.status_code == 403


# ═══════════════════════════════════════════════════════════════
# Refresh
# ═══════════════════════════════════════════════════════════════
class TestRefresh:

    async def test_refresh_success(self, client, db_session):
        await create_user(
            db_session,
            email="refresh@test.com",
            phone="0991111118",
            password="StrongPass1234!",
        )
        login = await client.post("/api/v1/auth/login", json={
            "email": "refresh@test.com",
            "password": "StrongPass1234!",
        })
        refresh_token = login.json()["tokens"]["refresh_token"]

        resp = await client.post("/api/v1/auth/refresh", json={
            "refresh_token": refresh_token,
        })
        assert resp.status_code == 200
        assert resp.json()["access_token"]


# ═══════════════════════════════════════════════════════════════
# JWT revocation
# ═══════════════════════════════════════════════════════════════
class TestSessionRevocation:

    async def test_logout_all_invalidates_existing_token(
        self, patient_client, client,
    ):
        # Token works
        me = await patient_client.get("/api/v1/auth/me")
        assert me.status_code == 200

        # Logout all
        logout = await patient_client.post("/api/v1/auth/logout-all")
        assert logout.status_code == 200

        # Same token now fails
        me_after = await patient_client.get("/api/v1/auth/me")
        assert me_after.status_code == 401


# ═══════════════════════════════════════════════════════════════
# Profile
# ═══════════════════════════════════════════════════════════════
class TestProfile:

    async def test_get_me(self, patient_client, patient_user):
        resp = await patient_client.get("/api/v1/auth/me")
        assert resp.status_code == 200
        assert resp.json()["id"] == patient_user.id

    async def test_update_profile_partial(self, patient_client):
        resp = await patient_client.patch("/api/v1/auth/me", json={
            "full_name": "Updated Full Name",
        })
        assert resp.status_code == 200
        assert resp.json()["full_name"] == "Updated Full Name"

    async def test_unauthenticated_returns_401(self, client):
        resp = await client.get("/api/v1/auth/me")
        assert resp.status_code in (401, 403)


# ═══════════════════════════════════════════════════════════════
# Admin: create doctor
# ═══════════════════════════════════════════════════════════════
class TestAdminCreatesDoctor:

    async def test_admin_creates_doctor(self, admin_client, db_session):
        resp = await admin_client.post(
            "/api/v1/auth/admin/create-doctor",
            json={
                "full_name": "Doctor Freshly Made",
                "email": "freshdoc@test.com",
                "phone": "0944444444",
                "password": "StrongPass1234!",
                "university_id": "UNI-NEW-01",
                "gender": "female",
                "age": 27,
            },
        )
        assert resp.status_code == 201, resp.text
        body = resp.json()
        assert body["role"] == UserRole.DOCTOR.value
        assert body["is_verified_by_admin"] is True
        assert body["is_email_verified"] is True

    async def test_non_admin_cannot_create_doctor(self, patient_client):
        resp = await patient_client.post(
            "/api/v1/auth/admin/create-doctor",
            json={
                "full_name": "Should Fail Here",
                "email": "fail@test.com",
                "phone": "0944444445",
                "password": "StrongPass1234!",
                "university_id": "UNI-NEW-02",
                "gender": "male",
                "age": 25,
            },
        )
        assert resp.status_code == 403