import 'package:equatable/equatable.dart';

import '../../domain/entities/tool.dart';

enum ToolsStatus { idle, loading, loaded, submitting, failure }

/// Distinguishes the two list contexts the BLoC serves:
///   • [market] — available tools from other doctors
///   • [mine]   — the current doctor's own listings
enum ToolsViewMode { market, mine }

class ToolsState extends Equatable {
  const ToolsState({
    this.status = ToolsStatus.idle,
    this.viewMode = ToolsViewMode.market,
    this.tools = const [],
    this.currentTool,
    this.errorMessage,
    this.successMessage,
  });

  final ToolsStatus status;
  final ToolsViewMode viewMode;
  final List<Tool> tools;

  /// Single tool loaded via `GET /tools/{id}`.
  final Tool? currentTool;

  final String? errorMessage;

  /// One of: `tool_created`, `tool_updated`, `tool_deleted`,
  /// `tool_image_added`, `tool_image_removed`.
  final String? successMessage;

  bool get isLoading => status == ToolsStatus.loading;
  bool get isSubmitting => status == ToolsStatus.submitting;
  bool get isFailure => status == ToolsStatus.failure;

  ToolsState copyWith({
    ToolsStatus? status,
    ToolsViewMode? viewMode,
    List<Tool>? tools,
    Tool? currentTool,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCurrentTool = false,
  }) {
    return ToolsState(
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      tools: tools ?? this.tools,
      currentTool:
      clearCurrentTool ? null : (currentTool ?? this.currentTool),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
      clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, viewMode, tools, currentTool, errorMessage, successMessage];
}