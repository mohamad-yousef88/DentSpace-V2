import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_service.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/tool.dart';
import '../../domain/repositories/tools_repository.dart';
import '../datasources/tools_remote_datasource.dart';

class ToolsRepositoryImpl implements ToolsRepository {
  ToolsRepositoryImpl(this._remote, this._cache);

  final ToolsRemoteDataSource _remote;
  final CacheService _cache;

  // ═══════════════════════════════════════════════════════
  // List — cache only the *default* market / mine lists.
  //        Skip caching whenever a filter/search is active.
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, List<Tool>>> listTools(ToolListParams p) async {
    final isFiltered = (p.search?.trim().isNotEmpty ?? false) ||
        (p.category?.trim().isNotEmpty ?? false) ||
        p.status != null ||
        p.offset != 0;

    try {
      final items = await _remote.listTools(p);

      // Cache only the default query for each mode.
      if (!isFiltered) {
        if (p.mine) {
          await _cache.saveMyTools(items.map((t) => t.toJson()).toList());
        } else {
          await _cache.saveToolsList(items.map((t) => t.toJson()).toList());
        }
      }
      return Right(items);
    } catch (e) {
      if (!isFiltered) {
        final cached =
        p.mine ? _cache.readMyTools() : _cache.readToolsList();
        if (cached != null) {
          return Right(cached.map(Tool.fromJson).toList());
        }
      }
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Get one — cache detail
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, Tool>> getTool(int id) async {
    try {
      final tool = await _remote.getTool(id);
      await _cache.saveToolDetail(id, tool.toJson());
      return Right(tool);
    } catch (e) {
      final cached = _cache.readToolDetail(id);
      if (cached != null) {
        return Right(Tool.fromJson(cached));
      }
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Mutations — invalidate
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, Tool>> createTool(CreateToolParams p) async {
    try {
      final created = await _remote.createTool(p);
      await _cache.invalidateTools();
      return Right(created);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Tool>> updateTool(
      int id,
      UpdateToolParams p,
      ) async {
    try {
      final updated = await _remote.updateTool(id, p);
      await _cache.invalidateTools();
      return Right(updated);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTool(int id) async {
    try {
      await _remote.deleteTool(id);
      await _cache.invalidateTools();
      return const Right(null);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Tool>> uploadImage(int toolId, String path) async {
    try {
      final updated = await _remote.uploadImage(toolId, path);
      await _cache.invalidateTools();
      return Right(updated);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Tool>> deleteImage(int toolId, int index) async {
    try {
      final updated = await _remote.deleteImage(toolId, index);
      await _cache.invalidateTools();
      return Right(updated);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }
}