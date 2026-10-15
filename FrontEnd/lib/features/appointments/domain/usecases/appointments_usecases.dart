import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/appointment.dart';
import '../entities/doctor_stats.dart';
import '../repositories/appointments_repository.dart';

// ═══════════════════════════════════════════════════════════════
class CreateAppointmentUseCase
    extends UseCase<Appointment, int> {
  CreateAppointmentUseCase(this._repo);
  final AppointmentsRepository _repo;

  @override
  Future<Either<Failure, Appointment>> call(int caseId) =>
      _repo.createAppointment(caseId);
}

// ═══════════════════════════════════════════════════════════════
class ListAppointmentsUseCase
    extends UseCase<List<Appointment>, ListAppointmentsParams> {
  ListAppointmentsUseCase(this._repo);
  final AppointmentsRepository _repo;

  @override
  Future<Either<Failure, List<Appointment>>> call(
      ListAppointmentsParams params,
      ) =>
      _repo.listAppointments(params);
}

// ═══════════════════════════════════════════════════════════════
class GetAppointmentUseCase extends UseCase<Appointment, int> {
  GetAppointmentUseCase(this._repo);
  final AppointmentsRepository _repo;

  @override
  Future<Either<Failure, Appointment>> call(int id) =>
      _repo.getAppointment(id);
}

// ═══════════════════════════════════════════════════════════════
class ApproveAppointmentUseCase extends UseCase<Appointment, int> {
  ApproveAppointmentUseCase(this._repo);
  final AppointmentsRepository _repo;

  @override
  Future<Either<Failure, Appointment>> call(int id) =>
      _repo.approveAppointment(id);
}

// ═══════════════════════════════════════════════════════════════
class RejectAppointmentUseCase extends UseCase<Appointment, int> {
  RejectAppointmentUseCase(this._repo);
  final AppointmentsRepository _repo;

  @override
  Future<Either<Failure, Appointment>> call(int id) =>
      _repo.rejectAppointment(id);
}

// ═══════════════════════════════════════════════════════════════
class CancelAppointmentUseCase extends UseCase<void, int> {
  CancelAppointmentUseCase(this._repo);
  final AppointmentsRepository _repo;

  @override
  Future<Either<Failure, void>> call(int id) =>
      _repo.cancelAppointment(id);
}
// ═══════════════════════════════════════════════════════════════
class CompleteAppointmentUseCase extends UseCase<Appointment, int> {
  CompleteAppointmentUseCase(this._repo);
  final AppointmentsRepository _repo;

  @override
  Future<Either<Failure, Appointment>> call(int id) =>
      _repo.completeAppointment(id);
}
class GetDoctorStatsUseCase {
  GetDoctorStatsUseCase(this._repo);
  final AppointmentsRepository _repo;

  Future<Either<Failure, DoctorStats>> call() => _repo.getMyStats();
}