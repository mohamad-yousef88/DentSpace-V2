import 'package:dentspace/features/appointments/domain/entities/doctor_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DoctorStats.fromJson', () {
    test('parses all fields', () {
      final s = DoctorStats.fromJson(const {
        'active_requests': 3,
        'ongoing_bookings': 2,
        'verified_cases': 5,
      });

      expect(s.activeRequests, 3);
      expect(s.ongoingBookings, 2);
      expect(s.verifiedCases, 5);
    });

    test('missing fields default to 0', () {
      final s = DoctorStats.fromJson(const {});
      expect(s.activeRequests, 0);
      expect(s.ongoingBookings, 0);
      expect(s.verifiedCases, 0);
    });

    test('numeric strings are coerced', () {
      final s = DoctorStats.fromJson(const {
        'active_requests': 4,
        'ongoing_bookings': 1,
        'verified_cases': 8,
      });
      expect(s.activeRequests, 4);
    });
  });

  group('DoctorStats.empty', () {
    test('is all zeros', () {
      expect(DoctorStats.empty.activeRequests, 0);
      expect(DoctorStats.empty.ongoingBookings, 0);
      expect(DoctorStats.empty.verifiedCases, 0);
    });
  });

  group('Equatable', () {
    test('two stats with same values are equal', () {
      const a = DoctorStats(
        activeRequests: 1,
        ongoingBookings: 2,
        verifiedCases: 3,
      );
      const b = DoctorStats(
        activeRequests: 1,
        ongoingBookings: 2,
        verifiedCases: 3,
      );
      const c = DoctorStats(
        activeRequests: 1,
        ongoingBookings: 2,
        verifiedCases: 4,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}