import 'package:dartz/dartz.dart' hide Order;
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/order.dart';

// ═══════════════════════════════════════════════════════════════
// Parameter objects
// ═══════════════════════════════════════════════════════════════
class ListOrdersParams extends Equatable {
  const ListOrdersParams({
    this.role = 'seller',
    this.status,
    this.offset = 0,
    this.limit = 20,
  });

  /// 'seller' (incoming) or 'buyer' (my purchases).
  final String role;
  final OrderStatus? status;
  final int offset;
  final int limit;

  @override
  List<Object?> get props => [role, status, offset, limit];
}

class CreateOrderParams extends Equatable {
  const CreateOrderParams({required this.toolId, this.message});

  final int toolId;
  final String? message;

  @override
  List<Object?> get props => [toolId, message];
}

// ═══════════════════════════════════════════════════════════════
// Repository interface
// ═══════════════════════════════════════════════════════════════
abstract class OrdersRepository {
  Future<Either<Failure, List<Order>>> listOrders(ListOrdersParams params);

  Future<Either<Failure, Order>> getOrder(int id);

  Future<Either<Failure, Order>> createOrder(int toolId, String? message);

  Future<Either<Failure, Order>> approveOrder(int id);

  Future<Either<Failure, Order>> rejectOrder(int id);

  Future<Either<Failure, Order>> completeOrder(int id);

  Future<Either<Failure, void>> cancelOrder(int id);
}