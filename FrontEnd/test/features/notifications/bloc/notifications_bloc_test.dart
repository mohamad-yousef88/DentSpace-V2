import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dentspace/core/error/failures.dart';
import 'package:dentspace/features/notifications/domain/entities/app_notification.dart';
import 'package:dentspace/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:dentspace/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:dentspace/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_data.dart';
import '../../../helpers/test_mocks.dart';

void main() {
  late MockListNotificationsUseCase list;
  late MockMarkNotificationReadUseCase markRead;
  late MockMarkAllNotificationsReadUseCase markAllRead;
  late MockDeleteNotificationUseCase deleteOne;
  late MockDeleteReadNotificationsUseCase deleteRead;

  setUpAll(registerFallbackValues);

  setUp(() {
    list = MockListNotificationsUseCase();
    markRead = MockMarkNotificationReadUseCase();
    markAllRead = MockMarkAllNotificationsReadUseCase();
    deleteOne = MockDeleteNotificationUseCase();
    deleteRead = MockDeleteReadNotificationsUseCase();
  });

  NotificationsBloc build() => NotificationsBloc(
    listNotifications: list,
    markRead: markRead,
    markAllRead: markAllRead,
    deleteOne: deleteOne,
    deleteRead: deleteRead,
  );

  group('LoadNotificationsEvent', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'loads list',
      setUp: () {
        when(() => list(any())).thenAnswer(
              (_) async => Right<Failure, List<AppNotification>>([
            TestData.notification(id: 1),
            TestData.notification(id: 2, isRead: true),
          ]),
        );
      },
      build: build,
      act: (b) => b.add(const LoadNotificationsEvent()),
      expect: () => [
        isA<NotificationsState>()
            .having((s) => s.status, 's', NotificationsStatus.loading),
        isA<NotificationsState>()
            .having((s) => s.items.length, 'len', 2)
            .having((s) => s.unreadCount, 'unread', 1),
      ],
    );
  });

  group('MarkNotificationReadEvent', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'sets isRead to true for the target',
      setUp: () {
        when(() => markRead(any()))
            .thenAnswer((_) async => const Right(null));
      },
      seed: () => NotificationsState(
        status: NotificationsStatus.loaded,
        items: [
          TestData.notification(id: 1, isRead: false),
          TestData.notification(id: 2, isRead: false),
        ],
      ),
      build: build,
      act: (b) => b.add(const MarkNotificationReadEvent(1)),
      expect: () => [
        isA<NotificationsState>()
            .having((s) => s.items.first.isRead, 'first', isTrue)
            .having((s) => s.items.last.isRead, 'last', isFalse),
      ],
    );
  });

  group('DeleteNotificationEvent', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'removes the item',
      setUp: () {
        when(() => deleteOne(any()))
            .thenAnswer((_) async => const Right(null));
      },
      seed: () => NotificationsState(
        status: NotificationsStatus.loaded,
        items: [
          TestData.notification(id: 1),
          TestData.notification(id: 2),
        ],
      ),
      build: build,
      act: (b) => b.add(const DeleteNotificationEvent(1)),
      expect: () => [
        isA<NotificationsState>()
            .having((s) => s.items.length, 'len', 1)
            .having((s) => s.items.first.id, 'id', 2),
      ],
    );
  });
}