"""
PatientCase router — CRUD, diagnosis preview, image management,
and doctor-side treatment completion.
"""
from fastapi import APIRouter, File, Query, UploadFile, status

from app.application.dtos.case_dto import (
    CaseListResponse,
    CaseResponse,
    CompleteTreatmentRequest,
    CreateCaseRequest,
    DiagnosisPreviewResponse,
    PreviewDiagnosisRequest,
    UpdateCaseRequest,
)
from app.core.dependencies import CaseSvc, CurrentUser
from app.domain.entities.patient_case import CaseStatus

router = APIRouter()


# ═══════════════════════════════════════════════════════════════
# Diagnosis preview
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/preview",
    response_model=DiagnosisPreviewResponse,
    summary="Preview the differential diagnosis for given symptoms",
)
async def preview_diagnosis(
    payload: PreviewDiagnosisRequest,
    user: CurrentUser,
    cases: CaseSvc,
):
    return cases.preview_diagnosis(user, payload)


# ═══════════════════════════════════════════════════════════════
# Create
# ═══════════════════════════════════════════════════════════════
@router.post(
    "",
    response_model=CaseResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new patient case (patient only)",
)
async def create_case(
    payload: CreateCaseRequest,
    user: CurrentUser,
    cases: CaseSvc,
):
    case = await cases.create_case(user, payload)
    return CaseResponse.model_validate(case.__dict__)


# ═══════════════════════════════════════════════════════════════
# List
# ═══════════════════════════════════════════════════════════════
@router.get("", response_model=CaseListResponse, summary="List cases (role-aware)")
async def list_cases(
    user: CurrentUser,
    cases: CaseSvc,
    mine: bool = Query(False, description="Limit to my cases"),
    status_filter: CaseStatus | None = Query(None, alias="status"),
    search: str | None = Query(None, description="Search (doctors only)"),
    offset: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    items = await cases.list_cases(
        user, mine=mine, status=status_filter,
        search=search, offset=offset, limit=limit,
    )
    enriched = await cases.enrich_for_viewer(user, items)
    return CaseListResponse(
        items=enriched, count=len(enriched), offset=offset, limit=limit,
    )


# ═══════════════════════════════════════════════════════════════
# Detail
# ═══════════════════════════════════════════════════════════════
@router.get("/{case_id}", response_model=CaseResponse, summary="Get a case by id")
async def get_case(case_id: int, user: CurrentUser, cases: CaseSvc):
    case = await cases.get_case(user, case_id)
    enriched = await cases.enrich_for_viewer(user, [case])
    return enriched[0]


# ═══════════════════════════════════════════════════════════════
# Update
# ═══════════════════════════════════════════════════════════════
@router.patch(
    "/{case_id}",
    response_model=CaseResponse,
    summary="Update a pending case (owner only)",
)
async def update_case(
    case_id: int,
    payload: UpdateCaseRequest,
    user: CurrentUser,
    cases: CaseSvc,
):
    case = await cases.update_case(user, case_id, payload)
    return CaseResponse.model_validate(case.__dict__)


# ═══════════════════════════════════════════════════════════════
# Delete
# ═══════════════════════════════════════════════════════════════
@router.delete(
    "/{case_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a pending case (owner only, cascades images)",
)
async def delete_case(case_id: int, user: CurrentUser, cases: CaseSvc):
    await cases.delete_case(user, case_id)


# ═══════════════════════════════════════════════════════════════
# Images
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/{case_id}/images",
    response_model=CaseResponse,
    summary="Upload one image to a case",
)
async def add_image(
    case_id: int,
    user: CurrentUser,
    cases: CaseSvc,
    file: UploadFile = File(...),
):
    size = None
    try:
        await file.seek(0)
        content = await file.read()
        size = len(content)
        await file.seek(0)
    except Exception:
        size = None
    case = await cases.add_image(
        user, case_id, file.file, file.content_type, size,
    )
    return CaseResponse.model_validate(case.__dict__)


@router.delete(
    "/{case_id}/images/{index}",
    response_model=CaseResponse,
    summary="Remove one image from a case by index",
)
async def remove_image(
    case_id: int,
    index: int,
    user: CurrentUser,
    cases: CaseSvc,
):
    case = await cases.delete_image(user, case_id, index)
    return CaseResponse.model_validate(case.__dict__)


# ═══════════════════════════════════════════════════════════════
# Doctor: complete treatment
# ═══════════════════════════════════════════════════════════════
@router.post(
    "/{case_id}/complete",
    response_model=CaseResponse,
    summary="Mark treatment as completed (assigned doctor only)",
)
async def complete_treatment(
    case_id: int,
    payload: CompleteTreatmentRequest,
    user: CurrentUser,
    cases: CaseSvc,
):
    case = await cases.complete_treatment(user, case_id, payload.notes)
    return CaseResponse.model_validate(case.__dict__)