"""
Test data factories — reusable helpers to build DB entities fast.

Every factory commits before returning so the app (which runs in a
separate session) sees the rows immediately.
"""
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.domain.entities.patient_case import CaseStatus, CaseUrgency, PatientCase
from app.domain.entities.user import Gender, User, UserRole
from app.infrastructure.repositories.case_repository_impl import CaseRepositoryImpl
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl


# ═══════════════════════════════════════════════════════════════
# Users
# ═══════════════════════════════════════════════════════════════
async def create_user(
    session: AsyncSession,
    *,
    role: UserRole = UserRole.PATIENT,
    email: str = "user@test.com",
    phone: str = "0911111111",
    full_name: str = "Test User Fullname",
    password: str = "TestPass1234!",
    is_active: bool = True,
    is_email_verified: bool = True,
    is_verified_by_admin: bool = False,
    university_id: str | None = None,
    age: int = 25,
    gender: Gender = Gender.MALE,
) -> User:
    repo = UserRepositoryImpl(session)
    user = User(
        full_name=full_name,
        email=email,
        phone=phone,
        hashed_password=hash_password(password),
        role=role,
        gender=gender,
        age=age,
        is_active=is_active,
        is_email_verified=is_email_verified,
        is_verified_by_admin=is_verified_by_admin,
        university_id=university_id,
        password_changed_at=datetime.now(timezone.utc),
    )
    created = await repo.create(user)
    await session.commit()
    return created


# ═══════════════════════════════════════════════════════════════
# Cases
# ═══════════════════════════════════════════════════════════════
async def create_case(
    session: AsyncSession,
    *,
    patient_id: int,
    status: CaseStatus = CaseStatus.PENDING,
    doctor_id: int | None = None,
    suspected_condition: str = "تسوس الأسنان",
    location: str = "الفك العلوي الأيسر",
) -> PatientCase:
    repo = CaseRepositoryImpl(session)
    case = PatientCase(
        patient_id=patient_id,
        doctor_id=doctor_id,
        symptoms=["ثقوب أو تجاويف ظاهرة"],
        suspected_condition=suspected_condition,
        location=location,
        pain_level=3.0,
        swelling_level=0.0,
        diagnosis_confidence=0.7,
        alternate_conditions=[],
        urgency=CaseUrgency.SOON,
        red_flags=[],
        status=status,
    )
    created = await repo.create(case)
    await session.commit()
    return created