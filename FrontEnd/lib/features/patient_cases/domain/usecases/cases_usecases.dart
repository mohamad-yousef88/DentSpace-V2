import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/diagnosis_preview.dart';
import '../entities/patient_case.dart';
import '../repositories/cases_repository.dart';

// ═══════════════════════════════════════════════════════════════
class PreviewDiagnosisUseCase
    extends UseCase<DiagnosisPreview, CaseInput> {
  PreviewDiagnosisUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, DiagnosisPreview>> call(CaseInput p) =>
      _repo.previewDiagnosis(p);
}

// ═══════════════════════════════════════════════════════════════
class CreateCaseUseCase extends UseCase<PatientCase, CaseInput> {
  CreateCaseUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, PatientCase>> call(CaseInput p) =>
      _repo.createCase(p);
}

// ═══════════════════════════════════════════════════════════════
class ListMyCasesUseCase extends UseCase<List<PatientCase>, NoParams> {
  ListMyCasesUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, List<PatientCase>>> call(NoParams _) =>
      _repo.listMyCases();
}

// ═══════════════════════════════════════════════════════════════
class GetCaseUseCase extends UseCase<PatientCase, int> {
  GetCaseUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, PatientCase>> call(int id) => _repo.getCaseById(id);
}

// ═══════════════════════════════════════════════════════════════
class UpdateCaseParams {
  const UpdateCaseParams({required this.id, required this.input});
  final int id;
  final CaseInput input;
}

class UpdateCaseUseCase extends UseCase<PatientCase, UpdateCaseParams> {
  UpdateCaseUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, PatientCase>> call(UpdateCaseParams p) =>
      _repo.updateCase(p.id, p.input);
}

// ═══════════════════════════════════════════════════════════════
class DeleteCaseUseCase extends UseCase<void, int> {
  DeleteCaseUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, void>> call(int id) => _repo.deleteCase(id);
}

// ═══════════════════════════════════════════════════════════════
class UploadCaseImageParams {
  const UploadCaseImageParams({required this.caseId, required this.path});
  final int caseId;
  final String path;
}

class UploadCaseImageUseCase
    extends UseCase<PatientCase, UploadCaseImageParams> {
  UploadCaseImageUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, PatientCase>> call(UploadCaseImageParams p) =>
      _repo.uploadImage(p.caseId, p.path);
}

// ═══════════════════════════════════════════════════════════════
class DeleteCaseImageParams {
  const DeleteCaseImageParams({required this.caseId, required this.index});
  final int caseId;
  final int index;
}

class DeleteCaseImageUseCase
    extends UseCase<PatientCase, DeleteCaseImageParams> {
  DeleteCaseImageUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, PatientCase>> call(DeleteCaseImageParams p) =>
      _repo.deleteImage(p.caseId, p.index);
}
// ═══════════════════════════════════════════════════════════════
class ListAvailableCasesUseCase
    extends UseCase<List<PatientCase>, String?> {
  ListAvailableCasesUseCase(this._repo);
  final CasesRepository _repo;

  @override
  Future<Either<Failure, List<PatientCase>>> call(String? search) =>
      _repo.listAvailableCases(search: search);
}