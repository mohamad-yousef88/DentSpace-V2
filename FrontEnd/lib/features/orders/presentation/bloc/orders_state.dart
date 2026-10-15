import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';

enum OrdersStatus { idle, loading, loaded, submitting, failure }

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.idle,
    this.orders = const [],
    this.currentOrder,
    this.currentRole = 'seller',
    this.currentStatusFilter,
    this.errorMessage,
    this.successMessage,
    this.viewingHidden = false,
  });

  final OrdersStatus status;
  final List<Order> orders;
  final Order? currentOrder;
  final String currentRole;
  final OrderStatus? currentStatusFilter;
  final String? errorMessage;
  final String? successMessage;
  /// `true` when the state holds the hidden-orders view.
  final bool viewingHidden;

  bool get isLoading => status == OrdersStatus.loading;
  bool get isSubmitting => status == OrdersStatus.submitting;

  OrdersState copyWith({
    OrdersStatus? status,
    List<Order>? orders,
    Order? currentOrder,
    String? currentRole,
    OrderStatus? currentStatusFilter,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCurrentOrder = false,
    bool clearStatusFilter = false,
    bool? viewingHidden,

  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      currentOrder:
      clearCurrentOrder ? null : (currentOrder ?? this.currentOrder),
      currentRole: currentRole ?? this.currentRole,
      currentStatusFilter: clearStatusFilter
          ? null
          : (currentStatusFilter ?? this.currentStatusFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
      clearSuccess ? null : (successMessage ?? this.successMessage),
      viewingHidden: viewingHidden ?? this.viewingHidden,
    );
  }

  @override
  List<Object?> get props => [
    status,
    orders,
    currentOrder,
    currentRole,
    currentStatusFilter,
    errorMessage,
    successMessage,
    viewingHidden,
  ];
}