
import 'package:dentspace/features/notifications/presentation/notification_translator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that every notification type produces a distinct, localized
/// (title, body) pair for both AR and EN, and that payload fields are
/// interpolated correctly.
void main() {
  // ═══════════════════════════════════════════════════════════════
  group('NotificationTranslator — appointments', () {
    test('appointment_request with doctor_name (ar + en)', () {
      final ar = NotificationTranslator.translate(
        type: 'appointment_request',
        payload: const {'doctor_name': 'د. أحمد'},
        isArabic: true,
      );
      expect(ar.title, 'طلب حجز جديد');
      expect(ar.body, contains('د. أحمد'));

      final en = NotificationTranslator.translate(
        type: 'appointment_request',
        payload: const {'doctor_name': 'Dr. Ahmad'},
        isArabic: false,
      );
      expect(en.title, 'New booking request');
      expect(en.body, contains('Dr. Ahmad'));
    });

    test('appointment_request without doctor_name → generic body', () {
      final ar = NotificationTranslator.translate(
        type: 'appointment_request',
        payload: null,
        isArabic: true,
      );
      expect(ar.body, contains('طلب حجز'));

      final en = NotificationTranslator.translate(
        type: 'appointment_request',
        payload: null,
        isArabic: false,
      );
      expect(en.body.toLowerCase(), contains('request'));
    });

    test('appointment_approved with patient_name', () {
      final ar = NotificationTranslator.translate(
        type: 'appointment_approved',
        payload: const {'patient_name': 'سامر'},
        isArabic: true,
      );
      expect(ar.title, 'تمت الموافقة على الحجز');
      expect(ar.body, contains('سامر'));

      final en = NotificationTranslator.translate(
        type: 'appointment_approved',
        payload: const {'patient_name': 'Samer'},
        isArabic: false,
      );
      expect(en.body, contains('Samer'));
    });

    test('appointment_rejected → static message', () {
      final ar = NotificationTranslator.translate(
        type: 'appointment_rejected',
        payload: null,
        isArabic: true,
      );
      expect(ar.title, 'تم رفض طلب الحجز');
      expect(ar.body, 'تم رفض طلب الحجز.');
    });

    test('appointment_cancelled → static message', () {
      final en = NotificationTranslator.translate(
        type: 'appointment_cancelled',
        payload: null,
        isArabic: false,
      );
      expect(en.title, 'Appointment cancelled');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('NotificationTranslator — cases', () {
    test('case_completed (ar + en)', () {
      final ar = NotificationTranslator.translate(
        type: 'case_completed',
        payload: null,
        isArabic: true,
      );
      expect(ar.title, 'انتهى العلاج');

      final en = NotificationTranslator.translate(
        type: 'case_completed',
        payload: null,
        isArabic: false,
      );
      expect(en.title, 'Treatment finished');
    });

    test('case_verified', () {
      final ar = NotificationTranslator.translate(
        type: 'case_verified',
        payload: null,
        isArabic: true,
      );
      expect(ar.title, 'تمت المصادقة على العلاج');
    });

    test('case_rejected with reason payload', () {
      final ar = NotificationTranslator.translate(
        type: 'case_rejected',
        payload: const {'reason': 'صورة غير واضحة'},
        isArabic: true,
      );
      expect(ar.title, 'تم رفض توثيق العلاج');
      expect(ar.body, contains('صورة غير واضحة'));

      final en = NotificationTranslator.translate(
        type: 'case_rejected',
        payload: const {'reason': 'Blurry image'},
        isArabic: false,
      );
      expect(en.body, contains('Blurry image'));
    });

    test('case_rejected without reason → generic body', () {
      final ar = NotificationTranslator.translate(
        type: 'case_rejected',
        payload: null,
        isArabic: true,
      );
      expect(ar.body, contains('رفضت الإدارة'));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('NotificationTranslator — tool orders', () {
    for (final type in const [
      'tool_order_request',
      'tool_order_approved',
      'tool_order_rejected',
      'tool_order_cancelled',
      'tool_sold',
    ]) {
      test('$type — returns non-empty title in both languages', () {
        final ar = NotificationTranslator.translate(
          type: type,
          payload: null,
          isArabic: true,
        );
        final en = NotificationTranslator.translate(
          type: type,
          payload: null,
          isArabic: false,
        );
        expect(ar.title.isNotEmpty, isTrue, reason: 'AR $type');
        expect(en.title.isNotEmpty, isTrue, reason: 'EN $type');
        expect(ar.title, isNot(en.title));
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════
  group('NotificationTranslator — fallback', () {
    test('system type → generic', () {
      final ar = NotificationTranslator.translate(
        type: 'system',
        payload: null,
        isArabic: true,
      );
      expect(ar.title, 'إشعار');

      final en = NotificationTranslator.translate(
        type: 'system',
        payload: null,
        isArabic: false,
      );
      expect(en.title, 'Notification');
    });

    test('unknown type → fallback to system', () {
      final ar = NotificationTranslator.translate(
        type: 'unknown_xyz',
        payload: null,
        isArabic: true,
      );
      expect(ar.title, 'إشعار');
    });

    test('empty string in payload is treated as null', () {
      final ar = NotificationTranslator.translate(
        type: 'appointment_request',
        payload: const {'doctor_name': '   '},
        isArabic: true,
      );
      // Empty → should not interpolate
      expect(ar.body, contains('طلب حجز'));
    });

    test('non-string payload value is ignored', () {
      final ar = NotificationTranslator.translate(
        type: 'appointment_request',
        payload: const {'doctor_name': 42},
        isArabic: true,
      );
      expect(ar.body, contains('طلب حجز'));
    });
  });
}