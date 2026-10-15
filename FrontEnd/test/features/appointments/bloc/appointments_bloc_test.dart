import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dentspace/core/error/failures.dart';
import 'package:dentspace/features/appointments/domain/entities/appointment.dart';
import 'package:dentspace/features/appointments/presentation/bloc/appointments_bloc.dart';
import 'package:dentspace/features/appointments/presentation/bloc/appointments_event.dart';
import 'package:dentspace/features/appointments/presentation/bloc/appointments_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_data.dart';
import '../../../helpers/test_mocks.dart';

void main() {
  late MockCreateAppointmentUseCase create;
  late MockListAppointmentsUseCase list;
  late MockApproveAppointmentUseCase approve;
  late MockRejectAppointmentUseCase reject;
  late MockCancelAppointmentUseCase cancel;
  late MockCompleteAppointmentUseCase complete;
  late MockGetDoctorStatsUseCase stats;

  setUpAll(registerFallbackValues);

  setUp(() {
    create = MockCreateAppointmentUseCase();
    list = MockListAppointmentsUseCase();
    approve = MockApproveAppointmentUseCase();
    reject = MockRejectAppointmentUseCase();
    cancel = MockCancelAppointmentUseCase();
    complete = MockCompleteAppointmentUseCase();
    stats = MockGetDoctorStatsUseCase();
  });

  AppointmentsBloc build() => AppointmentsBloc(
    createAppointment: create,
    listAppointments: list,
    approveAppointment: approve,
    rejectAppointment: reject,
    cancelAppointment: cancel,
    completeAppointment: complete,
    getDoctorStats: stats,
  );

  // ═══════════════════════════════════════════════════════════
  group('LoadAppointmentsEvent', () {
    blocTest<AppointmentsBloc, AppointmentsState>(
      'loads pending list',
      setUp: () {
        when(() => list(any())).thenAnswer(
              (_) async => Right<Failure, List<Appointment>>([
            TestData.appointment(id: 1),
            TestData.appointment(id: 2),
          ]),
        );
      },
      build: build,
      act: (b) => b.add(const LoadAppointmentsEvent(
        mine: true,
        status: AppointmentStatus.pending,
      ),),
      expect: () => [
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.loading),
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.loaded)
            .having((s) => s.appointments.length, 'len', 2),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('CreateAppointmentEvent', () {
    blocTest<AppointmentsBloc, AppointmentsState>(
      'prepends the new request',
      setUp: () {
        when(() => create(any())).thenAnswer(
              (_) async => Right<Failure, Appointment>(
            TestData.appointment(id: 99),
          ),
        );
      },
      build: build,
      act: (b) => b.add(const CreateAppointmentEvent(5)),
      expect: () => [
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.submitting),
        isA<AppointmentsState>()
            .having((s) => s.appointments.first.id, 'id', 99)
            .having((s) => s.successMessage, 'ok', 'appointment_created'),
      ],
    );

    blocTest<AppointmentsBloc, AppointmentsState>(
      'conflict when duplicate request → failure',
      setUp: () {
        when(() => create(any())).thenAnswer(
              (_) async => const Left(
            ServerFailure(message: 'You already have a pending request'),
          ),
        );
      },
      build: build,
      act: (b) => b.add(const CreateAppointmentEvent(5)),
      expect: () => [
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.submitting),
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.failure)
            .having(
              (s) => s.errorMessage,
          'err',
          'You already have a pending request',
        ),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('ApproveAppointmentEvent', () {
    blocTest<AppointmentsBloc, AppointmentsState>(
      'updates status to approved',
      setUp: () {
        when(() => approve(any())).thenAnswer(
              (_) async => Right<Failure, Appointment>(
            TestData.appointment(id: 1, status: AppointmentStatus.approved),
          ),
        );
      },
      seed: () => AppointmentsState(
        status: AppointmentsStatus.loaded,
        appointments: [TestData.appointment(id: 1)],
      ),
      build: build,
      act: (b) => b.add(const ApproveAppointmentEvent(1)),
      expect: () => [
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.submitting),
        isA<AppointmentsState>()
            .having(
              (s) => s.appointments.first.status,
          'status',
          AppointmentStatus.approved,
        )
            .having((s) => s.successMessage, 'ok', 'appointment_approved'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('RejectAppointmentEvent', () {
    blocTest<AppointmentsBloc, AppointmentsState>(
      'updates status to rejected',
      setUp: () {
        when(() => reject(any())).thenAnswer(
              (_) async => Right<Failure, Appointment>(
            TestData.appointment(id: 1, status: AppointmentStatus.rejected),
          ),
        );
      },
      seed: () => AppointmentsState(
        status: AppointmentsStatus.loaded,
        appointments: [TestData.appointment(id: 1)],
      ),
      build: build,
      act: (b) => b.add(const RejectAppointmentEvent(1)),
      expect: () => [
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.submitting),
        isA<AppointmentsState>()
            .having((s) => s.successMessage, 'ok', 'appointment_rejected'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('CompleteAppointmentEvent (confirm treatment done)', () {
    blocTest<AppointmentsBloc, AppointmentsState>(
      'transitions approved → completed',
      setUp: () {
        when(() => complete(any())).thenAnswer(
              (_) async => Right<Failure, Appointment>(
            TestData.appointment(id: 1, status: AppointmentStatus.completed),
          ),
        );
      },
      seed: () => AppointmentsState(
        status: AppointmentsStatus.loaded,
        appointments: [
          TestData.appointment(id: 1, status: AppointmentStatus.approved),
        ],
      ),
      build: build,
      act: (b) => b.add(const CompleteAppointmentEvent(1)),
      expect: () => [
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.submitting),
        isA<AppointmentsState>()
            .having(
              (s) => s.appointments.first.status,
          'status',
          AppointmentStatus.completed,
        )
            .having((s) => s.successMessage, 'ok', 'appointment_completed'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('CancelAppointmentEvent', () {
    blocTest<AppointmentsBloc, AppointmentsState>(
      'removes the appointment',
      setUp: () {
        when(() => cancel(any()))
            .thenAnswer((_) async => const Right(null));
      },
      seed: () => AppointmentsState(
        status: AppointmentsStatus.loaded,
        appointments: [
          TestData.appointment(id: 1),
          TestData.appointment(id: 2),
        ],
      ),
      build: build,
      act: (b) => b.add(const CancelAppointmentEvent(1)),
      expect: () => [
        isA<AppointmentsState>()
            .having((s) => s.status, 's', AppointmentsStatus.submitting),
        isA<AppointmentsState>()
            .having((s) => s.appointments.length, 'len', 1)
            .having((s) => s.successMessage, 'ok', 'appointment_cancelled'),
      ],
    );
  });
}