import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<AppNotification>>> list();
  Future<Either<Failure, void>> markRead(int id);
  Future<Either<Failure, int>> markAllRead();
  Future<Either<Failure, void>> delete(int id);
  Future<Either<Failure, int>> deleteRead();
}