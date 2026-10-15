import 'package:dentspace/core/error/exceptions.dart';
import 'package:dentspace/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:dentspace/features/appointments/domain/entities/appointment.dart';
import 'package:dentspace/features/appointments/domain/entities/doctor_stats.dart';
import 'package:dentspace/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_mocks.dart';

void main() {
  late MockAppointmentsRemoteDataSource remote;
  late MockCacheService cache;

  setUpAll(registerFallbackValues);

  setUp(() {
    remote = MockAppointmentsRemoteDataSource();
    cache = MockCacheService();
    when(() => cache.saveAppointmentsList(any(), any()))
        .thenAnswer((_) async {});
    when(() => cache.saveDoctorStats(any())).thenAnswer((_) async {});
    when(() => cache.invalidateAppointments()).thenAnswer((_) async {});
  });

  AppointmentsRepositoryImpl build() =>
      AppointmentsRepositoryImpl(remote, cache);

  // ═══════════════════════════════════════════════════════════════
  group('listAppointments', () {
    test('success → caches per status key', () async {
      when(() => remote.listAppointments(any())).thenAnswer(
            (_) async => [TestData.appointment(id: 1)],
      );

      final result = await build().listAppointments(
        const ListAppointmentsParams(status: AppointmentStatus.pending),
      );

      expect(result.isRight(), isTrue);
      verify(() => cache.saveAppointmentsList('pending', any())).called(1);
    });

    test('failure + cache → cached', () async {
      when(() => remote.listAppointments(any()))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readAppointmentsList('pending'))
          .thenReturn([TestData.appointmentJson(id: 5)]);

      final result = await build().listAppointments(
        const ListAppointmentsParams(status: AppointmentStatus.pending),
      );

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.first.id, 5));
    });

    test('failure + no cache → Left', () async {
      when(() => remote.listAppointments(any()))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readAppointmentsList(any())).thenReturn(null);

      final result = await build().listAppointments(
        const ListAppointmentsParams(status: AppointmentStatus.pending),
      );

      expect(result.isLeft(), isTrue);
    });

    test('null status → "all" cache key', () async {
      when(() => remote.listAppointments(any())).thenAnswer(
            (_) async => [TestData.appointment(id: 1)],
      );

      await build().listAppointments(const ListAppointmentsParams());

      verify(() => cache.saveAppointmentsList('all', any())).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('mutations invalidate cache', () {
    test('createAppointment', () async {
      when(() => remote.createAppointment(any()))
          .thenAnswer((_) async => TestData.appointment(id: 1));

      await build().createAppointment(5);

      verify(() => cache.invalidateAppointments()).called(1);
    });

    test('approveAppointment', () async {
      when(() => remote.approveAppointment(any()))
          .thenAnswer((_) async => TestData.appointment(id: 1));

      await build().approveAppointment(1);

      verify(() => cache.invalidateAppointments()).called(1);
    });

    test('rejectAppointment', () async {
      when(() => remote.rejectAppointment(any()))
          .thenAnswer((_) async => TestData.appointment(id: 1));

      await build().rejectAppointment(1);

      verify(() => cache.invalidateAppointments()).called(1);
    });

    test('cancelAppointment', () async {
      when(() => remote.cancelAppointment(any())).thenAnswer((_) async {});

      await build().cancelAppointment(1);

      verify(() => cache.invalidateAppointments()).called(1);
    });

    test('completeAppointment', () async {
      when(() => remote.completeAppointment(any()))
          .thenAnswer((_) async => TestData.appointment(id: 1));

      await build().completeAppointment(1);

      verify(() => cache.invalidateAppointments()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('getMyStats', () {
    test('success → caches stats', () async {
      when(() => remote.getMyStats()).thenAnswer(
            (_) async => const DoctorStats(
          activeRequests: 3,
          ongoingBookings: 2,
          verifiedCases: 5,
        ),
      );

      final result = await build().getMyStats();

      expect(result.isRight(), isTrue);
      result.fold(
            (_) {},
            (s) {
          expect(s.activeRequests, 3);
          expect(s.ongoingBookings, 2);
          expect(s.verifiedCases, 5);
        },
      );
      verify(() => cache.saveDoctorStats(any())).called(1);
    });

    test('failure + cache → cached', () async {
      when(() => remote.getMyStats())
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readDoctorStats()).thenReturn({
        'active_requests': 7,
        'ongoing_bookings': 1,
        'verified_cases': 9,
      });

      final result = await build().getMyStats();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (s) => expect(s.activeRequests, 7));
    });

    test('failure + no cache → Left', () async {
      when(() => remote.getMyStats())
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readDoctorStats()).thenReturn(null);

      expect((await build().getMyStats()).isLeft(), isTrue);
    });
  });
}