"""Appointment repository interface."""
from abc import ABC, abstractmethod

from app.domain.entities.appointment import Appointment, AppointmentStatus


class AppointmentRepository(ABC):

    @abstractmethod
    async def get_by_id(self, appointment_id: int) -> Appointment | None: ...

    @abstractmethod
    async def create(self, appointment: Appointment) -> Appointment: ...

    @abstractmethod
    async def update(self, appointment: Appointment) -> Appointment: ...
    @abstractmethod
    async def get_by_id_for_update(self, appointment_id: int) -> Appointment | None: ...

    @abstractmethod
    async def delete(self, appointment_id: int) -> None: ...

    @abstractmethod
    async def find_pending_by_doctor_and_case(
        self, doctor_id: int, case_id: int,
    ) -> Appointment | None: ...

    @abstractmethod
    async def list_pending_for_case(self, case_id: int) -> list[Appointment]: ...

    @abstractmethod
    async def count_active_for_doctor(self, doctor_id: int) -> int: ...
    """Count of pending + approved appointments for a doctor."""

    @abstractmethod
    async def count_active_for_patient(self, patient_id: int) -> int: ...

    @abstractmethod
    async def list_for_patient(
        self, patient_id: int, *,
        status: AppointmentStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[Appointment]: ...

    @abstractmethod
    async def list_for_doctor(
        self, doctor_id: int, *,
        status: AppointmentStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[Appointment]: ...

    @abstractmethod
    async def list_all(
        self, *, status: AppointmentStatus | None = None,
        offset: int = 0, limit: int = 20,
    ) -> list[Appointment]: ...

    @abstractmethod
    async def count_doctor_dashboard(self, doctor_id: int) -> dict[str, int]: ...