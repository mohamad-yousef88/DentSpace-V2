import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/cache_service.dart';
import '../../domain/entities/order.dart';

import '../../domain/repositories/orders_repository.dart';
import '../../domain/usecases/orders_usecases.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({
    required ListOrdersUseCase listOrders,
    required GetOrderUseCase getOrder,
    required CreateOrderUseCase createOrder,
    required ApproveOrderUseCase approveOrder,
    required RejectOrderUseCase rejectOrder,
    required CompleteOrderUseCase completeOrder,
    required CancelOrderUseCase cancelOrder,
    required CacheService cache,
  })  : _list = listOrders,
        _get = getOrder,
        _create = createOrder,
        _approve = approveOrder,
        _reject = rejectOrder,
        _complete = completeOrder,
        _cancel = cancelOrder,
        _cache = cache,
      super(const OrdersState()) {
    on<LoadOrdersEvent>(_onLoad);
    on<LoadOrderByIdEvent>(_onLoadById);
    on<CreateOrderEvent>(_onCreate);
    on<ApproveOrderEvent>(_onApprove);
    on<RejectOrderEvent>(_onReject);
    on<CompleteOrderEvent>(_onComplete);
    on<CancelOrderEvent>(_onCancel);
    on<ClearOrderFeedbackEvent>(_onClear);
    on<HideOrderEvent>(_onHide);            // ★
    on<UnhideOrderEvent>(_onUnhide);        // ★
    on<ClearOrderHistoryEvent>(_onClearHistory);  // ★
    on<LoadHiddenOrdersEvent>(_onLoadHidden);
  }

  final ListOrdersUseCase _list;
  final GetOrderUseCase _get;
  final CreateOrderUseCase _create;
  final ApproveOrderUseCase _approve;
  final RejectOrderUseCase _reject;
  final CompleteOrderUseCase _complete;
  final CancelOrderUseCase _cancel;
  final CacheService _cache;

  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoad(
      LoadOrdersEvent event,
      Emitter<OrdersState> emit,
      ) async {
    emit(state.copyWith(
      status: OrdersStatus.loading,
      currentRole: event.role,
      currentStatusFilter: event.status,
      viewingHidden: false, // ★ exit hidden view
      clearError: true,
      clearSuccess: true,
    ),);

    final hidden = _cache.readHiddenOrderIds(event.role);

    final result = await _list(ListOrdersParams(
      role: event.role,
      status: event.status,
    ),);

    result.fold(
          (f) => emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: f.message,
      ),),
          (items) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: items.where((o) => !hidden.contains(o.id)).toList(),
      ),),
    );
  }
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoadById(
      LoadOrderByIdEvent event,
      Emitter<OrdersState> emit,
      ) async {
    emit(state.copyWith(
      status: OrdersStatus.loading,
      clearCurrentOrder: true,
      clearError: true,
    ),);

    final result = await _get(event.id);

    result.fold(
          (f) => emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: f.message,
      ),),
          (order) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        currentOrder: order,
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _onCreate(
      CreateOrderEvent event,
      Emitter<OrdersState> emit,
      ) async {
    emit(state.copyWith(
      status: OrdersStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _create(event.params);

    result.fold(
          (f) => emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: f.message,
      ),),
          (order) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: [order, ...state.orders],
        successMessage: 'order_created',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _onApprove(
      ApproveOrderEvent event,
      Emitter<OrdersState> emit,
      ) async {
    emit(state.copyWith(
      status: OrdersStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _approve(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: f.message,
      ),),
          (updated) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: state.orders
            .map((o) => o.id == updated.id ? updated : o)
            .toList(),
        currentOrder:
        state.currentOrder?.id == updated.id ? updated : state.currentOrder,
        successMessage: 'order_approved',
      ),),
    );
  }

  Future<void> _onReject(
      RejectOrderEvent event,
      Emitter<OrdersState> emit,
      ) async {
    emit(state.copyWith(
      status: OrdersStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _reject(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: f.message,
      ),),
          (updated) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: state.orders
            .map((o) => o.id == updated.id ? updated : o)
            .toList(),
        currentOrder:
        state.currentOrder?.id == updated.id ? updated : state.currentOrder,
        successMessage: 'order_rejected',
      ),),
    );
  }

  Future<void> _onComplete(
      CompleteOrderEvent event,
      Emitter<OrdersState> emit,
      ) async {
    emit(state.copyWith(
      status: OrdersStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _complete(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: f.message,
      ),),
          (updated) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: state.orders
            .map((o) => o.id == updated.id ? updated : o)
            .toList(),
        currentOrder:
        state.currentOrder?.id == updated.id ? updated : state.currentOrder,
        successMessage: 'order_completed',
      ),),
    );
  }

  Future<void> _onCancel(
      CancelOrderEvent event,
      Emitter<OrdersState> emit,
      ) async {
    emit(state.copyWith(
      status: OrdersStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);
    final result = await _cancel(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: f.message,
      ),),
          (_) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: state.orders.where((o) => o.id != event.id).toList(),
        clearCurrentOrder: true,
        successMessage: 'order_cancelled',
      ),),
    );
  }

  void _onClear(
      ClearOrderFeedbackEvent event,
      Emitter<OrdersState> emit,
      ) {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
  // ═══════════════════════════════════════════════════════════════
  // Hide / unhide / clear history
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onHide(
      HideOrderEvent event,
      Emitter<OrdersState> emit,
      ) async {
    await _cache.addHiddenOrderId(state.currentRole, event.id);
    emit(state.copyWith(
      orders: state.orders.where((o) => o.id != event.id).toList(),
    ),);
  }
  Future<void> _onUnhide(
      UnhideOrderEvent event,
      Emitter<OrdersState> emit,
      ) async {
    // Remove from BOTH sets — same order cannot be in both roles,
    // but this guarantees consistency.
    await _cache.removeHiddenOrderId('seller', event.id);
    await _cache.removeHiddenOrderId('buyer', event.id);

    if (state.viewingHidden) {
      // We're on the Hidden History screen — remove locally.
      emit(state.copyWith(
        orders: state.orders.where((o) => o.id != event.id).toList(),
      ),);
    } else {
      // We're on the Orders page — refresh the active list.
      add(LoadOrdersEvent(
        role: state.currentRole,
        status: state.currentStatusFilter,
      ),);
    }
  }

  Future<void> _onClearHistory(
      ClearOrderHistoryEvent event,
      Emitter<OrdersState> emit,
      ) async {
    final terminals = state.orders.where((o) => !o.status.isActive).toList();
    for (final o in terminals) {
      await _cache.addHiddenOrderId(state.currentRole, o.id);
    }
    emit(state.copyWith(
      orders: state.orders.where((o) => o.status.isActive).toList(),
    ),);
  }
  // ═══════════════════════════════════════════════════════════════
  // Hidden History — fetch everything, keep only hidden IDs
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoadHidden(
      LoadHiddenOrdersEvent event,
      Emitter<OrdersState> emit,
      ) async {
    emit(state.copyWith(
      status: OrdersStatus.loading,
      viewingHidden: true,
      clearError: true,
      clearSuccess: true,
    ),);

    final hidden = _cache.allHiddenOrderIds();

    // Fetch both roles concurrently (one round-trip each).
    final sellerRes = await _list(const ListOrdersParams(role: 'seller'));
    final buyerRes = await _list(const ListOrdersParams(role: 'buyer'));

    final merged = <int, Order>{};
    sellerRes.fold((_) {}, (items) {
      for (final o in items) {
        if (hidden.contains(o.id)) merged[o.id] = o;
      }
    },);
    buyerRes.fold((_) {}, (items) {
      for (final o in items) {
        if (hidden.contains(o.id)) merged[o.id] = o;
      }
    },);

    final sorted = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    emit(state.copyWith(
      status: OrdersStatus.loaded,
      orders: sorted,
    ),);
  }
}