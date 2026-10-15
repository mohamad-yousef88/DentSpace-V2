import 'package:dentspace/features/appointments/domain/entities/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('Appointment.fromJson', () {
    test('parses a full payload', () {
      final a = Appointment.fromJson(TestData.appointmentJson());

      expect(a.id, 1);
      expect(a.status, AppointmentStatus.pending);
      expect(a.caseInfo?.suspectedCondition, 'Dental caries');
      expect(a.patient?.fullName, 'Patient X');
      expect(a.doctor?.fullName, 'Dr. Y');
    });

    test('parses all statuses', () {
      for (final s in AppointmentStatus.values) {
        final a = Appointment.fromJson(
          TestData.appointmentJson(status: s.name),
        );
        expect(a.status, s);
      }
    });

    test('unknown status → pending', () {
      final a = Appointment.fromJson(
        TestData.appointmentJson(status: 'weird'),
      );
      expect(a.status, AppointmentStatus.pending);
    });

    test('handles missing optional blocks', () {
      final a = Appointment.fromJson(const {
        'id': 1,
        'status': 'pending',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(a.patient, isNull);
      expect(a.doctor, isNull);
      expect(a.caseInfo, isNull);
    });
  });

  group('Appointment.toJson', () {
    test('round-trips through JSON', () {
      final original = TestData.appointment(
        id: 42,
        status: AppointmentStatus.approved,
      );
      final restored = Appointment.fromJson(original.toJson());

      expect(restored.id, 42);
      expect(restored.status, AppointmentStatus.approved);
      expect(restored.caseInfo?.id, original.caseInfo?.id);
    });
  });

  group('AppointmentStatus helpers', () {
    test('isActive for pending and approved only', () {
      expect(AppointmentStatus.pending.isActive, isTrue);
      expect(AppointmentStatus.approved.isActive, isTrue);
      expect(AppointmentStatus.rejected.isActive, isFalse);
      expect(AppointmentStatus.cancelled.isActive, isFalse);
      expect(AppointmentStatus.completed.isActive, isFalse);
    });
  });
}