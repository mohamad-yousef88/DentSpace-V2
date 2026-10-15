import 'package:dartz/dartz.dart' hide Order;

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

// ═══════════════════════════════════════════════════════════════
// List
// ═══════════════════════════════════════════════════════════════
class ListOrdersUseCase extends UseCase<List<Order>, ListOrdersParams> {
  ListOrdersUseCase(this._repo);
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, List<Order>>> call(ListOrdersParams params) =>
      _repo.listOrders(params);
}

// ═══════════════════════════════════════════════════════════════
// Get one
// ═══════════════════════════════════════════════════════════════
class GetOrderUseCase extends UseCase<Order, int> {
  GetOrderUseCase(this._repo);
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, Order>> call(int id) => _repo.getOrder(id);
}

// ═══════════════════════════════════════════════════════════════
// Create
// ═══════════════════════════════════════════════════════════════
class CreateOrderUseCase extends UseCase<Order, CreateOrderParams> {
  CreateOrderUseCase(this._repo);
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, Order>> call(CreateOrderParams p) =>
      _repo.createOrder(p.toolId, p.message);
}

// ═══════════════════════════════════════════════════════════════
// Seller actions
// ═══════════════════════════════════════════════════════════════
class ApproveOrderUseCase extends UseCase<Order, int> {
  ApproveOrderUseCase(this._repo);
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, Order>> call(int id) => _repo.approveOrder(id);
}

class RejectOrderUseCase extends UseCase<Order, int> {
  RejectOrderUseCase(this._repo);
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, Order>> call(int id) => _repo.rejectOrder(id);
}

class CompleteOrderUseCase extends UseCase<Order, int> {
  CompleteOrderUseCase(this._repo);
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, Order>> call(int id) => _repo.completeOrder(id);
}

// ═══════════════════════════════════════════════════════════════
// Either party
// ═══════════════════════════════════════════════════════════════
class CancelOrderUseCase extends UseCase<void, int> {
  CancelOrderUseCase(this._repo);
  final OrdersRepository _repo;

  @override
  Future<Either<Failure, void>> call(int id) => _repo.cancelOrder(id);
}