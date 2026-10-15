import 'package:equatable/equatable.dart';

import '../../domain/entities/app_notification.dart';

enum NotificationsStatus { idle, loading, loaded, submitting, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.idle,
    this.items = const [],
    this.errorMessage,
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final String? errorMessage;

  int get unreadCount => items.where((n) => !n.isRead).length;
  bool get isLoading => status == NotificationsStatus.loading;
  bool get isSubmitting => status == NotificationsStatus.submitting;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}