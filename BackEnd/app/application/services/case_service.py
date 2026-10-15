"""
PatientCase service — business logic for the entire case lifecycle.
"""
import asyncio
import logging
import uuid
from datetime import datetime, timezone

from app.domain.entities.notification import NotificationType
from app.application.services.notification_service import NotificationService
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.dtos.case_dto import (
    CaseResponse,
    CreateCaseRequest,
    DiagnosisMatchDTO,
    DiagnosisPreviewResponse,
    PreviewDiagnosisRequest,
    UpdateCaseRequest,
)
from app.core.exceptions import (
    BadRequestException, ForbiddenException, NotFoundException,
)
from app.domain.entities.patient_case import (
    CaseStatus, CaseUrgency, PatientCase,
)
from app.domain.entities.user import User, UserRole
from app.domain.services.symptom_analyzer import (
    SEVERITY_TO_LEVEL, DiagnosisResult, analyze_symptoms,
)
from app.infrastructure.external.cloudinary_client import (
    CloudinaryError, cloudinary_client, extract_public_id,
)
from app.infrastructure.repositories.case_repository_impl import CaseRepositoryImpl
from app.infrastructure.repositories.user_repository_impl import UserRepositoryImpl

logger = logging.getLogger(__name__)

CASE_FOLDER = "dentspace/cases"
MAX_PENDING_CASES_PER_PATIENT = 3
MAX_IMAGES_PER_CASE = 5


