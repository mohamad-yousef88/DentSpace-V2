"""
Appointment service — full lifecycle.

Race-safe:
  • approve() and reject() acquire row-level locks via SELECT ... FOR UPDATE
    on both the appointment and (for approve) the case.
  • This prevents two patients/doctors from double-approving the same
    case, or double-approving the same appointment.
"""
import logging
from datetime import datetime, timezone

from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dtos.appointment_dto import (
    AppointmentCaseBrief, AppointmentResponse, AppointmentUserBrief,
)
from app.application.services.notification_service import NotificationService
from app.core.exceptions import (
    BadRequestException, ConflictException, ForbiddenException, NotFoundException,
)
from app.domain.entities.appointment import Appointment, AppointmentStatus
from app.domain.entities.notification import NotificationType
from app.domain.entities.patient_case import CaseStatus
from app.domain.entities.user import User, UserRole
from app.infrastructure.repositories.appointment_repository_impl import (
    AppointmentRepositoryImpl,
)
from app.infrastructure.repositories.case_repository_impl import CaseRepositoryImpl
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl

logger = logging.getLogger(__name__)

ACTIVE_LIMIT = 3


class AppointmentService:

    def __init__(self, session: AsyncSession):
        self._session = session
        self._repo = AppointmentRepositoryImpl(session)
        self._cases = CaseRepositoryImpl(session)
        self._users = UserRepositoryImpl(session)
        self._notif = NotificationService(session)

    # ═══════════════════════════════════════════════════════
    # Create
    # ═══════════════════════════════════════════════════════
    async def create_appointment(
        self, requester: User, case_id: int,
    ) -> Appointment:
        if requester.role != UserRole.DOCTOR:
            raise ForbiddenException("Only doctors can create appointments.")

        case = await self._cases.get_by_id(case_id)
        if case is None:
            raise NotFoundException("Case not found.")

        if not case.is_pending or case.doctor_id is not None:
            raise BadRequestException("This case is no longer available.")

        existing = await self._repo.find_pending_by_doctor_and_case(
            requester.id, case_id,
        )
        if existing is not None:
            raise ConflictException(
                "You already have a pending request for this case."
            )

        doctor_active = await self._repo.count_active_for_doctor(requester.id)
        if doctor_active >= ACTIVE_LIMIT:
            raise BadRequestException(
                f"You cannot have more than {ACTIVE_LIMIT} active appointments."
            )

        patient_active = await self._repo.count_active_for_patient(case.patient_id)
        if patient_active >= ACTIVE_LIMIT:
            raise BadRequestException(
                f"This patient already has {ACTIVE_LIMIT} active appointments."
            )

        appt = Appointment(
            case_id=case_id,
            patient_id=case.patient_id,
            doctor_id=requester.id,
            status=AppointmentStatus.PENDING,
        )
        created = await self._repo.create(appt)

        await self._notif.create(
            user_id=case.patient_id,
            title="طلب حجز جديد",
            body=f"الطبيب {requester.full_name} أرسل طلباً لحالة '{case.suspected_condition}'.",
            type=NotificationType.APPOINTMENT_REQUEST,
            payload={
                "appointment_id": created.id,
                "case_id": case_id,
                "doctor_id": requester.id,
                "doctor_name": requester.full_name,  # ★
                "condition": case.suspected_condition,  # ★
            },
        )
        logger.info(
            "Appointment created: id=%s doctor=%s case=%s",
            created.id, requester.id, case_id,
        )
        return created

    # ═══════════════════════════════════════════════════════
    # Patient actions
    # ═══════════════════════════════════════════════════════
    async def approve(self, requester: User, appointment_id: int) -> Appointment:
        if requester.role != UserRole.PATIENT:
            raise ForbiddenException("Only patients can approve appointments.")

        # ★ Row lock on appointment
        appt = await self._repo.get_by_id_for_update(appointment_id)
        if appt is None:
            raise NotFoundException("Appointment not found.")
        if appt.patient_id != requester.id:
            raise ForbiddenException("This appointment is not yours.")
        if not appt.is_pending:
            raise BadRequestException("Only pending appointments can be approved.")

        # ★ Row lock on case — prevents two simultaneous approvals
        case = await self._cases.get_by_id_for_update(appt.case_id)
        if case is None:
            raise NotFoundException("Case not found.")
        if not case.is_pending or case.doctor_id is not None:
            raise BadRequestException("This case is no longer available.")

        patient_active = await self._repo.count_active_for_patient(requester.id)
        if patient_active >= ACTIVE_LIMIT:
            raise BadRequestException(
                f"You cannot have more than {ACTIVE_LIMIT} active appointments."
            )
        doctor_active = await self._repo.count_active_for_doctor(appt.doctor_id)
        if doctor_active >= ACTIVE_LIMIT:
            raise BadRequestException(
                "The doctor has already reached the active-appointment limit."
            )

        # 1) Approve
        appt.status = AppointmentStatus.APPROVED
        appt.responded_at = datetime.now(timezone.utc)
        updated = await self._repo.update(appt)

        # 2) Lock the case
        case.status = CaseStatus.BOOKED
        case.doctor_id = appt.doctor_id
        await self._cases.update(case)

        # 3) Auto-reject other pending requests on the same case
        others = await self._repo.list_pending_for_case(appt.case_id)
        for other in others:
            if other.id == appt.id:
                continue
            other.status = AppointmentStatus.REJECTED
            other.responded_at = datetime.now(timezone.utc)
            other.rejection_reason = "تمت الموافقة على طبيب آخر لنفس الحالة."
            await self._repo.update(other)
            await self._notif.create(
                user_id=other.doctor_id,
                title="تم رفض طلب الحجز",
                body=f"تمت الموافقة على طبيب آخر لحالة '{case.suspected_condition}'.",
                type=NotificationType.APPOINTMENT_REJECTED,
                payload={
                    "appointment_id": other.id,
                    "case_id": case.id,
                    "condition": case.suspected_condition,  # ★
                },
            )

        # 4) Notify the winning doctor
        await self._notif.create(
            user_id=appt.doctor_id,
            title="تمت الموافقة على طلب الحجز",
            body=f"وافق المريض {requester.full_name} على طلبك لحالة '{case.suspected_condition}'.",
            type=NotificationType.APPOINTMENT_APPROVED,
            payload={
                "appointment_id": appt.id,
                "case_id": case.id,
                "patient_name": requester.full_name,  # ★
                "condition": case.suspected_condition,  # ★
            },
        )
        logger.info("Appointment approved: id=%s", appt.id)
        return updated

    async def reject(self, requester: User, appointment_id: int) -> Appointment:
        if requester.role != UserRole.PATIENT:
            raise ForbiddenException("Only patients can reject appointments.")

        # ★ Row lock
        appt = await self._repo.get_by_id_for_update(appointment_id)
        if appt is None:
            raise NotFoundException("Appointment not found.")
        if appt.patient_id != requester.id:
            raise ForbiddenException("This appointment is not yours.")
        if not appt.is_pending:
            raise BadRequestException("Only pending appointments can be rejected.")

        appt.status = AppointmentStatus.REJECTED
        appt.responded_at = datetime.now(timezone.utc)
        updated = await self._repo.update(appt)

        await self._notif.create(
            user_id=appt.doctor_id,
            title="تم رفض طلب الحجز",
            body=f"رفض المريض {requester.full_name} طلب الحجز.",
            type=NotificationType.APPOINTMENT_REJECTED,
            payload={
                "appointment_id": appt.id,
                "case_id": appt.case_id,
                "patient_name": requester.full_name,  # ★
            },
        )

        logger.info("Appointment rejected: id=%s", appt.id)
        return updated

    # ═══════════════════════════════════════════════════════
    # Cancel (either party)
    # ═══════════════════════════════════════════════════════
    async def cancel(self, requester: User, appointment_id: int) -> None:
        appt = await self._repo.get_by_id_for_update(appointment_id)
        if appt is None:
            raise NotFoundException("Appointment not found.")

        is_doctor = requester.id == appt.doctor_id
        is_patient = requester.id == appt.patient_id
        if not (is_doctor or is_patient):
            raise ForbiddenException("You cannot cancel this appointment.")

        if appt.status not in (AppointmentStatus.PENDING, AppointmentStatus.APPROVED):
            raise BadRequestException(
                "Only pending or approved appointments can be cancelled."
            )

        was_approved = appt.is_approved
        appt.status = AppointmentStatus.CANCELLED
        appt.responded_at = datetime.now(timezone.utc)
        await self._repo.update(appt)

        if was_approved:
            case = await self._cases.get_by_id_for_update(appt.case_id)
            if case is not None and case.doctor_id == appt.doctor_id:
                case.status = CaseStatus.PENDING
                case.doctor_id = None
                await self._cases.update(case)

        other_id = appt.doctor_id if is_patient else appt.patient_id
        canceller = "المريض" if is_patient else "الطبيب"
        await self._notif.create(
            user_id=other_id,
            title="تم إلغاء طلب الحجز",
            body=f"قام {canceller} بإلغاء طلب الحجز.",
            type=NotificationType.APPOINTMENT_CANCELLED,
            payload={
                "appointment_id": appt.id,
                "case_id": appt.case_id,
                "canceller": "patient" if is_patient else "doctor",  # ★
            },
        )

        logger.info("Appointment cancelled: id=%s by=%s", appt.id, canceller)
    # ═══════════════════════════════════════════════════════
    # Complete treatment (doctor marks case as done)
    # ═══════════════════════════════════════════════════════
    async def complete(
        self, requester: User, appointment_id: int,
    ) -> Appointment:
        """
        Doctor marks the treatment as done.

        Side effects:
          • appointment.status → COMPLETED
          • case.status        → COMPLETED + completed_at
          • patient notified   → CASE_COMPLETED
        """
        if requester.role != UserRole.DOCTOR:
            raise ForbiddenException("Only doctors can complete appointments.")

        # Lock appointment
        appt = await self._repo.get_by_id_for_update(appointment_id)
        if appt is None:
            raise NotFoundException("Appointment not found.")
        if appt.doctor_id != requester.id:
            raise ForbiddenException("You are not the doctor for this appointment.")
        if not appt.is_approved:
            raise BadRequestException(
                "Only approved appointments can be completed."
            )

        # Lock case
        case = await self._cases.get_by_id_for_update(appt.case_id)
        if case is None:
            raise NotFoundException("Case not found.")
        if case.doctor_id != requester.id:
            raise ForbiddenException("You are not the assigned doctor for this case.")
        if case.status != CaseStatus.BOOKED:
            raise BadRequestException(
                "Only booked cases can be marked as completed."
            )

        now = datetime.now(timezone.utc)

        # 1) appointment → completed
        appt.status = AppointmentStatus.COMPLETED
        appt.responded_at = now
        updated = await self._repo.update(appt)

        # 2) case → completed
        case.status = CaseStatus.COMPLETED
        case.completed_at = now
        await self._cases.update(case)

        await self._notif.create(
            user_id=appt.patient_id,
            title="انتهى العلاج",
            body=(
                f"أعلن الطبيب انتهاء علاج حالتك "
                f"'{case.suspected_condition}'. "
                f"بانتظار مصادقة الإدارة."
            ),
            type=NotificationType.CASE_COMPLETED,
            payload={
                "appointment_id": appt.id,
                "case_id": case.id,
                "condition": case.suspected_condition,  # ★
            },
        )

        logger.info("Appointment completed: id=%s", appt.id)
        return updated

    # ═══════════════════════════════════════════════════════
    # List & enrich
    # ═══════════════════════════════════════════════════════
    async def list_appointments(
        self, requester: User, *,
        mine: bool, status: AppointmentStatus | None,
        offset: int, limit: int,
    ):
        if requester.role == UserRole.PATIENT:
            return await self._repo.list_for_patient(
                requester.id, status=status, offset=offset, limit=limit,
            )
        if requester.role == UserRole.ADMIN:
            return await self._repo.list_all(
                status=status, offset=offset, limit=limit,
            )
        return await self._repo.list_for_doctor(
            requester.id, status=status, offset=offset, limit=limit,
        )

    async def get_appointment(self, requester: User, appointment_id: int) -> Appointment:
        appt = await self._repo.get_by_id(appointment_id)
        if appt is None:
            raise NotFoundException("Appointment not found.")
        if requester.role == UserRole.ADMIN:
            return appt
        if requester.id not in (appt.doctor_id, appt.patient_id):
            raise ForbiddenException("You cannot view this appointment.")
        return appt

    async def enrich(self, appointments: list[Appointment]) -> list[AppointmentResponse]:
        """Attach case brief + user briefs. Uses batch user fetch to avoid N+1."""
        if not appointments:
            return []

        # ★ Batch fetch all users
        user_ids: set[int] = set()
        case_ids: set[int] = set()
        for a in appointments:
            user_ids.add(a.patient_id)
            user_ids.add(a.doctor_id)
            case_ids.add(a.case_id)

        users_map = await self._users.get_many_by_ids(user_ids)
        cases_map: dict[int, object] = {}
        for cid in case_ids:
            c = await self._cases.get_by_id(cid)
            if c is not None:
                cases_map[cid] = c

        out: list[AppointmentResponse] = []
        for a in appointments:
            case = cases_map.get(a.case_id)
            buyer_u = users_map.get(a.patient_id)
            doctor_u = users_map.get(a.doctor_id)
            out.append(
                AppointmentResponse(
                    id=a.id,
                    status=a.status,
                    responded_at=a.responded_at,
                    created_at=a.created_at,
                    case=AppointmentCaseBrief(
                        id=case.id,
                        suspected_condition=case.suspected_condition,
                        location=case.location,
                        urgency=case.urgency,
                        status=case.status,
                        image_urls=list(case.image_urls),
                    ) if case else None,
                    patient=AppointmentUserBrief(
                        id=buyer_u.id,
                        full_name=buyer_u.full_name,
                        phone=buyer_u.phone,
                    ) if buyer_u else None,
                    doctor=AppointmentUserBrief(
                        id=doctor_u.id,
                        full_name=doctor_u.full_name,
                        phone=doctor_u.phone,
                    ) if doctor_u else None,
                )
            )
        return out

    async def get_doctor_stats(self, requester: User) -> dict[str, int]:
        """Dashboard counters for the current doctor."""
        if requester.role != UserRole.DOCTOR:
            raise ForbiddenException("Only doctors can access this endpoint.")
        return await self._repo.count_doctor_dashboard(requester.id)
