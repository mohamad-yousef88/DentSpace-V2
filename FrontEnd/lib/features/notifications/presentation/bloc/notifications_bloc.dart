import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/notifications_usecases.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc
    extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required ListNotificationsUseCase listNotifications,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
    required DeleteNotificationUseCase deleteOne,
    required DeleteReadNotificationsUseCase deleteRead,
  })  : _list = listNotifications,
        _markRead = markRead,
        _markAllRead = markAllRead,
        _deleteOne = deleteOne,
        _deleteRead = deleteRead,
        super(const NotificationsState()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<MarkNotificationReadEvent>(_onMarkRead);
    on<MarkAllNotificationsReadEvent>(_onMarkAllRead);
    on<DeleteNotificationEvent>(_onDelete);
    on<DeleteReadNotificationsEvent>(_onDeleteRead);
  }

  final ListNotificationsUseCase _list;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final DeleteNotificationUseCase _deleteOne;
  final DeleteReadNotificationsUseCase _deleteRead;

  Future<void> _onLoad(
      LoadNotificationsEvent event,
      Emitter<NotificationsState> emit,
      ) async {
    emit(state.copyWith(
      status: NotificationsStatus.loading,
      clearError: true,
    ),);
    final result = await _list(const NoParams());
    result.fold(
          (f) => emit(state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: f.message,
      ),),
          (items) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: items,
      ),),
    );
  }

  Future<void> _onMarkRead(
      MarkNotificationReadEvent event,
      Emitter<NotificationsState> emit,
      ) async {
    final result = await _markRead(event.id);
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (_) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: state.items
            .map((n) => n.id == event.id ? n.copyWith(isRead: true) : n)
            .toList(),
      ),),
    );
  }

  Future<void> _onMarkAllRead(
      MarkAllNotificationsReadEvent event,
      Emitter<NotificationsState> emit,
      ) async {
    final result = await _markAllRead(const NoParams());
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (_) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
      ),),
    );
  }

  Future<void> _onDelete(
      DeleteNotificationEvent event,
      Emitter<NotificationsState> emit,
      ) async {
    final result = await _deleteOne(event.id);
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (_) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: state.items.where((n) => n.id != event.id).toList(),
      ),),
    );
  }

  Future<void> _onDeleteRead(
      DeleteReadNotificationsEvent event,
      Emitter<NotificationsState> emit,
      ) async {
    final result = await _deleteRead(const NoParams());
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (_) => emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: state.items.where((n) => !n.isRead).toList(),
      ),),
    );
  }
}