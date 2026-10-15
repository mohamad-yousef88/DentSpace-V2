import 'package:equatable/equatable.dart';

import '../../domain/entities/appointment.dart';

sealed class AppointmentsEvent extends Equatable {
  const AppointmentsEvent();
  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════
// List
// ═══════════════════════════════════════════════════════════════
class LoadAppointmentsEvent extends AppointmentsEvent {
  const LoadAppointmentsEvent({
    this.mine = true,
    this.status,
  });

  final bool mine;
  final AppointmentStatus? status;

  @override
  List<Object?> get props => [mine, status];
}

// ═══════════════════════════════════════════════════════════════
// Actions
// ═══════════════════════════════════════════════════════════════
class CreateAppointmentEvent extends AppointmentsEvent {
  const CreateAppointmentEvent(this.caseId);
  final int caseId;

  @override
  List<Object?> get props => [caseId];
}

class ApproveAppointmentEvent extends AppointmentsEvent {
  const ApproveAppointmentEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class RejectAppointmentEvent extends AppointmentsEvent {
  const RejectAppointmentEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class CancelAppointmentEvent extends AppointmentsEvent {
  const CancelAppointmentEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

/// Clear success/error feedback after the UI has shown it.
class ClearAppointmentFeedbackEvent extends AppointmentsEvent {
  const ClearAppointmentFeedbackEvent();
}
class CompleteAppointmentEvent extends AppointmentsEvent {
  const CompleteAppointmentEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}
class LoadDoctorStatsEvent extends AppointmentsEvent {
  const LoadDoctorStatsEvent();
}