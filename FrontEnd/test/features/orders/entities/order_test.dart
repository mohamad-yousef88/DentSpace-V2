import 'package:dentspace/features/orders/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('Order.fromJson', () {
    test('parses a full payload', () {
      final order = Order.fromJson(TestData.orderJson());

      expect(order.id, 1);
      expect(order.status, OrderStatus.pending);
      expect(order.tool?.name, 'Dental Mirror');
      expect(order.buyer?.fullName, 'Dr. Buyer');
      expect(order.seller?.fullName, 'Dr. Seller');
    });

    test('parses every status enum', () {
      for (final s in OrderStatus.values) {
        final order = Order.fromJson(TestData.orderJson(status: s.name));
        expect(order.status, s);
      }
    });

    test('unknown status → pending (safe fallback)', () {
      final order = Order.fromJson(TestData.orderJson(status: 'weird'));
      expect(order.status, OrderStatus.pending);
    });

    test('handles missing optional blocks', () {
      final order = Order.fromJson(const {
        'id': 1,
        'status': 'pending',
        'created_at': '2026-01-01T00:00:00Z',
      });

      expect(order.tool, isNull);
      expect(order.buyer, isNull);
      expect(order.seller, isNull);
    });
  });

  group('Order.toJson', () {
    test('round-trips through JSON', () {
      final original = TestData.order(id: 42, status: OrderStatus.approved);
      final restored = Order.fromJson(original.toJson());

      expect(restored.id, 42);
      expect(restored.status, OrderStatus.approved);
      expect(restored.tool?.id, original.tool?.id);
    });
  });

  group('OrderStatus', () {
    test('isActive for pending and approved only', () {
      expect(OrderStatus.pending.isActive, isTrue);
      expect(OrderStatus.approved.isActive, isTrue);
      expect(OrderStatus.rejected.isActive, isFalse);
      expect(OrderStatus.cancelled.isActive, isFalse);
      expect(OrderStatus.completed.isActive, isFalse);
    });
  });
}