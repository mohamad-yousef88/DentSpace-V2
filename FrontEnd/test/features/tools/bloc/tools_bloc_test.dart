import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dentspace/core/error/failures.dart';
import 'package:dentspace/features/tools/domain/entities/tool.dart';
import 'package:dentspace/features/tools/domain/repositories/tools_repository.dart';
import 'package:dentspace/features/tools/presentation/bloc/tools_bloc.dart';
import 'package:dentspace/features/tools/presentation/bloc/tools_event.dart';
import 'package:dentspace/features/tools/presentation/bloc/tools_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_data.dart';
import '../../../helpers/test_mocks.dart';

void main() {
  late MockListToolsUseCase list;
  late MockGetToolUseCase get;
  late MockCreateToolUseCase create;
  late MockUpdateToolUseCase update;
  late MockDeleteToolUseCase delete;
  late MockUploadToolImageUseCase upload;
  late MockDeleteToolImageUseCase deleteImage;

  setUpAll(registerFallbackValues);

  setUp(() {
    list = MockListToolsUseCase();
    get = MockGetToolUseCase();
    create = MockCreateToolUseCase();
    update = MockUpdateToolUseCase();
    delete = MockDeleteToolUseCase();
    upload = MockUploadToolImageUseCase();
    deleteImage = MockDeleteToolImageUseCase();
  });

  ToolsBloc build() =>
      ToolsBloc(
        listTools: list,
        getTool: get,
        createTool: create,
        updateTool: update,
        deleteTool: delete,
        uploadImage: upload,
        deleteImage: deleteImage,
      );

  // ═══════════════════════════════════════════════════════════
  group('LoadMarketToolsEvent', () {
    blocTest<ToolsBloc, ToolsState>(
      'emits [loading, loaded] on success',
      setUp: () {
        when(() => list(any())).thenAnswer(
              (_) async => Right([TestData.tool(id: 1), TestData.tool(id: 2)]),
        );
      },
      build: build,
      act: (b) => b.add(const LoadMarketToolsEvent()),
      expect: () =>
      [
        isA<ToolsState>()
            .having((s) => s.status, 'status', ToolsStatus.loading)
            .having((s) => s.viewMode, 'viewMode', ToolsViewMode.market),
        isA<ToolsState>()
            .having((s) => s.status, 'status', ToolsStatus.loaded)
            .having((s) => s.tools.length, 'len', 2),
      ],
    );

    blocTest<ToolsBloc, ToolsState>(
      'emits [loading, failure] on error',
      setUp: () {
        when(() => list(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'boom')),
        );
      },
      build: build,
      act: (b) => b.add(const LoadMarketToolsEvent()),
      expect: () =>
      [
        isA<ToolsState>().having((s) => s.status, 's', ToolsStatus.loading),
        isA<ToolsState>()
            .having((s) => s.status, 's', ToolsStatus.failure)
            .having((s) => s.errorMessage, 'err', 'boom'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('LoadMyToolsEvent', () {
    blocTest<ToolsBloc, ToolsState>(
      'sets viewMode to mine',
      setUp: () {
        when(() => list(any())).thenAnswer(
              (_) async => Right([TestData.tool()]),
        );
      },
      build: build,
      act: (b) => b.add(const LoadMyToolsEvent()),
      expect: () =>
      [
        isA<ToolsState>()
            .having((s) => s.status, 's', ToolsStatus.loading)
            .having((s) => s.viewMode, 'v', ToolsViewMode.mine),
        isA<ToolsState>()
            .having((s) => s.status, 's', ToolsStatus.loaded),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('CreateToolEvent', () {
    blocTest<ToolsBloc, ToolsState>(
      'prepends the new tool and emits success',
      setUp: () {
        when(() => create(any())).thenAnswer(
              (_) async => Right(TestData.tool(id: 99)),
        );
      },
      build: build,
      act: (b) =>
          b.add(const CreateToolEvent(
            CreateToolParams(
              name: 'New',
              description: 'xxxxx',
              category: 'diagnostic',
              condition: 'new',
              price: 10,
            ),
          ),),
      expect: () =>
      [
        isA<ToolsState>()
            .having((s) => s.status, 's', ToolsStatus.submitting),
        isA<ToolsState>()
            .having((s) => s.tools.first.id, 'id', 99)
            .having((s) => s.successMessage, 'success', 'tool_created'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('DeleteToolEvent', () {
    blocTest<ToolsBloc, ToolsState>(
      'removes the tool from the list',
      setUp: () {
        when(() => delete(any())).thenAnswer((_) async => const Right(null));
      },
      seed: () =>
          ToolsState(
            status: ToolsStatus.loaded,
            tools: [TestData.tool(id: 1), TestData.tool(id: 2)],
          ),
      build: build,
      act: (b) => b.add(const DeleteToolEvent(1)),
      expect: () =>
      [
        isA<ToolsState>()
            .having((s) => s.status, 's', ToolsStatus.submitting),
        isA<ToolsState>()
            .having((s) => s.tools.length, 'len', 1)
            .having((s) => s.tools.first.id, 'id', 2)
            .having((s) => s.successMessage, 'ok', 'tool_deleted'),
      ],
    );
  });

  group('UploadToolImageEvent', () {
    blocTest<ToolsBloc, ToolsState>(
      'replaces the tool in the list with the updated one',
      setUp: () {
        // ★ Use a typed variable to force the right generic inference.
        final Either<Failure, Tool> response = Right<Failure, Tool>(
          TestData.tool(id: 1, imageCount: 2),
        );
        when(() => upload(any())).thenAnswer((_) async => response);
      },
      seed: () =>
          ToolsState(
            status: ToolsStatus.loaded,
            tools: [TestData.tool(id: 1, imageCount: 0)],
          ),
      build: build,
      act: (b) =>
          b.add(
            const UploadToolImageEvent(toolId: 1, path: '/p.jpg'),
          ),
      verify: (_) {
        // ★ Confirms the mock actually fired (would throw if not stubbed).
        verify(() => upload(any())).called(1);
      },
      expect: () =>
      [
        isA<ToolsState>()
            .having((s) => s.tools.first.imageCount, 'count', 2),
      ],
    );
  });
}