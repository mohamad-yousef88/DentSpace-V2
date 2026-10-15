import 'package:dentspace/core/error/exceptions.dart';
import 'package:dentspace/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_mocks.dart';

void main() {
  late MockNotificationsRemoteDataSource remote;
  late MockCacheService cache;

  setUpAll(registerFallbackValues);

  setUp(() {
    remote = MockNotificationsRemoteDataSource();
    cache = MockCacheService();
    when(() => cache.saveNotifications(any())).thenAnswer((_) async {});
    when(() => cache.invalidateNotifications()).thenAnswer((_) async {});
  });

  NotificationsRepositoryImpl build() =>
      NotificationsRepositoryImpl(remote, cache);

  // ═══════════════════════════════════════════════════════════════
  group('list', () {
    test('success → caches + returns list', () async {
      when(() => remote.list()).thenAnswer(
            (_) async => [
          TestData.notification(id: 1),
          TestData.notification(id: 2, isRead: true),
        ],
      );

      final result = await build().list();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.length, 2));
      verify(() => cache.saveNotifications(any())).called(1);
    });

    test('failure + cache → returns cached', () async {
      when(() => remote.list())
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readNotifications())
          .thenReturn([TestData.notificationJson(id: 9)]);

      final result = await build().list();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.first.id, 9));
    });

    test('failure + no cache → Left', () async {
      when(() => remote.list())
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readNotifications()).thenReturn(null);

      final result = await build().list();
      expect(result.isLeft(), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('mutations invalidate cache', () {
    test('markRead', () async {
      when(() => remote.markRead(any())).thenAnswer((_) async {});

      await build().markRead(1);

      verify(() => cache.invalidateNotifications()).called(1);
    });

    test('markAllRead returns count', () async {
      when(() => remote.markAllRead()).thenAnswer((_) async => 5);

      final result = await build().markAllRead();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (n) => expect(n, 5));
      verify(() => cache.invalidateNotifications()).called(1);
    });

    test('delete', () async {
      when(() => remote.delete(any())).thenAnswer((_) async {});

      await build().delete(1);

      verify(() => cache.invalidateNotifications()).called(1);
    });

    test('deleteRead returns count', () async {
      when(() => remote.deleteRead()).thenAnswer((_) async => 3);

      final result = await build().deleteRead();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (n) => expect(n, 3));
      verify(() => cache.invalidateNotifications()).called(1);
    });
  });
}
