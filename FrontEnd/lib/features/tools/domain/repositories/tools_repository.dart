import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/tool.dart';

// ═══════════════════════════════════════════════════════════════
// Parameter objects
// ═══════════════════════════════════════════════════════════════
class ToolListParams extends Equatable {
  const ToolListParams({
    this.mine = false,
    this.search,
    this.category,
    this.status,
    this.offset = 0,
    this.limit = 20,
  });

  /// `true` → my listings; `false` → market (others' available tools).
  final bool mine;
  final String? search;
  final String? category;
  final ToolStatus? status;
  final int offset;
  final int limit;

  @override
  List<Object?> get props =>
      [mine, search, category, status, offset, limit];
}

class CreateToolParams extends Equatable {
  const CreateToolParams({
    required this.name,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
  });

  final String name;
  final String description;
  final String category;
  final String condition;
  final double price;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'condition': condition,
    'price': price,
  };

  @override
  List<Object?> get props =>
      [name, description, category, condition, price];
}

class UpdateToolParams extends Equatable {
  const UpdateToolParams({
    this.name,
    this.description,
    this.category,
    this.condition,
    this.price,
  });

  final String? name;
  final String? description;
  final String? category;
  final String? condition;
  final double? price;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (category != null) 'category': category,
    if (condition != null) 'condition': condition,
    if (price != null) 'price': price,
  };

  @override
  List<Object?> get props => [name, description, category, condition, price];
}

// ═══════════════════════════════════════════════════════════════
// Repository interface
// ═══════════════════════════════════════════════════════════════
abstract class ToolsRepository {
  /// List tools. `params.mine = true` → my listings,
  /// `params.mine = false` → market (others' available tools).
  Future<Either<Failure, List<Tool>>> listTools(ToolListParams params);

  Future<Either<Failure, Tool>> getTool(int id);

  Future<Either<Failure, Tool>> createTool(CreateToolParams params);

  Future<Either<Failure, Tool>> updateTool(int id, UpdateToolParams params);

  Future<Either<Failure, void>> deleteTool(int id);

  Future<Either<Failure, Tool>> uploadImage(int toolId, String path);

  Future<Either<Failure, Tool>> deleteImage(int toolId, int index);
}