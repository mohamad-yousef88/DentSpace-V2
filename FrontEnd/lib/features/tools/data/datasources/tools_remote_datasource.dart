import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/tool.dart';
import '../../domain/repositories/tools_repository.dart';

/// Talks to `/tools`. Returns domain entities directly.
class ToolsRemoteDataSource {
  ToolsRemoteDataSource(this._client);
  final DioClient _client;

  static const _base = '/tools';

  // ═══════════════════════════════════════════════════════
  // List — market or my listings
  // ═══════════════════════════════════════════════════════
  Future<List<Tool>> listTools(ToolListParams p) async {
    final r = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        'mine': p.mine,
        if (p.search != null && p.search!.trim().isNotEmpty)
          'search': p.search,
        if (p.category != null && p.category!.trim().isNotEmpty)
          'category': p.category,
        if (p.status != null) 'status': p.status!.name,
        'offset': p.offset,
        'limit': p.limit,
      },
    );
    final items = (r.data?['items'] as List? ?? []);
    return items
        .map((e) => Tool.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════
  // Get one
  // ═══════════════════════════════════════════════════════
  Future<Tool> getTool(int id) async {
    final r = await _client.get<Map<String, dynamic>>('$_base/$id');
    return Tool.fromJson(r.data!);
  }

  // ═══════════════════════════════════════════════════════
  // Create
  // ═══════════════════════════════════════════════════════
  Future<Tool> createTool(CreateToolParams p) async {
    final r = await _client.post<Map<String, dynamic>>(
      _base,
      data: p.toJson(),
    );
    return Tool.fromJson(r.data!);
  }

  // ═══════════════════════════════════════════════════════
  // Update
  // ═══════════════════════════════════════════════════════
  Future<Tool> updateTool(int id, UpdateToolParams p) async {
    final r = await _client.patch<Map<String, dynamic>>(
      '$_base/$id',
      data: p.toJson(),
    );
    return Tool.fromJson(r.data!);
  }

  // ═══════════════════════════════════════════════════════
  // Delete
  // ═══════════════════════════════════════════════════════
  Future<void> deleteTool(int id) async {
    await _client.delete('$_base/$id');
  }

  // ═══════════════════════════════════════════════════════
  // Images
  // ═══════════════════════════════════════════════════════
  Future<Tool> uploadImage(int toolId, String path) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(path),
    });
    final r = await _client.upload<Map<String, dynamic>>(
      '$_base/$toolId/images',
      formData: formData,
    );
    return Tool.fromJson(r.data!);
  }

  Future<Tool> deleteImage(int toolId, int index) async {
    final r = await _client.delete<Map<String, dynamic>>(
      '$_base/$toolId/images/$index',
    );
    return Tool.fromJson(r.data!);
  }
}