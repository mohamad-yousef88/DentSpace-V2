import 'package:equatable/equatable.dart';

import '../../domain/repositories/tools_repository.dart';

sealed class ToolsEvent extends Equatable {
  const ToolsEvent();
  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════
// List events
// ═══════════════════════════════════════════════════════════════
class LoadMarketToolsEvent extends ToolsEvent {
  const LoadMarketToolsEvent({this.search, this.category});

  final String? search;
  final String? category;

  @override
  List<Object?> get props => [search, category];
}

class LoadMyToolsEvent extends ToolsEvent {
  const LoadMyToolsEvent();
}

// ═══════════════════════════════════════════════════════════════
// Single-tool event (used by detail page)
// ═══════════════════════════════════════════════════════════════
class LoadToolByIdEvent extends ToolsEvent {
  const LoadToolByIdEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

// ═══════════════════════════════════════════════════════════════
// Mutations
// ═══════════════════════════════════════════════════════════════
class CreateToolEvent extends ToolsEvent {
  const CreateToolEvent(this.params);
  final CreateToolParams params;

  @override
  List<Object?> get props => [params];
}

class UpdateToolEvent extends ToolsEvent {
  const UpdateToolEvent({required this.id, required this.params});
  final int id;
  final UpdateToolParams params;

  @override
  List<Object?> get props => [id, params];
}

class DeleteToolEvent extends ToolsEvent {
  const DeleteToolEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

class UploadToolImageEvent extends ToolsEvent {
  const UploadToolImageEvent({required this.toolId, required this.path});
  final int toolId;
  final String path;

  @override
  List<Object?> get props => [toolId, path];
}

class DeleteToolImageEvent extends ToolsEvent {
  const DeleteToolImageEvent({required this.toolId, required this.index});
  final int toolId;
  final int index;

  @override
  List<Object?> get props => [toolId, index];
}

/// Clear success/error feedback after the UI has shown it.
class ClearToolFeedbackEvent extends ToolsEvent {
  const ClearToolFeedbackEvent();
}
/// Composite event: create the tool, then upload each image
/// sequentially. Used by the create-tool form.
class CreateToolWithImagesEvent extends ToolsEvent {
  const CreateToolWithImagesEvent({
    required this.params,
    required this.imagePaths,
  });

  final CreateToolParams params;
  final List<String> imagePaths;

  @override
  List<Object?> get props => [params, imagePaths];
}