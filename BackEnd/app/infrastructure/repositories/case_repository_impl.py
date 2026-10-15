"""
PatientCase repository implementation using SQLAlchemy.
"""
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.patient_case import (
    CaseStatus, CaseUrgency, PatientCase,
)
from app.domain.repositories.case_repository import CaseRepository
from app.infrastructure.database.models.patient_case_model import (
    CaseStatusEnum, CaseUrgencyEnum, PatientCaseModel,
)


# ═══════════════════════════════════════════════════════════════
# Mappers
# ═══════════════════════════════════════════════════════════════
def _to_entity(m: PatientCaseModel) -> PatientCase:
    return PatientCase(
        id=m.id,
        patient_id=m.patient_id,
        doctor_id=m.doctor_id,
        symptoms=list(m.symptoms or []),
        suspected_condition=m.suspected_condition,
        image_urls=list(m.image_urls or []),
        location=m.location,
        pain_level=m.pain_level,
        swelling_level=m.swelling_level,
        diagnosis_confidence=m.diagnosis_confidence,
        alternate_conditions=list(m.alternate_conditions or []),
        urgency=CaseUrgency(m.urgency.value),
        red_flags=list(m.red_flags or []),
        completed_at=m.completed_at,
        verified_at=m.verified_at,
        verified_by_admin_id=m.verified_by_admin_id,
        verification_notes=m.verification_notes,
        status=CaseStatus(m.status.value),
        created_at=m.created_at,
        updated_at=m.updated_at,
    )


def _to_model(e: PatientCase) -> PatientCaseModel:
    return PatientCaseModel(
        id=e.id,
        patient_id=e.patient_id,
        doctor_id=e.doctor_id,
        symptoms=list(e.symptoms),
        suspected_condition=e.suspected_condition,
        image_urls=list(e.image_urls),
        location=e.location,
        pain_level=e.pain_level,
        swelling_level=e.swelling_level,
        diagnosis_confidence=e.diagnosis_confidence,
        alternate_conditions=list(e.alternate_conditions),
        urgency=CaseUrgencyEnum(e.urgency.value),
        red_flags=list(e.red_flags),
        completed_at=e.completed_at,
        verified_at=e.verified_at,
        verified_by_admin_id=e.verified_by_admin_id,
        verification_notes=e.verification_notes,
        status=CaseStatusEnum(e.status.value),
    )


# ═══════════════════════════════════════════════════════════════
# Repository
# ═══════════════════════════════════════════════════════════════
class CaseRepositoryImpl(CaseRepository):

    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, case_id: int) -> PatientCase | None:
        r = await self._session.execute(
            select(PatientCaseModel).where(PatientCaseModel.id == case_id)
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def get_by_id_for_update(self, case_id: int) -> PatientCase | None:
        """SELECT ... FOR UPDATE — prevents double-approval races."""
        r = await self._session.execute(
            select(PatientCaseModel)
            .where(PatientCaseModel.id == case_id)
            .with_for_update()
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def create(self, case: PatientCase) -> PatientCase:
        m = _to_model(case)
        m.id = None
        self._session.add(m)
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def update(self, case: PatientCase) -> PatientCase:
        if case.id is None:
            raise ValueError("Cannot update case without id")
        r = await self._session.execute(
            select(PatientCaseModel).where(PatientCaseModel.id == case.id)
        )
        m = r.scalar_one()
        m.symptoms = list(case.symptoms)
        m.suspected_condition = case.suspected_condition
        m.image_urls = list(case.image_urls)
        m.location = case.location
        m.pain_level = case.pain_level
        m.swelling_level = case.swelling_level
        m.diagnosis_confidence = case.diagnosis_confidence
        m.alternate_conditions = list(case.alternate_conditions)
        m.urgency = CaseUrgencyEnum(case.urgency.value)
        m.red_flags = list(case.red_flags)
        m.status = CaseStatusEnum(case.status.value)
        m.doctor_id = case.doctor_id
        m.completed_at = case.completed_at
        m.verified_at = case.verified_at
        m.verified_by_admin_id = case.verified_by_admin_id
        m.verification_notes = case.verification_notes
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def delete(self, case_id: int) -> None:
        r = await self._session.execute(
            select(PatientCaseModel).where(PatientCaseModel.id == case_id)
        )
        m = r.scalar_one_or_none()
        if m:
            await self._session.delete(m)

    async def count_pending_for_patient(self, patient_id: int) -> int:
        r = await self._session.execute(
            select(func.count(PatientCaseModel.id)).where(
                PatientCaseModel.patient_id == patient_id,
                PatientCaseModel.status == CaseStatusEnum.PENDING,
            )
        )
        return int(r.scalar() or 0)

    async def list_for_patient(self, patient_id, *, status=None, offset=0, limit=20):
        s = select(PatientCaseModel).where(PatientCaseModel.patient_id == patient_id)
        if status is not None:
            s = s.where(PatientCaseModel.status == CaseStatusEnum(status.value))
        s = s.order_by(PatientCaseModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def list_for_doctor(self, doctor_id, *, status=None, offset=0, limit=20):
        s = select(PatientCaseModel).where(PatientCaseModel.doctor_id == doctor_id)
        if status is not None:
            s = s.where(PatientCaseModel.status == CaseStatusEnum(status.value))
        s = s.order_by(PatientCaseModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def list_available(self, *, search=None, offset=0, limit=20):
        s = select(PatientCaseModel).where(
            PatientCaseModel.status == CaseStatusEnum.PENDING,
            PatientCaseModel.doctor_id.is_(None),
        )
        if search:
            like = f"%{search.strip()}%"
            s = s.where(or_(
                PatientCaseModel.suspected_condition.ilike(like),
                PatientCaseModel.location.ilike(like),
            ))
        s = s.order_by(PatientCaseModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def list_all(self, *, status=None, offset=0, limit=20):
        s = select(PatientCaseModel)
        if status is not None:
            s = s.where(PatientCaseModel.status == CaseStatusEnum(status.value))
        s = s.order_by(PatientCaseModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]
    async def list_for_admin(
        self, *, status=None, offset=0, limit=20,
    ):
        s = select(PatientCaseModel)
        if status is not None:
            s = s.where(PatientCaseModel.status == CaseStatusEnum(status.value))
        s = s.order_by(PatientCaseModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def count_by_status(self) -> dict[str, int]:
        r = await self._session.execute(
            select(PatientCaseModel.status, func.count(PatientCaseModel.id))
            .group_by(PatientCaseModel.status)
        )
        return {status.value: int(count) for status, count in r.all()}