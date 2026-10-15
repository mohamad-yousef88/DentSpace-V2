import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/tool.dart';
import '../repositories/tools_repository.dart';

// ═══════════════════════════════════════════════════════════════
// List
// ═══════════════════════════════════════════════════════════════
class ListToolsUseCase extends UseCase<List<Tool>, ToolListParams> {
  ListToolsUseCase(this._repo);
  final ToolsRepository _repo;

  @override
  Future<Either<Failure, List<Tool>>> call(ToolListParams params) =>
      _repo.listTools(params);
}

// ═══════════════════════════════════════════════════════════════
// Get one
// ═══════════════════════════════════════════════════════════════
class GetToolUseCase extends UseCase<Tool, int> {
  GetToolUseCase(this._repo);
  final ToolsRepository _repo;

  @override
  Future<Either<Failure, Tool>> call(int id) => _repo.getTool(id);
}

// ═══════════════════════════════════════════════════════════════
// Create
// ═══════════════════════════════════════════════════════════════
class CreateToolUseCase extends UseCase<Tool, CreateToolParams> {
  CreateToolUseCase(this._repo);
  final ToolsRepository _repo;

  @override
  Future<Either<Failure, Tool>> call(CreateToolParams params) =>
      _repo.createTool(params);
}

// ═══════════════════════════════════════════════════════════════
// Update
// ═══════════════════════════════════════════════════════════════
class UpdateToolParams2 {
  const UpdateToolParams2(this.id, this.params);
  final int id;
  final UpdateToolParams params;
}

class UpdateToolUseCase extends UseCase<Tool, UpdateToolParams2> {
  UpdateToolUseCase(this._repo);
  final ToolsRepository _repo;

  @override
  Future<Either<Failure, Tool>> call(UpdateToolParams2 p) =>
      _repo.updateTool(p.id, p.params);
}

// ═══════════════════════════════════════════════════════════════
// Delete
// ═══════════════════════════════════════════════════════════════
class DeleteToolUseCase extends UseCase<void, int> {
  DeleteToolUseCase(this._repo);
  final ToolsRepository _repo;

  @override
  Future<Either<Failure, void>> call(int id) => _repo.deleteTool(id);
}

// ═══════════════════════════════════════════════════════════════
// Images
// ═══════════════════════════════════════════════════════════════
class UploadToolImageParams {
  const UploadToolImageParams({required this.toolId, required this.path});
  final int toolId;
  final String path;
}

class UploadToolImageUseCase
    extends UseCase<Tool, UploadToolImageParams> {
  UploadToolImageUseCase(this._repo);
  final ToolsRepository _repo;

  @override
  Future<Either<Failure, Tool>> call(UploadToolImageParams p) =>
      _repo.uploadImage(p.toolId, p.path);
}

class DeleteToolImageParams {
  const DeleteToolImageParams({required this.toolId, required this.index});
  final int toolId;
  final int index;
}

class DeleteToolImageUseCase
    extends UseCase<Tool, DeleteToolImageParams> {
  DeleteToolImageUseCase(this._repo);
  final ToolsRepository _repo;

  @override
  Future<Either<Failure, Tool>> call(DeleteToolImageParams p) =>
      _repo.deleteImage(p.toolId, p.index);
}