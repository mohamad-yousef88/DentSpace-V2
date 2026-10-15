import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_service.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/diagnosis_preview.dart';
import '../../domain/entities/patient_case.dart';
import '../../domain/repositories/cases_repository.dart';
import '../datasources/cases_remote_datasource.dart';

class CasesRepositoryImpl implements CasesRepository {
  CasesRepositoryImpl(this._remote, this._cache);

  final CasesRemoteDataSource _remote;
  final CacheService _cache;

  // ═══════════════════════════════════════════════════════
  // Preview — never cached (stateless calculation)
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, DiagnosisPreview>> previewDiagnosis(
      CaseInput input,
      ) async {
    try {
      return Right(await _remote.previewDiagnosis(input));
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Create — invalidate my-cases
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, PatientCase>> createCase(CaseInput input) async {
    try {
      final created = await _remote.createCase(input);
      await _cache.invalidateCases();
      return Right(created);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Read — network-first with cache fallback
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, List<PatientCase>>> listMyCases() async {
    try {
      final items = await _remote.listMyCases();
      await _cache.saveMyCases(items.map((c) => c.toJson()).toList());
      return Right(items);
    } catch (e) {
      final cached = _cache.readMyCases();
      if (cached != null) {
        return Right(cached.map(PatientCase.fromJson).toList());
      }
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<PatientCase>>> listAvailableCases({
    String? search,
  }) async {
    // Never cache search results — only the default list.
    final isSearch = search != null && search.trim().isNotEmpty;
    try {
      final items = await _remote.listAvailableCases(search: search);
      if (!isSearch) {
        await _cache.saveAvailableCases(
          items.map((c) => c.toJson()).toList(),
        );
      }
      return Right(items);
    } catch (e) {
      if (!isSearch) {
        final cached = _cache.readAvailableCases();
        if (cached != null) {
          return Right(cached.map(PatientCase.fromJson).toList());
        }
      }
      return Left(mapErrorToFailure(e));
    }
  }

  // ★ Renamed to match the repository interface (`getCaseById`).
  @override
  Future<Either<Failure, PatientCase>> getCaseById(int id) async {
    try {
      final item = await _remote.getCaseById(id);
      await _cache.saveCaseDetail(id, item.toJson());
      return Right(item);
    } catch (e) {
      final cached = _cache.readCaseDetail(id);
      if (cached != null) {
        return Right(PatientCase.fromJson(cached));
      }
      return Left(mapErrorToFailure(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Update / delete / images — invalidate cache
  // ═══════════════════════════════════════════════════════
  @override
  Future<Either<Failure, PatientCase>> updateCase(
      int id,
      CaseInput input,
      ) async {
    try {
      final updated = await _remote.updateCase(id, input);
      await _cache.invalidateCases();
      return Right(updated);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCase(int id) async {
    try {
      await _remote.deleteCase(id);
      await _cache.invalidateCases();
      return const Right(null);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, PatientCase>> uploadImage(
      int caseId,
      String path,
      ) async {
    try {
      final updated = await _remote.uploadImage(caseId, path);
      await _cache.invalidateCases();
      return Right(updated);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }

  @override
  Future<Either<Failure, PatientCase>> deleteImage(
      int caseId,
      int index,
      ) async {
    try {
      final updated = await _remote.deleteImage(caseId, index);
      await _cache.invalidateCases();
      return Right(updated);
    } catch (e) {
      return Left(mapErrorToFailure(e));
    }
  }
}