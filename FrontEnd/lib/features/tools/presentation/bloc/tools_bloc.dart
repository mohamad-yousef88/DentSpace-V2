import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tool.dart';

import '../../domain/repositories/tools_repository.dart';
import '../../domain/usecases/tools_usecases.dart';
import 'tools_event.dart';
import 'tools_state.dart';

class ToolsBloc extends Bloc<ToolsEvent, ToolsState> {
  ToolsBloc({
    required ListToolsUseCase listTools,
    required GetToolUseCase getTool,
    required CreateToolUseCase createTool,
    required UpdateToolUseCase updateTool,
    required DeleteToolUseCase deleteTool,
    required UploadToolImageUseCase uploadImage,
    required DeleteToolImageUseCase deleteImage,
  })  : _listTools = listTools,
        _getTool = getTool,
        _create = createTool,
        _update = updateTool,
        _delete = deleteTool,
        _upload = uploadImage,
        _deleteImage = deleteImage,
        super(const ToolsState()) {
    on<LoadMarketToolsEvent>(_onLoadMarket);
    on<LoadMyToolsEvent>(_onLoadMine);
    on<LoadToolByIdEvent>(_onLoadById);
    on<CreateToolEvent>(_onCreate);
    on<UpdateToolEvent>(_onUpdate);
    on<DeleteToolEvent>(_onDelete);
    on<UploadToolImageEvent>(_onUpload);
    on<DeleteToolImageEvent>(_onDeleteImage);
    on<ClearToolFeedbackEvent>(_onClearFeedback);
    on<CreateToolWithImagesEvent>(_onCreateWithImages);
  }

  final ListToolsUseCase _listTools;
  final GetToolUseCase _getTool;
  final CreateToolUseCase _create;
  final UpdateToolUseCase _update;
  final DeleteToolUseCase _delete;
  final UploadToolImageUseCase _upload;
  final DeleteToolImageUseCase _deleteImage;

