import 'package:dentspace/core/error/exceptions.dart';
import 'package:dentspace/features/tools/data/repositories/tools_repository_impl.dart';
import 'package:dentspace/features/tools/domain/repositories/tools_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_mocks.dart';

void main() {
  late MockToolsRemoteDataSource remote;
  late MockCacheService cache;

  setUpAll(registerFallbackValues);

  setUp(() {
    remote = MockToolsRemoteDataSource();
    cache = MockCacheService();

    // Default no-op cache writes (override per test).
    when(() => cache.saveToolsList(any())).thenAnswer((_) async {});
    when(() => cache.saveMyTools(any())).thenAnswer((_) async {});
    when(() => cache.saveToolDetail(any(), any()))
        .thenAnswer((_) async {});
    when(() => cache.invalidateTools()).thenAnswer((_) async {});
  });

  ToolsRepositoryImpl build() => ToolsRepositoryImpl(remote, cache);

  // ═══════════════════════════════════════════════════════════════
  group('listTools', () {
    test('market success → caches + returns', () async {
      final items = [TestData.tool(id: 1), TestData.tool(id: 2)];
      when(() => remote.listTools(any()))
          .thenAnswer((_) async => items);

      final result = await build().listTools(
        const ToolListParams(mine: false),
      );

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.length, 2));
      verify(() => cache.saveToolsList(any())).called(1);
    });

    test('market failure → falls back to cache', () async {
      when(() => remote.listTools(any()))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readToolsList()).thenReturn([
        TestData.toolJson(id: 5),
      ]);

      final result = await build().listTools(
        const ToolListParams(mine: false),
      );

      expect(result.isRight(), isTrue);
      result.fold(
            (_) => fail('expected cached data'),
            (list) => expect(list.first.id, 5),
      );
    });

    test('market failure + no cache → Left(failure)', () async {
      when(() => remote.listTools(any()))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readToolsList()).thenReturn(null);

      final result = await build().listTools(
        const ToolListParams(mine: false),
      );

      expect(result.isLeft(), isTrue);
    });

    test('filtered search → does NOT cache', () async {
      when(() => remote.listTools(any()))
          .thenAnswer((_) async => [TestData.tool(id: 1)]);

      await build().listTools(
        const ToolListParams(mine: false, search: 'mirror'),
      );

      verifyNever(() => cache.saveToolsList(any()));
    });

    test('mine=true → writes to myTools cache', () async {
      when(() => remote.listTools(any()))
          .thenAnswer((_) async => [TestData.tool(id: 1)]);

      await build().listTools(const ToolListParams(mine: true));

      verify(() => cache.saveMyTools(any())).called(1);
      verifyNever(() => cache.saveToolsList(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('getTool', () {
    test('success → caches detail', () async {
      when(() => remote.getTool(1))
          .thenAnswer((_) async => TestData.tool(id: 1));

      final result = await build().getTool(1);

      expect(result.isRight(), isTrue);
      verify(() => cache.saveToolDetail(1, any())).called(1);
    });

    test('failure → falls back to cached detail', () async {
      when(() => remote.getTool(1))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readToolDetail(1))
          .thenReturn(TestData.toolJson(id: 1));

      final result = await build().getTool(1);

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (t) => expect(t.id, 1));
    });

    test('failure + no cache → Left', () async {
      when(() => remote.getTool(1))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readToolDetail(1)).thenReturn(null);

      final result = await build().getTool(1);
      expect(result.isLeft(), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('mutations invalidate cache', () {
    test('create → invalidateTools called', () async {
      when(() => remote.createTool(any()))
          .thenAnswer((_) async => TestData.tool(id: 1));

      await build().createTool(const CreateToolParams(
        name: 'x',
        description: 'xxxxx',
        category: 'diagnostic',
        condition: 'new',
        price: 1,
      ),);

      verify(() => cache.invalidateTools()).called(1);
    });

    test('update → invalidateTools called', () async {
      when(() => remote.updateTool(any(), any()))
          .thenAnswer((_) async => TestData.tool(id: 1));

      await build().updateTool(1, const UpdateToolParams(name: 'new'));

      verify(() => cache.invalidateTools()).called(1);
    });

    test('delete → invalidateTools called', () async {
      when(() => remote.deleteTool(any())).thenAnswer((_) async {});

      await build().deleteTool(1);

      verify(() => cache.invalidateTools()).called(1);
    });

    test('uploadImage → invalidateTools called', () async {
      when(() => remote.uploadImage(any(), any()))
          .thenAnswer((_) async => TestData.tool(id: 1, imageCount: 1));

      await build().uploadImage(1, '/p.jpg');

      verify(() => cache.invalidateTools()).called(1);
    });

    test('deleteImage → invalidateTools called', () async {
      when(() => remote.deleteImage(any(), any()))
          .thenAnswer((_) async => TestData.tool(id: 1));

      await build().deleteImage(1, 0);

      verify(() => cache.invalidateTools()).called(1);
    });
  });
}