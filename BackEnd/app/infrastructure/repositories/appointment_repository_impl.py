"""Appointment repository implementation."""
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.appointment import Appointment, AppointmentStatus
from app.domain.repositories.appointment_repository import AppointmentRepository
from app.infrastructure.database.models.appointment_model import (
    AppointmentModel, AppointmentStatusEnum,
)
from app.infrastructure.database.models.patient_case_model import CaseStatusEnum


def _to_entity(m: AppointmentModel) -> Appointment:
    return Appointment(
        id=m.id,
        case_id=m.case_id,
        patient_id=m.patient_id,
        doctor_id=m.doctor_id,
        status=AppointmentStatus(m.status.value),
        responded_at=m.responded_at,
        rejection_reason=getattr(m, "rejection_reason", None),
        created_at=m.created_at,
        updated_at=m.updated_at,
    )


def _to_enum(s: AppointmentStatus) -> AppointmentStatusEnum:
    return AppointmentStatusEnum(s.value)


class AppointmentRepositoryImpl(AppointmentRepository):

    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, appointment_id: int) -> Appointment | None:
        r = await self._session.execute(
            select(AppointmentModel).where(AppointmentModel.id == appointment_id)
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def get_by_id_for_update(self, appointment_id: int) -> Appointment | None:
        r = await self._session.execute(
            select(AppointmentModel)
            .where(AppointmentModel.id == appointment_id)
            .with_for_update()
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def create(self, a: Appointment) -> Appointment:
        m = AppointmentModel(
            case_id=a.case_id,
            patient_id=a.patient_id,
            doctor_id=a.doctor_id,
            status=_to_enum(a.status),
        )
        self._session.add(m)
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def update(self, a: Appointment) -> Appointment:
        if a.id is None:
            raise ValueError("Cannot update appointment without id")
        r = await self._session.execute(
            select(AppointmentModel).where(AppointmentModel.id == a.id)
        )
        m = r.scalar_one()
        m.status = _to_enum(a.status)
        m.responded_at = a.responded_at
        if hasattr(m, "rejection_reason"):
            m.rejection_reason = a.rejection_reason
        await self._session.flush()
        await self._session.refresh(m)
        return _to_entity(m)

    async def delete(self, appointment_id: int) -> None:
        r = await self._session.execute(
            select(AppointmentModel).where(AppointmentModel.id == appointment_id)
        )
        m = r.scalar_one_or_none()
        if m:
            await self._session.delete(m)

    async def find_pending_by_doctor_and_case(
        self, doctor_id: int, case_id: int,
    ) -> Appointment | None:
        r = await self._session.execute(
            select(AppointmentModel).where(
                AppointmentModel.doctor_id == doctor_id,
                AppointmentModel.case_id == case_id,
                AppointmentModel.status == AppointmentStatusEnum.PENDING,
            ).limit(1)
        )
        m = r.scalar_one_or_none()
        return _to_entity(m) if m else None

    async def list_pending_for_case(self, case_id: int) -> list[Appointment]:
        r = await self._session.execute(
            select(AppointmentModel).where(
                AppointmentModel.case_id == case_id,
                AppointmentModel.status == AppointmentStatusEnum.PENDING,
            )
        )
        return [_to_entity(m) for m in r.scalars().all()]

    async def count_active_for_doctor(self, doctor_id: int) -> int:
        r = await self._session.execute(
            select(func.count(AppointmentModel.id)).where(
                AppointmentModel.doctor_id == doctor_id,
                AppointmentModel.status.in_([
                    AppointmentStatusEnum.PENDING,
                    AppointmentStatusEnum.APPROVED,
                ]),
            )
        )
        return int(r.scalar() or 0)

    async def count_active_for_patient(self, patient_id: int) -> int:
        r = await self._session.execute(
            select(func.count(AppointmentModel.id)).where(
                AppointmentModel.patient_id == patient_id,
                AppointmentModel.status.in_([
                    AppointmentStatusEnum.PENDING,
                    AppointmentStatusEnum.APPROVED,
                ]),
            )
        )
        return int(r.scalar() or 0)

    async def list_for_patient(self, patient_id, *, status=None, offset=0, limit=20):
        s = select(AppointmentModel).where(AppointmentModel.patient_id == patient_id)
        if status:
            s = s.where(AppointmentModel.status == _to_enum(status))
        s = s.order_by(AppointmentModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def list_for_doctor(self, doctor_id, *, status=None, offset=0, limit=20):
        s = select(AppointmentModel).where(AppointmentModel.doctor_id == doctor_id)
        if status:
            s = s.where(AppointmentModel.status == _to_enum(status))
        s = s.order_by(AppointmentModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def list_all(self, *, status=None, offset=0, limit=20):
        s = select(AppointmentModel)
        if status:
            s = s.where(AppointmentModel.status == _to_enum(status))
        s = s.order_by(AppointmentModel.created_at.desc()).offset(offset).limit(limit)
        r = await self._session.execute(s)
        return [_to_entity(m) for m in r.scalars().all()]

    async def count_doctor_dashboard(self, doctor_id: int) -> dict[str, int]:
        """
        Single-round-trip aggregation for the doctor dashboard.

        Uses SQLAlchemy `filter()` aggregation on a joined query.
        """
        from sqlalchemy import and_, func, or_, select

        from app.infrastructure.database.models.patient_case_model import (
            CaseStatusEnum, PatientCaseModel,
        )

        active_expr = func.count().filter(
            AppointmentModel.status == AppointmentStatusEnum.PENDING,
        ).label("active_requests")

        ongoing_expr = func.count().filter(
            or_(
                AppointmentModel.status == AppointmentStatusEnum.APPROVED,
                and_(
                    AppointmentModel.status == AppointmentStatusEnum.COMPLETED,
                    PatientCaseModel.status != CaseStatusEnum.VERIFIED,
                ),
            ),
        ).label("ongoing_bookings")

        verified_expr = func.count().filter(
            PatientCaseModel.status == CaseStatusEnum.VERIFIED,
        ).label("verified_cases")

        stmt = (
            select(active_expr, ongoing_expr, verified_expr)
            .select_from(AppointmentModel)
            .join(
                PatientCaseModel,
                PatientCaseModel.id == AppointmentModel.case_id,
            )
            .where(AppointmentModel.doctor_id == doctor_id)
        )
        row = (await self._session.execute(stmt)).one()
        return {
            "active_requests": int(row.active_requests or 0),
            "ongoing_bookings": int(row.ongoing_bookings or 0),
            "verified_cases": int(row.verified_cases or 0),
        }