  // ═══════════════════════════════════════════════════════════════
  // Market
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoadMarket(
      LoadMarketToolsEvent event,
      Emitter<ToolsState> emit,
      ) async {
    emit(state.copyWith(
      status: ToolsStatus.loading,
      viewMode: ToolsViewMode.market,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _listTools(ToolListParams(
      mine: false,
      search: event.search,
      category: event.category,
    ),);

    result.fold(
          (f) => emit(state.copyWith(
        status: ToolsStatus.failure,
        errorMessage: f.message,
      ),),
          (items) => emit(state.copyWith(
        status: ToolsStatus.loaded,
        tools: items,
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // My tools
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoadMine(
      LoadMyToolsEvent event,
      Emitter<ToolsState> emit,
      ) async {
    emit(state.copyWith(
      status: ToolsStatus.loading,
      viewMode: ToolsViewMode.mine,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _listTools(const ToolListParams(mine: true));

    result.fold(
          (f) => emit(state.copyWith(
        status: ToolsStatus.failure,
        errorMessage: f.message,
      ),),
          (items) => emit(state.copyWith(
        status: ToolsStatus.loaded,
        tools: items,
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Detail
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoadById(
      LoadToolByIdEvent event,
      Emitter<ToolsState> emit,
      ) async {
    emit(state.copyWith(
      status: ToolsStatus.loading,
      clearError: true,
      clearCurrentTool: true,
    ),);

    final result = await _getTool(event.id);

    result.fold(
          (f) => emit(state.copyWith(
        status: ToolsStatus.failure,
        errorMessage: f.message,
      ),),
          (tool) => emit(state.copyWith(
        status: ToolsStatus.loaded,
        currentTool: tool,
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Create
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onCreate(
      CreateToolEvent event,
      Emitter<ToolsState> emit,
      ) async {
    emit(state.copyWith(
      status: ToolsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _create(event.params);

    result.fold(
          (f) => emit(state.copyWith(
        status: ToolsStatus.failure,
        errorMessage: f.message,
      ),),
          (created) => emit(state.copyWith(
        status: ToolsStatus.loaded,
        tools: [created, ...state.tools],
        currentTool: created,
        successMessage: 'tool_created',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Update
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onUpdate(
      UpdateToolEvent event,
      Emitter<ToolsState> emit,
      ) async {
    emit(state.copyWith(
      status: ToolsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _update(UpdateToolParams2(event.id, event.params));

    result.fold(
          (f) => emit(state.copyWith(
        status: ToolsStatus.failure,
        errorMessage: f.message,
      ),),
          (updated) => emit(state.copyWith(
        status: ToolsStatus.loaded,
        tools: state.tools
            .map((t) => t.id == updated.id ? updated : t)
            .toList(),
        currentTool: updated,
        successMessage: 'tool_updated',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Delete
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onDelete(
      DeleteToolEvent event,
      Emitter<ToolsState> emit,
      ) async {
    emit(state.copyWith(
      status: ToolsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _delete(event.id);

    result.fold(
          (f) => emit(state.copyWith(
        status: ToolsStatus.failure,
        errorMessage: f.message,
      ),),
          (_) => emit(state.copyWith(
        status: ToolsStatus.loaded,
        tools: state.tools.where((t) => t.id != event.id).toList(),
        clearCurrentTool: true,
        successMessage: 'tool_deleted',
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Images
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onUpload(
      UploadToolImageEvent event,
      Emitter<ToolsState> emit,
      ) async {
    final result = await _upload(UploadToolImageParams(
      toolId: event.toolId,
      path: event.path,
    ),);

    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (updated) {
        final list = state.tools
            .map((t) => t.id == updated.id ? updated : t)
            .toList();
        final current =
        state.currentTool?.id == updated.id ? updated : state.currentTool;
        emit(state.copyWith(
          status: ToolsStatus.loaded,
          tools: list,
          currentTool: current,
        ),);
      },
    );
  }

  Future<void> _onDeleteImage(
      DeleteToolImageEvent event,
      Emitter<ToolsState> emit,
      ) async {
    final result = await _deleteImage(DeleteToolImageParams(
      toolId: event.toolId,
      index: event.index,
    ),);

    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (updated) {
        final list = state.tools
            .map((t) => t.id == updated.id ? updated : t)
            .toList();
        final current =
        state.currentTool?.id == updated.id ? updated : state.currentTool;
        emit(state.copyWith(
          status: ToolsStatus.loaded,
          tools: list,
          currentTool: current,
        ),);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  void _onClearFeedback(
      ClearToolFeedbackEvent event,
      Emitter<ToolsState> emit,
      ) {
    emit(state.copyWith(clearError: true, clearSuccess: true));
  }
  // ═══════════════════════════════════════════════════════════════
  // Create + upload images (atomic feel)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onCreateWithImages(
      CreateToolWithImagesEvent event,
      Emitter<ToolsState> emit,
      ) async {
    emit(state.copyWith(
      status: ToolsStatus.submitting,
      clearError: true,
      clearSuccess: true,
    ),);

    // 1) Create the tool
    final created = await _create(event.params);

    Tool? tool;
    final failure = created.fold<Failure?>((f) => f, (t) {
      tool = t;
      return null;
    },);

    if (failure != null || tool == null) {
      emit(state.copyWith(
        status: ToolsStatus.failure,
        errorMessage: failure?.message ?? 'Failed to create tool.',
      ),);
      return;
    }

    // 2) Upload images sequentially
    for (final path in event.imagePaths) {
      final res = await _upload(UploadToolImageParams(
        toolId: tool!.id,
        path: path,
      ),);
      // On success, update the local tool reference. On failure, keep
      // going — a partial upload still produces a usable tool.
      res.fold((_) {}, (updated) => tool = updated);
    }

    // ★ Emit a SINGLE success state — prevents double-pop on the page.
    emit(state.copyWith(
      status: ToolsStatus.loaded,
      tools: [tool!, ...state.tools.where((t) => t.id != tool!.id)],
      currentTool: tool,
      successMessage: 'tool_created',
    ),);
  }
}