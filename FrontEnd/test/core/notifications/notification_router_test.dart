import 'package:dentspace/core/notifications/notification_router.dart';
import 'package:dentspace/core/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that every backend notification type maps to the correct
/// in-app route (deep-link correctness).
void main() {
  group('NotificationRouter — cases', () {
    test('case_verified → achievements', () {
      expect(
        NotificationRouter.routeFor('case_verified'),
        Routes.achievements,
      );
    });

    test('case_completed → appointments', () {
      expect(
        NotificationRouter.routeFor('case_completed'),
        Routes.appointments,
      );
    });

    test('case_rejected → appointments', () {
      expect(
        NotificationRouter.routeFor('case_rejected'),
        Routes.appointments,
      );
    });
  });

  group('NotificationRouter — appointments', () {
    for (final type in const [
      'appointment_request',
      'appointment_approved',
      'appointment_rejected',
      'appointment_cancelled',
    ]) {
      test('$type → appointments', () {
        expect(NotificationRouter.routeFor(type), Routes.appointments);
      });
    }
  });

  group('NotificationRouter — tool orders', () {
    test('with int order_id → orderDetails(id)', () {
      for (final type in const [
        'tool_order_request',
        'tool_order_approved',
        'tool_order_rejected',
        'tool_order_cancelled',
        'tool_sold',
      ]) {
        final route = NotificationRouter.routeFor(
          type,
          payload: const {'order_id': 42},
        );
        expect(route, Routes.orderDetails(42), reason: 'type=$type');
      }
    });

    test('without order_id → orders list', () {
      for (final type in const [
        'tool_order_request',
        'tool_order_approved',
        'tool_order_rejected',
        'tool_order_cancelled',
        'tool_sold',
      ]) {
        final route = NotificationRouter.routeFor(type);
        expect(route, Routes.orders, reason: 'type=$type');
      }
    });

    test('non-int order_id → orders list', () {
      expect(
        NotificationRouter.routeFor(
          'tool_order_approved',
          payload: const {'order_id': 'not-an-int'},
        ),
        Routes.orders,
      );
    });

    test('nullable order_id → orders list', () {
      expect(
        NotificationRouter.routeFor(
          'tool_order_approved',
          payload: const {'order_id': null},
        ),
        Routes.orders,
      );
    });
  });

  group('NotificationRouter — fallback', () {
    test('system → null (stay where you are)', () {
      expect(NotificationRouter.routeFor('system'), isNull);
    });

    test('unknown type → null', () {
      expect(NotificationRouter.routeFor('weird_xyz'), isNull);
    });

    test('empty type → null', () {
      expect(NotificationRouter.routeFor(''), isNull);
    });
  });
}