"""
PatientCase repository interface (port).
"""
from abc import ABC, abstractmethod

from app.domain.entities.patient_case import CaseStatus, PatientCase


class CaseRepository(ABC):

    @abstractmethod
    async def get_by_id(self, case_id: int) -> PatientCase | None: ...

    @abstractmethod
    async def create(self, case: PatientCase) -> PatientCase: ...

    @abstractmethod
    async def update(self, case: PatientCase) -> PatientCase: ...
    @abstractmethod
    async def get_by_id_for_update(self, case_id: int) -> PatientCase | None: ...

    @abstractmethod
    async def delete(self, case_id: int) -> None: ...

    @abstractmethod
    async def count_pending_for_patient(self, patient_id: int) -> int: ...

    @abstractmethod
    async def list_for_patient(
        self, patient_id: int, *,
        status: CaseStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[PatientCase]: ...

    @abstractmethod
    async def list_for_doctor(
        self, doctor_id: int, *,
        status: CaseStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[PatientCase]: ...

    @abstractmethod
    async def list_available(
        self, *, search: str | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[PatientCase]: ...

    @abstractmethod
    async def list_all(
        self, *, status: CaseStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[PatientCase]: ...
    @abstractmethod
    async def list_for_admin(
        self, *, status: CaseStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[PatientCase]: ...

    @abstractmethod
    async def count_by_status(self) -> dict[str, int]: ...
    """Return {status_value: count} for admin dashboard."""