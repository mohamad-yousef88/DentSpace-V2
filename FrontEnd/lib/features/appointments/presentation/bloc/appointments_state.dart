import 'package:equatable/equatable.dart';

import '../../domain/entities/appointment.dart';
import '../../domain/entities/doctor_stats.dart';

enum AppointmentsStatus {
  idle,
  loading,      // list is loading
  loaded,
  submitting,   // create/approve/reject/cancel in flight
  failure,
}

class AppointmentsState extends Equatable {
  const AppointmentsState({
    this.status = AppointmentsStatus.idle,
    this.appointments = const [],
    this.stats,
    this.errorMessage,
    this.successMessage,
  });

  final AppointmentsStatus status;
  final List<Appointment> appointments;

  /// Doctor dashboard counters — populated by [LoadDoctorStatsEvent].
  /// `null` until the first fetch completes.
  final DoctorStats? stats;

  final String? errorMessage;

  /// One of the sentinel values:
  /// `appointment_created`, `appointment_approved`, `appointment_rejected`,
  /// `appointment_cancelled`, `appointment_completed`.
  final String? successMessage;

  bool get isListLoading => status == AppointmentsStatus.loading;
  bool get isSubmitting => status == AppointmentsStatus.submitting;
  bool get isFailure => status == AppointmentsStatus.failure;

  AppointmentsState copyWith({
    AppointmentsStatus? status,
    List<Appointment>? appointments,
    DoctorStats? stats,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearStats = false,
  }) {
    return AppointmentsState(
      status: status ?? this.status,
      appointments: appointments ?? this.appointments,
      stats: clearStats ? null : (stats ?? this.stats),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
      clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, appointments, stats, errorMessage, successMessage];
}