import 'package:equatable/equatable.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationsEvent {
  const LoadNotificationsEvent();
}

class MarkNotificationReadEvent extends NotificationsEvent {
  const MarkNotificationReadEvent(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsReadEvent extends NotificationsEvent {
  const MarkAllNotificationsReadEvent();
}

class DeleteNotificationEvent extends NotificationsEvent {
  const DeleteNotificationEvent(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

class DeleteReadNotificationsEvent extends NotificationsEvent {
  const DeleteReadNotificationsEvent();
}