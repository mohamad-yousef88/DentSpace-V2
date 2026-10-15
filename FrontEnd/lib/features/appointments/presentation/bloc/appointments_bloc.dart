import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/appointments_repository.dart';
import '../../domain/usecases/appointments_usecases.dart';
import 'appointments_event.dart';
import 'appointments_state.dart';

class AppointmentsBloc
    extends Bloc<AppointmentsEvent, AppointmentsState> {
  AppointmentsBloc({
    required CreateAppointmentUseCase createAppointment,
    required ListAppointmentsUseCase listAppointments,
    required ApproveAppointmentUseCase approveAppointment,
    required RejectAppointmentUseCase rejectAppointment,
    required CancelAppointmentUseCase cancelAppointment,
    required CompleteAppointmentUseCase completeAppointment,
    required GetDoctorStatsUseCase getDoctorStats,
  })  : _create = createAppointment,
        _list = listAppointments,
        _approve = approveAppointment,
        _reject = rejectAppointment,
        _cancel = cancelAppointment,
        _complete = completeAppointment,
        _getDoctorStats = getDoctorStats,
        super(const AppointmentsState()) {
    on<LoadAppointmentsEvent>(_onLoad);
    on<CreateAppointmentEvent>(_onCreate);
    on<ApproveAppointmentEvent>(_onApprove);
    on<RejectAppointmentEvent>(_onReject);
    on<CancelAppointmentEvent>(_onCancel);
    on<CompleteAppointmentEvent>(_onComplete);
    on<ClearAppointmentFeedbackEvent>(_onClearFeedback);
    on<LoadDoctorStatsEvent>(_onLoadStats);
  }

  final CreateAppointmentUseCase _create;
  final ListAppointmentsUseCase _list;
  final ApproveAppointmentUseCase _approve;
  final RejectAppointmentUseCase _reject;
  final CancelAppointmentUseCase _cancel;
  final CompleteAppointmentUseCase _complete;
  final GetDoctorStatsUseCase _getDoctorStats;

  // ═══════════════════════════════════════════════════════════════
  // List
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoad(
      LoadAppointmentsEvent event,
      Emitter<AppointmentsState> emit,
      ) async {
    emit(state.copyWith(
      status: AppointmentsStatus.loading,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _list(ListAppointmentsParams(
      mine: event.mine,
      status: event.status,
    ),);
    result.fold(
          (f) => emit(state.copyWith(
        status: AppointmentsStatus.failure,
        errorMessage: f.message,
      ),),
          (items) => emit(state.copyWith(
        status: AppointmentsStatus.loaded,
        appointments: items,
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Create
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onCreate(
      CreateAppointmentEvent event,
      Emitter<AppointmentsState> emit,
      ) async {
    emit(state.copyWith(
      status: AppointmentsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _create(event.caseId);
    result.fold(
          (f) => emit(state.copyWith(
        status: AppointmentsStatus.failure,
        errorMessage: f.message,
      ),),
          (created) => emit(state.copyWith(
        status: AppointmentsStatus.loaded,
        appointments: [created, ...state.appointments],
        successMessage: 'appointment_created',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Approve
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onApprove(
      ApproveAppointmentEvent event,
      Emitter<AppointmentsState> emit,
      ) async {
    emit(state.copyWith(
      status: AppointmentsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _approve(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: AppointmentsStatus.failure,
        errorMessage: f.message,
      ),),
          (updated) => emit(state.copyWith(
        status: AppointmentsStatus.loaded,
        appointments: state.appointments
            .map((a) => a.id == updated.id ? updated : a)
            .toList(),
        successMessage: 'appointment_approved',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Reject
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onReject(
      RejectAppointmentEvent event,
      Emitter<AppointmentsState> emit,
      ) async {
    emit(state.copyWith(
      status: AppointmentsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _reject(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: AppointmentsStatus.failure,
        errorMessage: f.message,
      ),),
          (updated) => emit(state.copyWith(
        status: AppointmentsStatus.loaded,
        appointments: state.appointments
            .map((a) => a.id == updated.id ? updated : a)
            .toList(),
        successMessage: 'appointment_rejected',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Cancel
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onCancel(
      CancelAppointmentEvent event,
      Emitter<AppointmentsState> emit,
      ) async {
    emit(state.copyWith(
      status: AppointmentsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _cancel(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: AppointmentsStatus.failure,
        errorMessage: f.message,
      ),),
          (_) => emit(state.copyWith(
        status: AppointmentsStatus.loaded,
        appointments:
        state.appointments.where((a) => a.id != event.id).toList(),
        successMessage: 'appointment_cancelled',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Complete treatment
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onComplete(
      CompleteAppointmentEvent event,
      Emitter<AppointmentsState> emit,
      ) async {
    emit(state.copyWith(
      status: AppointmentsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _complete(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: AppointmentsStatus.failure,
        errorMessage: f.message,
      ),),
          (updated) => emit(state.copyWith(
        status: AppointmentsStatus.loaded,
        appointments: state.appointments
            .map((a) => a.id == updated.id ? updated : a)
            .toList(),
        successMessage: 'appointment_completed',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  void _onClearFeedback(
      ClearAppointmentFeedbackEvent event,
      Emitter<AppointmentsState> emit,
      ) {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
  Future<void> _onLoadStats(
      LoadDoctorStatsEvent event,
      Emitter<AppointmentsState> emit,
      ) async {
    final result = await _getDoctorStats();
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (stats) => emit(state.copyWith(stats: stats)),
    );
  }
}