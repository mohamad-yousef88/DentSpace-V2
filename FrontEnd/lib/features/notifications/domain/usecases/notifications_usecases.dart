import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

class ListNotificationsUseCase
    extends UseCase<List<AppNotification>, NoParams> {
  ListNotificationsUseCase(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, List<AppNotification>>> call(NoParams _) =>
      _repo.list();
}

class MarkNotificationReadUseCase extends UseCase<void, int> {
  MarkNotificationReadUseCase(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, void>> call(int id) => _repo.markRead(id);
}

class MarkAllNotificationsReadUseCase extends UseCase<int, NoParams> {
  MarkAllNotificationsReadUseCase(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, int>> call(NoParams _) => _repo.markAllRead();
}

class DeleteNotificationUseCase extends UseCase<void, int> {
  DeleteNotificationUseCase(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, void>> call(int id) => _repo.delete(id);
}

class DeleteReadNotificationsUseCase extends UseCase<int, NoParams> {
  DeleteReadNotificationsUseCase(this._repo);
  final NotificationsRepository _repo;

  @override
  Future<Either<Failure, int>> call(NoParams _) => _repo.deleteRead();
}