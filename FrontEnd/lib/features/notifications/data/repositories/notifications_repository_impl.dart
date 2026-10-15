import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_service.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote, this._cache);

  final NotificationsRemoteDataSource _remote;
  final CacheService _cache;

  // ═══════════════════════════════════════════════════════
  // List — cache-aside
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, List<AppNotification>>> list() async {
    try {
      final items = await _remote.list();
      await _cache.saveNotifications(
        items.map((n) => n.toJson()).toList(),
      );
      return Right(items);
    } catch (e) {
      final cached = _cache.readNotifications();
      if (cached != null) {
        return Right(cached.map(AppNotification.fromJson).toList());
      }
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Mark read
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, void>> markRead(int id) async {
    try {
      await _remote.markRead(id);
      await _cache.invalidateNotifications();
      return const Right(null);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Mark all read — backend returns the affected count
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, int>> markAllRead() async {
    try {
      final count = await _remote.markAllRead();
      await _cache.invalidateNotifications();
      return Right(count);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Delete one — datasource method is `delete`
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, void>> delete(int id) async {
    try {
      await _remote.delete(id);
      await _cache.invalidateNotifications();
      return const Right(null);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Delete read — backend returns the affected count
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, int>> deleteRead() async {
    try {
      final count = await _remote.deleteRead();
      await _cache.invalidateNotifications();
      return Right(count);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }
}