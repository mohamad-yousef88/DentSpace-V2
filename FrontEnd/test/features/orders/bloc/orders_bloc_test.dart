import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dentspace/core/error/failures.dart';
import 'package:dentspace/features/orders/domain/entities/order.dart';
import 'package:dentspace/features/orders/domain/repositories/orders_repository.dart';
import 'package:dentspace/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:dentspace/features/orders/presentation/bloc/orders_event.dart';
import 'package:dentspace/features/orders/presentation/bloc/orders_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_data.dart';
import '../../../helpers/test_mocks.dart';

void main() {
  late MockListOrdersUseCase list;
  late MockGetOrderUseCase get;
  late MockCreateOrderUseCase create;
  late MockApproveOrderUseCase approve;
  late MockRejectOrderUseCase reject;
  late MockCompleteOrderUseCase complete;
  late MockCancelOrderUseCase cancel;
  late MockCacheService cache;

  setUpAll(registerFallbackValues);

  setUp(() {
    list = MockListOrdersUseCase();
    get = MockGetOrderUseCase();
    create = MockCreateOrderUseCase();
    approve = MockApproveOrderUseCase();
    reject = MockRejectOrderUseCase();
    complete = MockCompleteOrderUseCase();
    cancel = MockCancelOrderUseCase();
    cache = MockCacheService();

    // Default: no hidden IDs → list passes through untouched.
    when(() => cache.readHiddenOrderIds(any())).thenReturn(<int>{});
    when(() => cache.allHiddenOrderIds()).thenReturn(<int>{});
    when(() => cache.addHiddenOrderId(any(), any()))
        .thenAnswer((_) async {});
    when(() => cache.removeHiddenOrderId(any(), any()))
        .thenAnswer((_) async {});
  });

  OrdersBloc build() => OrdersBloc(
    listOrders: list,
    getOrder: get,
    createOrder: create,
    approveOrder: approve,
    rejectOrder: reject,
    completeOrder: complete,
    cancelOrder: cancel,
    cache: cache,
  );

  // ═══════════════════════════════════════════════════════════
  group('LoadOrdersEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'emits [loading, loaded] with items',
      setUp: () {
        when(() => list(any())).thenAnswer(
              (_) async => Right<Failure, List<Order>>([
            TestData.order(id: 1),
            TestData.order(id: 2),
          ]),
        );
      },
      build: build,
      act: (b) => b.add(const LoadOrdersEvent(role: 'seller')),
      expect: () => [
        isA<OrdersState>().having((s) => s.status, 's', OrdersStatus.loading),
        isA<OrdersState>()
            .having((s) => s.status, 's', OrdersStatus.loaded)
            .having((s) => s.orders.length, 'len', 2),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'filters out hidden IDs',
      setUp: () {
        when(() => cache.readHiddenOrderIds('seller'))
            .thenReturn(<int>{1});
        when(() => list(any())).thenAnswer(
              (_) async => Right<Failure, List<Order>>([
            TestData.order(id: 1),
            TestData.order(id: 2),
          ]),
        );
      },
      build: build,
      act: (b) => b.add(const LoadOrdersEvent(role: 'seller')),
      expect: () => [
        isA<OrdersState>().having((s) => s.status, 's', OrdersStatus.loading),
        isA<OrdersState>()
            .having((s) => s.status, 's', OrdersStatus.loaded)
            .having((s) => s.orders.length, 'len', 1)
            .having((s) => s.orders.first.id, 'id', 2),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('ApproveOrderEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'updates the order status and emits success',
      setUp: () {
        when(() => approve(any())).thenAnswer(
              (_) async => Right<Failure, Order>(
            TestData.order(id: 1, status: OrderStatus.approved),
          ),
        );
      },
      seed: () => OrdersState(
        status: OrdersStatus.loaded,
        orders: [TestData.order(id: 1)],
      ),
      build: build,
      act: (b) => b.add(const ApproveOrderEvent(1)),
      expect: () => [
        isA<OrdersState>()
            .having((s) => s.status, 's', OrdersStatus.submitting),
        isA<OrdersState>()
            .having(
              (s) => s.orders.first.status,
          'status',
          OrderStatus.approved,
        )
            .having((s) => s.successMessage, 'ok', 'order_approved'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('RejectOrderEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'emits order_rejected',
      setUp: () {
        when(() => reject(any())).thenAnswer(
              (_) async => Right<Failure, Order>(
            TestData.order(id: 1, status: OrderStatus.rejected),
          ),
        );
      },
      seed: () => OrdersState(
        status: OrdersStatus.loaded,
        orders: [TestData.order(id: 1)],
      ),
      build: build,
      act: (b) => b.add(const RejectOrderEvent(1)),
      expect: () => [
        isA<OrdersState>()
            .having((s) => s.status, 's', OrdersStatus.submitting),
        isA<OrdersState>()
            .having((s) => s.successMessage, 'ok', 'order_rejected'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('CompleteOrderEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'emits order_completed',
      setUp: () {
        when(() => complete(any())).thenAnswer(
              (_) async => Right<Failure, Order>(
            TestData.order(id: 1, status: OrderStatus.completed),
          ),
        );
      },
      seed: () => OrdersState(
        status: OrdersStatus.loaded,
        orders: [TestData.order(id: 1, status: OrderStatus.approved)],
      ),
      build: build,
      act: (b) => b.add(const CompleteOrderEvent(1)),
      expect: () => [
        isA<OrdersState>()
            .having((s) => s.status, 's', OrdersStatus.submitting),
        isA<OrdersState>()
            .having((s) => s.successMessage, 'ok', 'order_completed'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('CancelOrderEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'removes the order from the list',
      setUp: () {
        when(() => cancel(any()))
            .thenAnswer((_) async => const Right(null));
      },
      seed: () => OrdersState(
        status: OrdersStatus.loaded,
        orders: [
          TestData.order(id: 1),
          TestData.order(id: 2),
        ],
      ),
      build: build,
      act: (b) => b.add(const CancelOrderEvent(1)),
      expect: () => [
        isA<OrdersState>()
            .having((s) => s.status, 's', OrdersStatus.submitting),
        isA<OrdersState>()
            .having((s) => s.orders.length, 'len', 1)
            .having((s) => s.orders.first.id, 'id', 2)
            .having((s) => s.successMessage, 'ok', 'order_cancelled'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('HideOrderEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'persists to cache and removes from list',
      seed: () => OrdersState(
        status: OrdersStatus.loaded,
        orders: [TestData.order(id: 5)],
        currentRole: 'seller',
      ),
      build: build,
      act: (b) => b.add(const HideOrderEvent(5)),
      verify: (_) {
        verify(() => cache.addHiddenOrderId('seller', 5)).called(1);
      },
      expect: () => [
        isA<OrdersState>().having((s) => s.orders, 'orders', isEmpty),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('ClearOrderHistoryEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'hides all terminal orders, keeps active ones',
      seed: () => OrdersState(
        status: OrdersStatus.loaded,
        currentRole: 'seller',
        orders: [
          TestData.order(id: 1, status: OrderStatus.pending),
          TestData.order(id: 2, status: OrderStatus.completed),
          TestData.order(id: 3, status: OrderStatus.rejected),
        ],
      ),
      build: build,
      act: (b) => b.add(const ClearOrderHistoryEvent()),
      verify: (_) {
        verify(() => cache.addHiddenOrderId('seller', 2)).called(1);
        verify(() => cache.addHiddenOrderId('seller', 3)).called(1);
        verifyNever(() => cache.addHiddenOrderId('seller', 1));
      },
      expect: () => [
        isA<OrdersState>()
            .having((s) => s.orders.length, 'len', 1)
            .having((s) => s.orders.first.id, 'id', 1),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('CreateOrderEvent', () {
    blocTest<OrdersBloc, OrdersState>(
      'prepends the new order',
      setUp: () {
        when(() => create(any())).thenAnswer(
              (_) async => Right<Failure, Order>(TestData.order(id: 99)),
        );
      },
      build: build,
      act: (b) => b.add(const CreateOrderEvent(
        CreateOrderParams(toolId: 5),
      ),),
      expect: () => [
        isA<OrdersState>()
            .having((s) => s.status, 's', OrdersStatus.submitting),
        isA<OrdersState>()
            .having((s) => s.orders.first.id, 'id', 99)
            .having((s) => s.successMessage, 'ok', 'order_created'),
      ],
    );
  });
}