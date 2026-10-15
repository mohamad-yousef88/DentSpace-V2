import 'package:dartz/dartz.dart' hide Order;
import 'package:dentspace/core/error/failures.dart';
import 'package:dentspace/features/orders/domain/entities/order.dart';
import 'package:dentspace/features/orders/domain/repositories/orders_repository.dart';
import 'package:dentspace/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:dentspace/features/orders/presentation/bloc/orders_event.dart';
import 'package:dentspace/features/orders/presentation/bloc/orders_state.dart';
import 'package:dentspace/features/tools/domain/entities/tool.dart';
import 'package:dentspace/features/tools/domain/repositories/tools_repository.dart';
import 'package:dentspace/features/tools/presentation/bloc/tools_bloc.dart';
import 'package:dentspace/features/tools/presentation/bloc/tools_event.dart';
import 'package:dentspace/features/tools/presentation/bloc/tools_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_data.dart';
import '../helpers/test_mocks.dart';

/// Full lifecycle test — simulates two devices (buyer + seller) with
/// their own BLoC instances. Each "device" loads its own list before
/// acting, exactly like the real app.
void main() {
  late MockListToolsUseCase listTools;
  late MockGetToolUseCase getTool;
  late MockCreateToolUseCase createTool;
  late MockUpdateToolUseCase updateTool;
  late MockDeleteToolUseCase deleteTool;
  late MockUploadToolImageUseCase uploadImage;
  late MockDeleteToolImageUseCase deleteImage;

  late MockListOrdersUseCase listOrders;
  late MockGetOrderUseCase getOrder;
  late MockCreateOrderUseCase createOrder;
  late MockApproveOrderUseCase approveOrder;
  late MockRejectOrderUseCase rejectOrder;
  late MockCompleteOrderUseCase completeOrder;
  late MockCancelOrderUseCase cancelOrder;
  late MockCacheService cache;

  setUpAll(registerFallbackValues);

  setUp(() {
    listTools = MockListToolsUseCase();
    getTool = MockGetToolUseCase();
    createTool = MockCreateToolUseCase();
    updateTool = MockUpdateToolUseCase();
    deleteTool = MockDeleteToolUseCase();
    uploadImage = MockUploadToolImageUseCase();
    deleteImage = MockDeleteToolImageUseCase();

    listOrders = MockListOrdersUseCase();
    getOrder = MockGetOrderUseCase();
    createOrder = MockCreateOrderUseCase();
    approveOrder = MockApproveOrderUseCase();
    rejectOrder = MockRejectOrderUseCase();
    completeOrder = MockCompleteOrderUseCase();
    cancelOrder = MockCancelOrderUseCase();
    cache = MockCacheService();

    when(() => cache.readHiddenOrderIds(any())).thenReturn(<int>{});
    when(() => cache.allHiddenOrderIds()).thenReturn(<int>{});
    when(() => cache.addHiddenOrderId(any(), any()))
        .thenAnswer((_) async {});
    when(() => cache.removeHiddenOrderId(any(), any()))
        .thenAnswer((_) async {});
  });

  ToolsBloc buildTools() => ToolsBloc(
    listTools: listTools,
    getTool: getTool,
    createTool: createTool,
    updateTool: updateTool,
    deleteTool: deleteTool,
    uploadImage: uploadImage,
    deleteImage: deleteImage,
  );

  OrdersBloc buildOrders() => OrdersBloc(
    listOrders: listOrders,
    getOrder: getOrder,
    createOrder: createOrder,
    approveOrder: approveOrder,
    rejectOrder: rejectOrder,
    completeOrder: completeOrder,
    cancelOrder: cancelOrder,
    cache: cache,
  );

  // ─── Wait helpers: subscribe first, then await ────────────
  Future<OrdersState> waitForOrderSuccess(
      OrdersBloc bloc,
      String message,
      ) =>
      bloc.stream
          .firstWhere((s) => s.successMessage == message)
          .timeout(const Duration(seconds: 3));

  Future<ToolsState> waitForToolSuccess(
      ToolsBloc bloc,
      String message,
      ) =>
      bloc.stream
          .firstWhere((s) => s.successMessage == message)
          .timeout(const Duration(seconds: 3));

  // ═══════════════════════════════════════════════════════════════
  test('END-TO-END: tool → order → approve → complete', () async {
    // ─── 1. Seller creates a tool ─────────────────────────────
    when(() => createTool(any())).thenAnswer(
          (_) async => Right<Failure, Tool>(TestData.tool(id: 1)),
    );
    final sellerTools = buildTools();
    addTearDown(sellerTools.close);

    final createFuture =
    waitForToolSuccess(sellerTools, 'tool_created');
    sellerTools.add(const CreateToolEvent(CreateToolParams(
      name: 'Dental Mirror',
      description: 'Quality diagnostic tool',
      category: 'diagnostic',
      condition: 'new',
      price: 45,
    ),),);
    await createFuture;

    // ─── 2. Buyer creates an order ────────────────────────────
    when(() => createOrder(any())).thenAnswer(
          (_) async => Right<Failure, Order>(TestData.order(id: 10)),
    );
    final buyerOrders = buildOrders();
    addTearDown(buyerOrders.close);

    final createOrderFuture =
    waitForOrderSuccess(buyerOrders, 'order_created');
    buyerOrders.add(const CreateOrderEvent(
      CreateOrderParams(toolId: 1, message: 'I need this urgently'),
    ),);
    final createdOrderState = await createOrderFuture;
    expect(createdOrderState.orders, isNotEmpty);
    expect(createdOrderState.orders.first.status, OrderStatus.pending);

    // ─── 3. Seller loads orders, then approves ────────────────
    // ★ Realistic: the seller's list must be loaded BEFORE approving.
    when(() => listOrders(any())).thenAnswer(
          (_) async => Right<Failure, List<Order>>(
        [TestData.order(id: 10, status: OrderStatus.pending)],
      ),
    );
    when(() => approveOrder(any())).thenAnswer(
          (_) async => Right<Failure, Order>(
        TestData.order(id: 10, status: OrderStatus.approved),
      ),
    );

    final sellerOrders = buildOrders();
    addTearDown(sellerOrders.close);

    // Load first
    sellerOrders.add(const LoadOrdersEvent(role: 'seller'));
    await sellerOrders.stream
        .firstWhere((s) => s.status == OrdersStatus.loaded)
        .timeout(const Duration(seconds: 3));

    // Now approve
    final approveFuture =
    waitForOrderSuccess(sellerOrders, 'order_approved');
    sellerOrders.add(const ApproveOrderEvent(10));
    final approvedState = await approveFuture;

    expect(approvedState.orders, isNotEmpty);
    expect(approvedState.orders.first.status, OrderStatus.approved);

    // ─── 4. Seller completes the sale ─────────────────────────
    when(() => completeOrder(any())).thenAnswer(
          (_) async => Right<Failure, Order>(
        TestData.order(id: 10, status: OrderStatus.completed),
      ),
    );

    final completeFuture =
    waitForOrderSuccess(sellerOrders, 'order_completed');
    sellerOrders.add(const CompleteOrderEvent(10));
    final completedState = await completeFuture;

    expect(completedState.orders, isNotEmpty);
    expect(completedState.orders.first.status, OrderStatus.completed);
  });

  // ═══════════════════════════════════════════════════════════════
  test('SELLER rejects → buyer sees rejection', () async {
    when(() => listOrders(any())).thenAnswer(
          (_) async => Right<Failure, List<Order>>(
        [TestData.order(id: 20, status: OrderStatus.pending)],
      ),
    );
    when(() => rejectOrder(any())).thenAnswer(
          (_) async => Right<Failure, Order>(
        TestData.order(id: 20, status: OrderStatus.rejected),
      ),
    );

    final orders = buildOrders();
    addTearDown(orders.close);

    // Load first
    orders.add(const LoadOrdersEvent(role: 'seller'));
    await orders.stream
        .firstWhere((s) => s.status == OrdersStatus.loaded)
        .timeout(const Duration(seconds: 3));

    // Then reject
    final future = waitForOrderSuccess(orders, 'order_rejected');
    orders.add(const RejectOrderEvent(20));
    final state = await future;

    expect(state.orders, isNotEmpty);
    expect(state.orders.first.status, OrderStatus.rejected);
  });

  // ═══════════════════════════════════════════════════════════════
  test('BUYER cancels a pending order', () async {
    when(() => listOrders(any())).thenAnswer(
          (_) async => Right<Failure, List<Order>>(
        [TestData.order(id: 30, status: OrderStatus.pending)],
      ),
    );
    when(() => cancelOrder(any())).thenAnswer(
          (_) async => const Right(null),
    );

    final orders = buildOrders();
    addTearDown(orders.close);

    orders.add(const LoadOrdersEvent(role: 'buyer'));
    await orders.stream
        .firstWhere((s) => s.status == OrdersStatus.loaded)
        .timeout(const Duration(seconds: 3));

    final future = waitForOrderSuccess(orders, 'order_cancelled');
    orders.add(const CancelOrderEvent(30));
    await future;

    expect(orders.state.orders, isEmpty);
  });

  // ═══════════════════════════════════════════════════════════════
  test('HIDE terminal order → persists to cache', () async {
    final orders = buildOrders();
    addTearDown(orders.close);

    orders.add(const HideOrderEvent(40));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    verify(() => cache.addHiddenOrderId(any(), 40)).called(1);
  });
}