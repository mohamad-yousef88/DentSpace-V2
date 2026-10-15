import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/diagnosis_preview.dart';
import '../../domain/entities/patient_case.dart';
import '../../domain/repositories/cases_repository.dart';

/// Talks to `/cases`. Returns domain entities directly.
class CasesRemoteDataSource {
  CasesRemoteDataSource(this._client);
  final DioClient _client;

  static const _base = '/cases';

  // ═══════════════════════════════════════════════════════
  // Preview (stateless)
  // ═══════════════════════════════════════════════════════
  Future<DiagnosisPreview> previewDiagnosis(CaseInput input) async {
    final r = await _client.post<Map<String, dynamic>>(
      '$_base/preview',
      data: input.toJson(),
    );
    return DiagnosisPreview.fromJson(r.data!);
  }

  // ═══════════════════════════════════════════════════════
  // Create
  // ═══════════════════════════════════════════════════════
  Future<PatientCase> createCase(CaseInput input) async {
    final r = await _client.post<Map<String, dynamic>>(
      _base,
      data: input.toJson(),
    );
    return PatientCase.fromJson(r.data!);
  }

  // ═══════════════════════════════════════════════════════
  // List my cases (patient)
  // ═══════════════════════════════════════════════════════
  Future<List<PatientCase>> listMyCases() async {
    final r = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: {'mine': true},
    );
    final items = (r.data?['items'] as List? ?? []);
    return items
        .map((e) => PatientCase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════
  // List available cases (doctor)
  // ═══════════════════════════════════════════════════════
  Future<List<PatientCase>> listAvailableCases({String? search}) async {
    final r = await _client.get<Map<String, dynamic>>(
      _base,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search,
      },
    );
    final items = (r.data?['items'] as List? ?? []);
    return items
        .map((e) => PatientCase.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════
  // Get by id
  // ═══════════════════════════════════════════════════════
  Future<PatientCase> getCaseById(int id) async {
    final r = await _client.get<Map<String, dynamic>>('$_base/$id');
    return PatientCase.fromJson(r.data!);
  }

  // ═══════════════════════════════════════════════════════
  // Update
  // ═══════════════════════════════════════════════════════
  Future<PatientCase> updateCase(int id, CaseInput input) async {
    final r = await _client.patch<Map<String, dynamic>>(
      '$_base/$id',
      data: input.toJson(),
    );
    return PatientCase.fromJson(r.data!);
  }

  // ═══════════════════════════════════════════════════════
  // Delete
  // ═══════════════════════════════════════════════════════
  Future<void> deleteCase(int id) async {
    await _client.delete('$_base/$id');
  }

  // ═══════════════════════════════════════════════════════
  // Images
  // ═══════════════════════════════════════════════════════
  Future<PatientCase> uploadImage(int caseId, String path) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(path),
    });
    final r = await _client.upload<Map<String, dynamic>>(
      '$_base/$caseId/images',
      formData: formData,
    );
    return PatientCase.fromJson(r.data!);
  }

  Future<PatientCase> deleteImage(int caseId, int index) async {
    final r = await _client.delete<Map<String, dynamic>>(
      '$_base/$caseId/images/$index',
    );
    return PatientCase.fromJson(r.data!);
  }
}