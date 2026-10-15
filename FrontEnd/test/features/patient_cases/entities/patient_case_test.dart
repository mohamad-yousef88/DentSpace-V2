import 'package:dentspace/features/patient_cases/domain/entities/patient_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('PatientCase.fromJson', () {
    test('parses a full payload', () {
      final c = PatientCase.fromJson(TestData.caseJson());

      expect(c.id, 1);
      expect(c.patientId, 200);
      expect(c.suspectedCondition, 'Dental caries');
      expect(c.status, 'pending');
      expect(c.urgency, 'routine');
      expect(c.imageUrls, isEmpty);
    });

    test('parses every status string', () {
      const statuses = ['pending', 'booked', 'completed', 'verified'];
      for (final s in statuses) {
        final c = PatientCase.fromJson(TestData.caseJson(status: s));
        expect(c.status, s);
      }
    });

    test('handles missing arrays gracefully', () {
      final c = PatientCase.fromJson(const {
        'id': 1,
        'patient_id': 200,
        'suspected_condition': 'X',
      });

      expect(c.symptoms, isEmpty);
      expect(c.imageUrls, isEmpty);
      expect(c.redFlags, isEmpty);
      expect(c.alternateConditions, isEmpty);
    });
  });

  group('PatientCase.toJson', () {
    test('round-trips through JSON', () {
      final original = TestData.patientCase(
        id: 5,
        status: 'booked',
        doctorId: 100,
      );
      final restored = PatientCase.fromJson(original.toJson());

      expect(restored.id, 5);
      expect(restored.status, 'booked');
      expect(restored.doctorId, 100);
    });
  });

  group('status helpers', () {
    test('all boolean flags map correctly', () {
      final pending = TestData.patientCase(status: 'pending');
      expect(pending.isPending, isTrue);
      expect(pending.isLocked, isFalse);

      final booked = TestData.patientCase(status: 'booked');
      expect(booked.isBooked, isTrue);
      expect(booked.isLocked, isTrue);

      final completed = TestData.patientCase(status: 'completed');
      expect(completed.isCompleted, isTrue);

      final verified = TestData.patientCase(status: 'verified');
      expect(verified.isVerified, isTrue);
    });
  });
}