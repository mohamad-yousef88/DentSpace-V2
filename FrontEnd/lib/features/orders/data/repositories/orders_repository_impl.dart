import 'package:dartz/dartz.dart' hide Order;

import '../../../../core/cache/cache_service.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._remote, this._cache);

  final OrdersRemoteDataSource _remote;
  final CacheService _cache;

  String _keyFor(ListOrdersParams p) => p.role == 'buyer' ? 'buyer' : 'seller';

  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, List<Order>>> listOrders(
      ListOrdersParams p,
      ) async {
    final cacheRole = _keyFor(p);
    final isDefault = p.status == null && p.offset == 0;

    try {
      final items = await _remote.listOrders(p);

      if (isDefault) {
        final json = items.map((o) => o.toJson()).toList();
        if (cacheRole == 'buyer') {
          await _cache.saveOrdersAsBuyer(json);
        } else {
          await _cache.saveOrdersAsSeller(json);
        }
      }
      return Right(items);
    } catch (e) {
      if (isDefault) {
        final cached = cacheRole == 'buyer'
            ? _cache.readOrdersAsBuyer()
            : _cache.readOrdersAsSeller();
        if (cached != null) {
          return Right(cached.map(Order.fromJson).toList());
        }
      }
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrder(int id) async {
    try {
      return Right(await _remote.getOrder(id));
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Order>> createOrder(
      int toolId,
      String? message,
      ) async {
    try {
      final order = await _remote.createOrder(toolId, message);
      await _cache.invalidateOrders();
      return Right(order);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Order>> approveOrder(int id) async {
    try {
      final order = await _remote.approveOrder(id);
      await _cache.invalidateOrders();
      return Right(order);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Order>> rejectOrder(int id) async {
    try {
      final order = await _remote.rejectOrder(id);
      await _cache.invalidateOrders();
      return Right(order);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Order>> completeOrder(int id) async {
    try {
      final order = await _remote.completeOrder(id);
      await _cache.invalidateOrders();
      return Right(order);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(int id) async {
    try {
      await _remote.cancelOrder(id);
      await _cache.invalidateOrders();
      return const Right(null);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }
}