import 'dart:io';

import 'package:dentspace/core/cache/cache_service.dart';
import 'package:dentspace/core/cache/hive_cache_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;
  late CacheService cache;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cache_service_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    box = await Hive.openBox<String>(
      'test_${DateTime.now().microsecondsSinceEpoch}',
    );
    cache = CacheService(HiveCacheBox(box));
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  // ═══════════════════════════════════════════════════════════════
  group('user', () {
    test('save + read current user', () async {
      await cache.saveCurrentUser({'id': 1, 'name': 'X'});
      final u = cache.readCurrentUser();
      expect(u!['id'], 1);
      expect(u['name'], 'X');
    });

    test('clearCurrentUser', () async {
      await cache.saveCurrentUser({'id': 1});
      await cache.clearCurrentUser();
      expect(cache.readCurrentUser(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('cases', () {
    test('saveMyCases + readMyCases', () async {
      await cache.saveMyCases([{'id': 1}, {'id': 2}]);
      expect(cache.readMyCases(), hasLength(2));
    });

    test('saveAvailableCases + readAvailableCases', () async {
      await cache.saveAvailableCases([{'id': 3}]);
      expect(cache.readAvailableCases()!.first['id'], 3);
    });

    test('saveCaseDetail + readCaseDetail', () async {
      await cache.saveCaseDetail(42, {'id': 42});
      expect(cache.readCaseDetail(42)!['id'], 42);
    });

    test('invalidateCases clears cases:*', () async {
      await cache.saveMyCases([{'id': 1}]);
      await cache.saveAvailableCases([{'id': 2}]);
      await cache.saveCaseDetail(3, {'id': 3});

      await cache.invalidateCases();

      expect(cache.readMyCases(), isNull);
      expect(cache.readAvailableCases(), isNull);
      expect(cache.readCaseDetail(3), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('appointments', () {
    test('per-status keys are independent', () async {
      await cache.saveAppointmentsList('pending', [{'id': 1}]);
      await cache.saveAppointmentsList('approved', [{'id': 2}]);

      expect(cache.readAppointmentsList('pending')!.first['id'], 1);
      expect(cache.readAppointmentsList('approved')!.first['id'], 2);
    });

    test('doctor stats save + read', () async {
      await cache.saveDoctorStats({
        'active_requests': 1,
        'ongoing_bookings': 2,
        'verified_cases': 3,
      });
      expect(cache.readDoctorStats()!['active_requests'], 1);
    });

    test('invalidateAppointments clears all', () async {
      await cache.saveAppointmentsList('all', [{'id': 1}]);
      await cache.saveDoctorStats({'active_requests': 1});

      await cache.invalidateAppointments();

      expect(cache.readAppointmentsList('all'), isNull);
      expect(cache.readDoctorStats(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('notifications', () {
    test('save + read + invalidate', () async {
      await cache.saveNotifications([{'id': 1}]);
      expect(cache.readNotifications()!.first['id'], 1);

      await cache.invalidateNotifications();
      expect(cache.readNotifications(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('tools', () {
    test('market + mine are independent', () async {
      await cache.saveToolsList([{'id': 1}]);
      await cache.saveMyTools([{'id': 2}]);
      expect(cache.readToolsList()!.first['id'], 1);
      expect(cache.readMyTools()!.first['id'], 2);
    });

    test('tool detail save + read', () async {
      await cache.saveToolDetail(7, {'id': 7});
      expect(cache.readToolDetail(7)!['id'], 7);
    });

    test('invalidateTools clears tools:*', () async {
      await cache.saveToolsList([{'id': 1}]);
      await cache.saveMyTools([{'id': 2}]);
      await cache.saveToolDetail(3, {'id': 3});

      await cache.invalidateTools();

      expect(cache.readToolsList(), isNull);
      expect(cache.readMyTools(), isNull);
      expect(cache.readToolDetail(3), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('orders', () {
    test('buyer / seller lists are independent', () async {
      await cache.saveOrdersAsBuyer([{'id': 1}]);
      await cache.saveOrdersAsSeller([{'id': 2}]);
      expect(cache.readOrdersAsBuyer()!.first['id'], 1);
      expect(cache.readOrdersAsSeller()!.first['id'], 2);
    });

    test('invalidateOrders clears both', () async {
      await cache.saveOrdersAsBuyer([{'id': 1}]);
      await cache.saveOrdersAsSeller([{'id': 2}]);

      await cache.invalidateOrders();

      expect(cache.readOrdersAsBuyer(), isNull);
      expect(cache.readOrdersAsSeller(), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('hidden orders', () {
    test('add + read per role', () async {
      await cache.addHiddenOrderId('seller', 1);
      await cache.addHiddenOrderId('seller', 2);
      await cache.addHiddenOrderId('buyer', 3);

      expect(cache.readHiddenOrderIds('seller'), {1, 2});
      expect(cache.readHiddenOrderIds('buyer'), {3});
    });

    test('removing is idempotent', () async {
      await cache.addHiddenOrderId('seller', 1);
      await cache.removeHiddenOrderId('seller', 1);
      await cache.removeHiddenOrderId('seller', 1);
      expect(cache.readHiddenOrderIds('seller'), isEmpty);
    });

    test('allHiddenOrderIds unions roles', () async {
      await cache.addHiddenOrderId('seller', 1);
      await cache.addHiddenOrderId('buyer', 2);
      expect(cache.allHiddenOrderIds(), {1, 2});
    });

    test('empty when nothing saved', () {
      expect(cache.readHiddenOrderIds('seller'), isEmpty);
      expect(cache.allHiddenOrderIds(), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('clearAll', () {
    test('wipes every key', () async {
      await cache.saveCurrentUser({'id': 1});
      await cache.saveMyCases([{'id': 1}]);
      await cache.saveToolsList([{'id': 1}]);
      await cache.saveOrdersAsBuyer([{'id': 1}]);
      await cache.addHiddenOrderId('seller', 1);

      await cache.clearAll();

      expect(cache.readCurrentUser(), isNull);
      expect(cache.readMyCases(), isNull);
      expect(cache.readToolsList(), isNull);
      expect(cache.readOrdersAsBuyer(), isNull);
      expect(cache.allHiddenOrderIds(), isEmpty);
    });
  });
}