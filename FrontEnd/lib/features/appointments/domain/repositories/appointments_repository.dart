import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/appointment.dart';
import '../entities/doctor_stats.dart';

/// Params for listing appointments.
class ListAppointmentsParams {
  const ListAppointmentsParams({
    this.mine = true,
    this.status,
  });

  /// Doctor-side flag: limit results to the current user's appointments.
  /// Ignored for patients (they always see their own) and admins.
  final bool mine;

  /// Optional status filter.
  final AppointmentStatus? status;
}

abstract class AppointmentsRepository {
  Future<Either<Failure, Appointment>> createAppointment(int caseId);

  Future<Either<Failure, List<Appointment>>> listAppointments(
      ListAppointmentsParams params,
      );

  Future<Either<Failure, Appointment>> getAppointment(int id);

  Future<Either<Failure, Appointment>> approveAppointment(int id);

  Future<Either<Failure, Appointment>> rejectAppointment(int id);

  Future<Either<Failure, void>> cancelAppointment(int id);
  Future<Either<Failure, Appointment>> completeAppointment(int id);
  Future<Either<Failure, DoctorStats>> getMyStats();
}