class CaseService:

    def __init__(self, session: AsyncSession):
        self._session = session
        self._cases = CaseRepositoryImpl(session)
        self._users = UserRepositoryImpl(session)
        self._notif = NotificationService(session)

    # ═══════════════════════════════════════════════════════
    # Diagnosis preview
    # ═══════════════════════════════════════════════════════
    def _run_analyzer(
        self, requester: User, data: PreviewDiagnosisRequest,
    ) -> DiagnosisResult:
        return analyze_symptoms(
            selected_symptoms=data.symptoms,
            pain_severity=data.pain_severity if data.has_pain else None,
            swelling_severity=data.swelling_severity if data.has_swelling else None,
            age=requester.age,
            location=data.location,
        )

    def preview_diagnosis(
        self, requester: User, data: PreviewDiagnosisRequest,
    ) -> DiagnosisPreviewResponse:
        try:
            result = self._run_analyzer(requester, data)
        except ValueError as exc:
            raise BadRequestException(str(exc))

        def to_dto(m) -> DiagnosisMatchDTO:
            return DiagnosisMatchDTO(
                key=m.key,
                name_ar=m.name_ar,
                confidence=m.confidence,
                confidence_pct=m.confidence_pct,
                category=m.category.value,
                urgency=m.urgency.value,
                notes_ar=m.notes_ar,
                recommendation_ar=m.recommendation_ar,
            )

        return DiagnosisPreviewResponse(
            primary=to_dto(result.primary),
            alternatives=[to_dto(a) for a in result.alternatives],
            urgency=result.urgency.value,
            red_flags=result.red_flags,
            warnings=result.warnings,
            emergency_instructions=result.emergency_instructions,
        )

    # ═══════════════════════════════════════════════════════
    # Create
    # ═══════════════════════════════════════════════════════
    async def create_case(
        self, requester: User, data: CreateCaseRequest,
    ) -> PatientCase:
        if requester.role != UserRole.PATIENT:
            raise ForbiddenException("Only patients can create cases.")

        pending = await self._cases.count_pending_for_patient(requester.id)
        if pending >= MAX_PENDING_CASES_PER_PATIENT:
            raise BadRequestException(
                f"You cannot have more than {MAX_PENDING_CASES_PER_PATIENT} "
                f"pending cases at the same time."
            )

        # Run the analyzer (unless the client explicitly overrode condition)
        try:
            diagnosis = self._run_analyzer(requester, data)
        except ValueError as exc:
            raise BadRequestException(str(exc))

        condition = data.suspected_condition.strip() if data.suspected_condition \
            else diagnosis.primary.name_ar

        pain_level = (
            SEVERITY_TO_LEVEL.get(data.pain_severity or "", 0.0)
            if data.has_pain else 0.0
        )
        swelling_level = (
            SEVERITY_TO_LEVEL.get(data.swelling_severity or "", 0.0)
            if data.has_swelling else 0.0
        )

        case = PatientCase(
            patient_id=requester.id,
            symptoms=list(data.symptoms),
            suspected_condition=condition,
            location=data.location.strip(),
            pain_level=pain_level,
            swelling_level=swelling_level,
            diagnosis_confidence=diagnosis.primary.confidence,
            alternate_conditions=[a.name_ar for a in diagnosis.alternatives],
            urgency=CaseUrgency(diagnosis.urgency.value),
            red_flags=list(diagnosis.red_flags),
            status=CaseStatus.PENDING,
            image_urls=[],
        )
        created = await self._cases.create(case)
        logger.info(
            "Case created: id=%s patient=%s urgency=%s",
            created.id, requester.id, created.urgency.value,
        )
        return created

    # ═══════════════════════════════════════════════════════
    # Read
    # ═══════════════════════════════════════════════════════
    async def get_case(self, requester: User, case_id: int) -> PatientCase:
        case = await self._cases.get_by_id(case_id)
        if case is None:
            raise NotFoundException("Case not found.")
        if requester.role == UserRole.PATIENT and case.patient_id != requester.id:
            raise ForbiddenException("You cannot view another patient's case.")
        return case
    async def list_cases(
        self,
        requester: User,
        *,
        mine: bool,
        status: CaseStatus | None,
        search: str | None,
        offset: int,
        limit: int,
    ) -> list[PatientCase]:
        """
        Role-aware case listing.

        Routing rules for DOCTORS
        -------------------------
        A doctor has two conceptually distinct lists:

            (A) "Available"  — pending cases from any patient, not yet
                               booked by any doctor. This is the
                               browse-and-book list.

            (B) "My cases"   — cases where doctor_id == me, at any
                               stage (booked / completed / verified).

        Priority (first match wins):

            1. mine=True                       → (B) with the given filter
            2. status is None or PENDING       → (A) available cases
            3. status in {BOOKED, COMPLETED,
                          VERIFIED}             → (B) with the given filter
                                                     (a doctor can only see
                                                      their own non-pending
                                                      cases, for privacy)

        Admins see everything. Patients see only their own cases.
        """
        # ── Patients ───────────────────────────────────────
        if requester.role == UserRole.PATIENT:
            return await self._cases.list_for_patient(
                requester.id, status=status, offset=offset, limit=limit,
            )

        # ── Admins ─────────────────────────────────────────
        if requester.role == UserRole.ADMIN:
            return await self._cases.list_all(
                status=status, offset=offset, limit=limit,
            )

        # ── Doctors ────────────────────────────────────────
        # Rule 1: explicit "my cases" flag
        if mine:
            return await self._cases.list_for_doctor(
                requester.id, status=status, offset=offset, limit=limit,
            )

        # Rule 2: no status, or specifically PENDING → available
        if status is None or status == CaseStatus.PENDING:
            return await self._cases.list_available(
                search=search, offset=offset, limit=limit,
            )

        # Rule 3: any non-pending status → the doctor's own cases
        # (privacy: a doctor must not see another doctor's booked cases)
        return await self._cases.list_for_doctor(
            requester.id, status=status, offset=offset, limit=limit,
        )
    # ═══════════════════════════════════════════════════════
    # Update
    # ═══════════════════════════════════════════════════════
    async def update_case(
        self, requester: User, case_id: int, data: UpdateCaseRequest,
    ) -> PatientCase:
        case = await self._cases.get_by_id(case_id)
        if case is None:
            raise NotFoundException("Case not found.")
        if requester.role != UserRole.PATIENT or case.patient_id != requester.id:
            raise ForbiddenException("You can only edit your own cases.")
        if not case.is_pending:
            raise BadRequestException(
                "Only pending cases can be edited. Booked or completed "
                "cases are locked."
            )

        if data.symptoms is not None:
            case.symptoms = list(data.symptoms)
        if data.location is not None:
            case.location = data.location.strip()
        if data.has_pain is not None:
            case.pain_level = (
                SEVERITY_TO_LEVEL.get(data.pain_severity or "", 0.0)
                if data.has_pain else 0.0
            )
        if data.has_swelling is not None:
            case.swelling_level = (
                SEVERITY_TO_LEVEL.get(data.swelling_severity or "", 0.0)
                if data.has_swelling else 0.0
            )
        if data.suspected_condition is not None:
            case.suspected_condition = data.suspected_condition.strip()

        # Re-run the analyzer on updated symptoms
        try:
            dx = analyze_symptoms(
                selected_symptoms=case.symptoms,
                pain_severity=None,
                swelling_severity=None,
                age=requester.age,
                location=case.location,
            )
            case.diagnosis_confidence = dx.primary.confidence
            case.alternate_conditions = [a.name_ar for a in dx.alternatives]
            case.urgency = CaseUrgency(dx.urgency.value)
            case.red_flags = list(dx.red_flags)
            if data.suspected_condition is None:
                case.suspected_condition = dx.primary.name_ar
        except ValueError:
            pass

        return await self._cases.update(case)

    # ═══════════════════════════════════════════════════════
    # Delete
    # ═══════════════════════════════════════════════════════
    async def delete_case(self, requester: User, case_id: int) -> None:
        case = await self._cases.get_by_id(case_id)
        if case is None:
            raise NotFoundException("Case not found.")
        if requester.role != UserRole.PATIENT or case.patient_id != requester.id:
            raise ForbiddenException("You can only delete your own cases.")
        if not case.is_pending:
            raise BadRequestException(
                "Only pending cases can be deleted. Booked or completed "
                "cases are locked."
            )

        for url in case.image_urls:
            pid = extract_public_id(url)
            if pid:
                cloudinary_client.delete_image(pid)

        await self._cases.delete(case_id)
        logger.info("Case deleted: id=%s (images cleaned)", case_id)

    # ═══════════════════════════════════════════════════════
    # Images
    # ═══════════════════════════════════════════════════════
    async def add_image(
        self, requester: User, case_id: int,
        file, content_type: str | None, file_size: int | None,
    ) -> PatientCase:
        case = await self._cases.get_by_id(case_id)
        if case is None:
            raise NotFoundException("Case not found.")
        if requester.role != UserRole.PATIENT or case.patient_id != requester.id:
            raise ForbiddenException("You can only modify your own cases.")
        if not case.is_pending:
            raise BadRequestException("Only pending cases can be modified.")
        if len(case.image_urls) >= MAX_IMAGES_PER_CASE:
            raise BadRequestException(
                f"A case cannot have more than {MAX_IMAGES_PER_CASE} images."
            )
        if content_type not in {"image/jpeg", "image/jpg", "image/png", "image/webp"}:
            raise BadRequestException("Only JPEG, PNG, or WEBP images are allowed.")
        if file_size is not None and file_size > 5 * 1024 * 1024:
            raise BadRequestException("Image too large. Max size is 5 MB.")

        folder = f"{CASE_FOLDER}/{requester.id}"
        public_id = f"case_{case_id}_{uuid.uuid4().hex[:8]}"

        try:
            result = await asyncio.to_thread(
                cloudinary_client.upload_image, file, folder, public_id,
            )
        except CloudinaryError as exc:
            raise BadRequestException(str(exc))

        case.image_urls = [*case.image_urls, result.url]
        return await self._cases.update(case)

    async def delete_image(
        self, requester: User, case_id: int, index: int,
    ) -> PatientCase:
        case = await self._cases.get_by_id(case_id)
        if case is None:
            raise NotFoundException("Case not found.")
        if requester.role != UserRole.PATIENT or case.patient_id != requester.id:
            raise ForbiddenException("You can only modify your own cases.")
        if not case.is_pending:
            raise BadRequestException("Only pending cases can be modified.")
        if index < 0 or index >= len(case.image_urls):
            raise BadRequestException("Image index out of range.")

        url = case.image_urls[index]
        pid = extract_public_id(url)
        if pid:
            cloudinary_client.delete_image(pid)

        remaining = list(case.image_urls)
        remaining.pop(index)
        case.image_urls = remaining
        return await self._cases.update(case)

    # ═══════════════════════════════════════════════════════
    # Enrichment for viewer
    # ═══════════════════════════════════════════════════════
    async def enrich_for_viewer(
        self, requester: User, cases: list[PatientCase],
    ) -> list[CaseResponse]:
        show_patient_info = requester.role in (UserRole.DOCTOR, UserRole.ADMIN)

        patients: dict[int, User] = {}
        if show_patient_info and cases:
            for pid in {c.patient_id for c in cases}:
                u = await self._users.get_by_id(pid)
                if u is not None:
                    patients[pid] = u

        out: list[CaseResponse] = []
        for c in cases:
            resp = CaseResponse.model_validate(c.__dict__)
            if show_patient_info:
                p = patients.get(c.patient_id)
                if p:
                    resp.patient_name = p.full_name
                    resp.patient_phone = p.phone
            out.append(resp)
        return out
    # ═══════════════════════════════════════════════════════
    # Doctor completes treatment
    # ═══════════════════════════════════════════════════════
    async def complete_treatment(
        self, requester: User, case_id: int, notes: str | None,
    ) -> PatientCase:
        """
        Doctor marks treatment as done.

        Transitions: booked → completed.
        Requires the caller to be the assigned doctor (or an admin).
        """
        # Lock the row to prevent concurrent completion
        case = await self._cases.get_by_id_for_update(case_id)
        if case is None:
            raise NotFoundException("Case not found.")

        if requester.role == UserRole.DOCTOR and case.doctor_id != requester.id:
            raise ForbiddenException("You are not the doctor for this case.")
        if requester.role not in (UserRole.DOCTOR, UserRole.ADMIN):
            raise ForbiddenException("Only the assigned doctor can complete.")

        if case.status not in (CaseStatus.BOOKED,):
            raise BadRequestException(
                "Only booked cases can be marked as completed."
            )

        case.status = CaseStatus.COMPLETED
        case.completed_at = datetime.now(timezone.utc)
        case.verification_notes = (notes or "").strip() or None
        updated = await self._cases.update(case)

        # Notify patient + admin pool (via SYSTEM notification)
        await self._notif.create(
            user_id=case.patient_id,
            title="انتهى العلاج",
            body=f"أعلن الطبيب انتهاء علاج حالتك '{case.suspected_condition}'.",
            type=NotificationType.CASE_COMPLETED,
            payload={"case_id": case.id, "doctor_id": case.doctor_id},
        )

        logger.info(
            "Case completed: id=%s by doctor=%s", case.id, requester.id,
        )
        return updated

    # ═══════════════════════════════════════════════════════
    # Admin listing
    # ═══════════════════════════════════════════════════════
    async def list_for_admin(
        self, *, status: CaseStatus | None, offset: int, limit: int,
    ) -> list[PatientCase]:
        return await self._cases.list_for_admin(
            status=status, offset=offset, limit=limit,
        )