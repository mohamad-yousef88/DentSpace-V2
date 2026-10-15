import 'package:equatable/equatable.dart';

import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════
class LoadOrdersEvent extends OrdersEvent {
  const LoadOrdersEvent({
    this.role = 'seller',
    this.status,
  });

  final String role;
  final OrderStatus? status;

  @override
  List<Object?> get props => [role, status];
}

class LoadOrderByIdEvent extends OrdersEvent {
  const LoadOrderByIdEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class CreateOrderEvent extends OrdersEvent {
  const CreateOrderEvent(this.params);
  final CreateOrderParams params;

  @override
  List<Object?> get props => [params];
}

class ApproveOrderEvent extends OrdersEvent {
  const ApproveOrderEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class RejectOrderEvent extends OrdersEvent {
  const RejectOrderEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class CompleteOrderEvent extends OrdersEvent {
  const CompleteOrderEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class CancelOrderEvent extends OrdersEvent {
  const CancelOrderEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class ClearOrderFeedbackEvent extends OrdersEvent {
  const ClearOrderFeedbackEvent();
}
// ═══════════════════════════════════════════════════════════════
// Hide / restore from the local list (no backend mutation).
// ═══════════════════════════════════════════════════════════════
class HideOrderEvent extends OrdersEvent {
  const HideOrderEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class UnhideOrderEvent extends OrdersEvent {
  const UnhideOrderEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

/// Hides every terminal order (completed / rejected / cancelled).
class ClearOrderHistoryEvent extends OrdersEvent {
  const ClearOrderHistoryEvent();
}
/// Loads every hidden order (from both seller + buyer views).
/// Used by the "Hidden History" screen.
class LoadHiddenOrdersEvent extends OrdersEvent {
  const LoadHiddenOrdersEvent();
}