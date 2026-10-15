import 'dart:io';

import 'package:dentspace/core/cache/hive_cache_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;
  late HiveCacheBox cache;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cache_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    box = await Hive.openBox<String>(
      'test_${DateTime.now().microsecondsSinceEpoch}',
    );
    cache = HiveCacheBox(box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  // ═══════════════════════════════════════════════════════════════
  group('write + read', () {
    test('round-trips simple values', () async {
      await cache.write('k1', 'hello');
      expect(cache.read('k1'), 'hello');
    });

    test('round-trips integers', () async {
      await cache.write('n', 42);
      expect(cache.read('n'), 42);
    });

    test('round-trips lists of maps', () async {
      await cache.write('list', [
        {'id': 1},
        {'id': 2},
      ]);
      final result = cache.readJsonList('list');
      expect(result, hasLength(2));
      expect(result![0]['id'], 1);
    });

    test('round-trips maps', () async {
      await cache.write('map', {'a': 1, 'b': 'x'});
      final r = cache.readJsonMap('map');
      expect(r!['a'], 1);
      expect(r['b'], 'x');
    });

    test('returns null for missing key', () {
      expect(cache.read('missing'), isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('TTL', () {
    test('returns value within TTL', () async {
      await cache.write('k', 'v');
      expect(
        cache.read('k', ttl: const Duration(seconds: 10)),
        'v',
      );
    });

    test('returns null + purges after TTL expires', () async {
      await cache.write('k', 'v');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(
        cache.read('k', ttl: const Duration(milliseconds: 20)),
        isNull,
      );
      expect(box.containsKey('k'), isFalse);
    });

    test('no TTL → value never expires', () async {
      await cache.write('k', 'v');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(cache.read('k'), 'v');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('corrupt entries', () {
    test('non-JSON string → purged, null', () async {
      await box.put('corrupt', 'not json at all');
      expect(cache.read('corrupt'), isNull);
      expect(box.containsKey('corrupt'), isFalse);
    });

    test('JSON without envelope → purged, null', () async {
      await box.put('bad', '"just a string"');
      expect(cache.read('bad'), isNull);
      expect(box.containsKey('bad'), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('typed readers', () {
    test('readJsonList on non-list → null', () async {
      await cache.write('map', {'a': 1});
      expect(cache.readJsonList('map'), isNull);
    });

    test('readJsonMap on non-map → null', () async {
      await cache.write('list', [1, 2]);
      expect(cache.readJsonMap('list'), isNull);
    });

    test('readJsonList filters out non-map entries', () async {
      await cache.write('mixed', [
        {'id': 1},
        'skip',
        42,
        {'id': 2},
      ]);
      final result = cache.readJsonList('mixed');
      expect(result, hasLength(2));
      expect(result!.map((m) => m['id']), containsAll([1, 2]));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('delete', () {
    test('delete single key', () async {
      await cache.write('a', 1);
      await cache.write('b', 2);
      await cache.delete('a');
      expect(cache.read('a'), isNull);
      expect(cache.read('b'), 2);
    });

    test('deleteByPrefix removes all matching', () async {
      await cache.write('tools:1', 1);
      await cache.write('tools:2', 2);
      await cache.write('orders:1', 3);

      await cache.deleteByPrefix('tools:');

      expect(cache.read('tools:1'), isNull);
      expect(cache.read('tools:2'), isNull);
      expect(cache.read('orders:1'), 3);
    });

    test('deleteByPrefix with no match → no-op', () async {
      await cache.write('a', 1);
      await cache.deleteByPrefix('nope:');
      expect(cache.read('a'), 1);
    });

    test('clear removes everything', () async {
      await cache.write('a', 1);
      await cache.write('b', 2);
      await cache.clear();
      expect(cache.read('a'), isNull);
      expect(cache.read('b'), isNull);
    });
  });
}