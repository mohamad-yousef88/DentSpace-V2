import 'package:dentspace/core/error/exceptions.dart';
import 'package:dentspace/features/orders/data/repositories/orders_repository_impl.dart';
import 'package:dentspace/features/orders/domain/entities/order.dart';
import 'package:dentspace/features/orders/domain/repositories/orders_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_mocks.dart';

void main() {
  late MockOrdersRemoteDataSource remote;
  late MockCacheService cache;

  setUpAll(registerFallbackValues);

  setUp(() {
    remote = MockOrdersRemoteDataSource();
    cache = MockCacheService();

    when(() => cache.saveOrdersAsBuyer(any())).thenAnswer((_) async {});
    when(() => cache.saveOrdersAsSeller(any())).thenAnswer((_) async {});
    when(() => cache.invalidateOrders()).thenAnswer((_) async {});
  });

  OrdersRepositoryImpl build() => OrdersRepositoryImpl(remote, cache);

  // ═══════════════════════════════════════════════════════════════
  group('listOrders', () {
    test('seller success → caches to seller key', () async {
      when(() => remote.listOrders(any())).thenAnswer(
            (_) async => [TestData.order(id: 1)],
      );

      final result = await build().listOrders(
        const ListOrdersParams(role: 'seller'),
      );

      expect(result.isRight(), isTrue);
      verify(() => cache.saveOrdersAsSeller(any())).called(1);
      verifyNever(() => cache.saveOrdersAsBuyer(any()));
    });

    test('buyer success → caches to buyer key', () async {
      when(() => remote.listOrders(any())).thenAnswer(
            (_) async => [TestData.order(id: 1)],
      );

      await build().listOrders(const ListOrdersParams(role: 'buyer'));

      verify(() => cache.saveOrdersAsBuyer(any())).called(1);
      verifyNever(() => cache.saveOrdersAsSeller(any()));
    });

    test('failure + cache hit → returns cached', () async {
      when(() => remote.listOrders(any()))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readOrdersAsSeller())
          .thenReturn([TestData.orderJson(id: 9)]);

      final result = await build().listOrders(
        const ListOrdersParams(role: 'seller'),
      );

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.first.id, 9));
    });

    test('filtered status → no cache write', () async {
      when(() => remote.listOrders(any())).thenAnswer(
            (_) async => [TestData.order(id: 1, status: OrderStatus.pending)],
      );

      await build().listOrders(const ListOrdersParams(
        role: 'seller',
        status: OrderStatus.pending,
      ),);

      verifyNever(() => cache.saveOrdersAsSeller(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('mutations invalidate cache', () {
    test('createOrder → invalidateOrders', () async {
      when(() => remote.createOrder(any(), any()))
          .thenAnswer((_) async => TestData.order(id: 1));

      await build().createOrder(1, 'msg');

      verify(() => cache.invalidateOrders()).called(1);
    });

    test('approveOrder → invalidateOrders', () async {
      when(() => remote.approveOrder(any()))
          .thenAnswer((_) async => TestData.order(id: 1));

      await build().approveOrder(1);

      verify(() => cache.invalidateOrders()).called(1);
    });

    test('rejectOrder → invalidateOrders', () async {
      when(() => remote.rejectOrder(any()))
          .thenAnswer((_) async => TestData.order(id: 1));

      await build().rejectOrder(1);

      verify(() => cache.invalidateOrders()).called(1);
    });

    test('completeOrder → invalidateOrders', () async {
      when(() => remote.completeOrder(any()))
          .thenAnswer((_) async => TestData.order(id: 1));

      await build().completeOrder(1);

      verify(() => cache.invalidateOrders()).called(1);
    });

    test('cancelOrder → invalidateOrders', () async {
      when(() => remote.cancelOrder(any())).thenAnswer((_) async {});

      await build().cancelOrder(1);

      verify(() => cache.invalidateOrders()).called(1);
    });
  });
}