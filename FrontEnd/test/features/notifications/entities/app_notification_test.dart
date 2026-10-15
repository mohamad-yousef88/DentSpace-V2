import 'package:dentspace/features/notifications/domain/entities/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('AppNotification.fromJson', () {
    test('parses a full payload', () {
      final n = AppNotification.fromJson(TestData.notificationJson());

      expect(n.id, 1);
      expect(n.title, 'Test title');
      expect(n.body, 'Test body');
      expect(n.type, 'appointment_request');
      expect(n.isRead, isFalse);
      expect(n.payload?['order_id'], 42);
    });

    test('defaults to system type when missing', () {
      final n = AppNotification.fromJson(const {
        'id': 5,
        'title': 'x',
        'created_at': '2026-01-01T00:00:00Z',
      });

      expect(n.type, 'system');
      expect(n.isRead, isFalse);
      expect(n.payload, isNull);
    });

    test('parses read flag', () {
      final n = AppNotification.fromJson(
        TestData.notificationJson(isRead: true),
      );
      expect(n.isRead, isTrue);
    });
  });

  group('AppNotification.toJson', () {
    test('round-trips through JSON', () {
      final original = TestData.notification(id: 99, isRead: true);
      final restored = AppNotification.fromJson(original.toJson());

      expect(restored.id, 99);
      expect(restored.isRead, isTrue);
      expect(restored.payload?['order_id'], 42);
    });
  });

  group('copyWith', () {
    test('changes isRead only', () {
      final n = TestData.notification(id: 1, isRead: false);
      final read = n.copyWith(isRead: true);

      expect(read.id, n.id);
      expect(read.title, n.title);
      expect(read.isRead, isTrue);
      expect(n.isRead, isFalse); // original unchanged
    });

    test('without args → same values', () {
      final n = TestData.notification(id: 1, isRead: true);
      final copy = n.copyWith();
      expect(copy.id, n.id);
      expect(copy.isRead, n.isRead);
    });
  });

  group('Equatable props', () {
    test('equality keyed on id + isRead only', () {
      final a = TestData.notification(id: 1, isRead: false);
      final b = TestData.notification(id: 1, isRead: false);
      final c = TestData.notification(id: 1, isRead: true);
      final d = TestData.notification(id: 2, isRead: false);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });
}