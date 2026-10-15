"""
Admin service — user management, statistics, and case verification.
"""
import logging
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dtos.admin_dto import (
    AdminCaseResponse,
    AdminUserResponse,
)
from app.application.services.notification_service import NotificationService
from app.core.exceptions import (
    BadRequestException, ForbiddenException, NotFoundException,
)
from app.domain.entities.notification import NotificationType
from app.domain.entities.patient_case import CaseStatus
from app.domain.entities.user import User, UserRole
from app.infrastructure.repositories.appointment_repository_impl import (
    AppointmentRepositoryImpl,
)
from app.infrastructure.repositories.case_repository_impl import CaseRepositoryImpl
from app.infrastructure.repositories.order_repository_impl import OrderRepositoryImpl
from app.infrastructure.repositories.tool_repository_impl import ToolRepositoryImpl
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl

logger = logging.getLogger(__name__)


class AdminService:

    def __init__(self, session: AsyncSession):
        self._session = session
        self._users = UserRepositoryImpl(session)
        self._cases = CaseRepositoryImpl(session)
        self._appointments = AppointmentRepositoryImpl(session)
        self._orders = OrderRepositoryImpl(session)
        self._tools = ToolRepositoryImpl(session)
        self._notif = NotificationService(session)

    # ═══════════════════════════════════════════════════════
    # Users
    # ═══════════════════════════════════════════════════════
    async def list_users(
        self, *,
        role: UserRole | None, is_active: bool | None,
        search: str | None, offset: int, limit: int,
    ) -> list[User]:
        return await self._users.list_users(
            role=role, is_active=is_active, search=search,
            offset=offset, limit=limit,
        )

    async def toggle_user_active(
        self, admin: User, user_id: int, is_active: bool,
    ) -> User:
        if admin.id == user_id:
            raise BadRequestException("You cannot disable your own account.")

        user = await self._users.get_by_id(user_id)
        if user is None:
            raise NotFoundException("User not found.")

        if user.role == UserRole.ADMIN and not is_active:
            # Prevent disabling the last admin
            admins = await self._users.list_users(
                role=UserRole.ADMIN, is_active=True, search=None,
                offset=0, limit=100,
            )
            if len(admins) <= 1:
                raise BadRequestException(
                    "Cannot disable the last active admin account."
                )

        user.is_active = is_active
        updated = await self._users.update(user)

        # Notify the affected user
        status_text = "تم تفعيل حسابك" if is_active else "تم تعطيل حسابك"
        await self._notif.create(
            user_id=user.id,
            title=status_text,
            body=(
                "يمكنك الآن استخدام التطبيق بشكل طبيعي."
                if is_active
                else "يرجى التواصل مع الدعم لمزيد من المعلومات."
            ),
            type=NotificationType.SYSTEM,
            payload={"by_admin_id": admin.id, "is_active": is_active},
        )

        logger.info(
            "User %s set is_active=%s by admin=%s",
            user.id, is_active, admin.id,
        )
        return updated

    # ═══════════════════════════════════════════════════════
    # Case verification
    # ═══════════════════════════════════════════════════════
    async def verify_case(
        self, admin: User, case_id: int, approve: bool, notes: str | None,
    ) -> None:
        # Lock the row
        case = await self._cases.get_by_id_for_update(case_id)
        if case is None:
            raise NotFoundException("Case not found.")

        if case.status != CaseStatus.COMPLETED:
            raise BadRequestException(
                "Only completed cases can be verified or rejected."
            )

        notes_clean = (notes or "").strip() or None

        if approve:
            case.status = CaseStatus.VERIFIED
            case.verified_at = datetime.now(timezone.utc)
            case.verified_by_admin_id = admin.id
            case.verification_notes = notes_clean

            await self._notif.create(
                user_id=case.doctor_id,
                title="تمت المصادقة على علاجك",
                body=f"وافقت الإدارة على حالة '{case.suspected_condition}'.",
                type=NotificationType.CASE_VERIFIED,
                payload={
                    "case_id": case.id,
                    "admin_id": admin.id,
                    "condition": case.suspected_condition,  # ★
                },
            )
            await self._notif.create(
                user_id=case.patient_id,
                title="تم توثيق علاجك",
                body="تم توثيق إتمام علاجك بنجاح في النظام.",
                type=NotificationType.CASE_VERIFIED,
                payload={
                    "case_id": case.id,
                    "condition": case.suspected_condition,  # ★
                },
            )
            logger.info("Case %s verified by admin %s", case.id, admin.id)

        else:
            # Revert to booked so the doctor can correct and re-submit
            case.status = CaseStatus.BOOKED
            case.completed_at = None
            case.verification_notes = notes_clean

            await self._notif.create(
                user_id=case.doctor_id,
                title="تم رفض توثيق العلاج",
                body=(
                    f"رفضت الإدارة توثيق حالة '{case.suspected_condition}'. "
                    f"السبب: {notes_clean or 'غير محدد'}."
                ),
                type=NotificationType.CASE_REJECTED,
                payload={
                    "case_id": case.id,
                    "admin_id": admin.id,
                    "condition": case.suspected_condition,  # ★
                    "reason": notes_clean or "",  # ★
                },
            )
            logger.info(
                "Case %s rejected by admin %s — reason: %s",
                case.id, admin.id, notes_clean,
            )

        await self._cases.update(case)

    # ═══════════════════════════════════════════════════════
    # List cases for admin review
    # ═══════════════════════════════════════════════════════
    async def list_cases(
        self, *, status: CaseStatus | None, offset: int, limit: int,
    ) -> list[AdminCaseResponse]:
        cases = await self._cases.list_for_admin(
            status=status, offset=offset, limit=limit,
        )
        return await self._enrich_cases(cases)

    async def _enrich_cases(self, cases) -> list[AdminCaseResponse]:
        if not cases:
            return []

        # Batch fetch users
        user_ids: set[int] = set()
        for c in cases:
            user_ids.add(c.patient_id)
            if c.doctor_id:
                user_ids.add(c.doctor_id)
        users_map = await self._users.get_many_by_ids(user_ids)

        out: list[AdminCaseResponse] = []
        for c in cases:
            p = users_map.get(c.patient_id)
            d = users_map.get(c.doctor_id) if c.doctor_id else None
            out.append(
                AdminCaseResponse(
                    id=c.id,
                    patient_id=c.patient_id,
                    doctor_id=c.doctor_id,
                    symptoms=list(c.symptoms),
                    suspected_condition=c.suspected_condition,
                    image_urls=list(c.image_urls),
                    location=c.location,
                    pain_level=c.pain_level,
                    swelling_level=c.swelling_level,
                    diagnosis_confidence=c.diagnosis_confidence,
                    urgency=c.urgency,
                    red_flags=list(c.red_flags),
                    status=c.status,
                    completed_at=c.completed_at,
                    verified_at=c.verified_at,
                    verification_notes=c.verification_notes,
                    patient_name=p.full_name if p else None,
                    patient_phone=p.phone if p else None,
                    doctor_name=d.full_name if d else None,
                    doctor_university_id=d.university_id if d else None,
                    created_at=c.created_at,
                )
            )
        return out

    # ═══════════════════════════════════════════════════════
    # Statistics
    # ═══════════════════════════════════════════════════════
    async def get_stats(self) -> dict:
        users = await self._users.count_by_role()
        cases = await self._cases.count_by_status()

        # Appointments by status
        from sqlalchemy import func, select
        from app.infrastructure.database.models.appointment_model import (
            AppointmentModel,
        )
        from app.infrastructure.database.models.order_model import OrderModel
        from app.infrastructure.database.models.tool_model import ToolModel

        appts_r = await self._session.execute(
            select(AppointmentModel.status, func.count(AppointmentModel.id))
            .group_by(AppointmentModel.status)
        )
        appointments = {s.value: int(c) for s, c in appts_r.all()}

        orders_r = await self._session.execute(
            select(OrderModel.status, func.count(OrderModel.id))
            .group_by(OrderModel.status)
        )
        orders = {s.value: int(c) for s, c in orders_r.all()}

        tools_r = await self._session.execute(
            select(ToolModel.status, func.count(ToolModel.id))
            .group_by(ToolModel.status)
        )
        tools = {s.value: int(c) for s, c in tools_r.all()}

        pending_verifications = cases.get("completed", 0)

        return {
            "users": users,
            "cases": cases,
            "appointments": appointments,
            "orders": orders,
            "tools": tools,
            "pending_verifications": pending_verifications,
        }