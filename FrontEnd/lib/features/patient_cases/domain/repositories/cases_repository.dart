import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/diagnosis_preview.dart';
import '../entities/patient_case.dart';

/// Input shape for preview / create case.
class CaseInput {
  const CaseInput({
    required this.symptoms,
    required this.location,
    required this.hasPain,
    this.painSeverity,
    required this.hasSwelling,
    this.swellingSeverity,
  });

  final List<String> symptoms;
  final String location;
  final bool hasPain;
  final String? painSeverity;      // خفيف / متوسط / شديد
  final bool hasSwelling;
  final String? swellingSeverity;

  Map<String, dynamic> toJson() => {
    'symptoms': symptoms,
    'location': location,
    'has_pain': hasPain,
    'pain_severity': hasPain ? painSeverity : null,
    'has_swelling': hasSwelling,
    'swelling_severity': hasSwelling ? swellingSeverity : null,
  };
}

abstract class CasesRepository {
  Future<Either<Failure, DiagnosisPreview>> previewDiagnosis(CaseInput input);

  Future<Either<Failure, PatientCase>> createCase(CaseInput input);

  Future<Either<Failure, List<PatientCase>>> listMyCases();

  Future<Either<Failure, PatientCase>> getCaseById(int id);

  Future<Either<Failure, PatientCase>> updateCase(int id, CaseInput input);

  Future<Either<Failure, void>> deleteCase(int id);

  Future<Either<Failure, PatientCase>> uploadImage(int caseId, String path);

  Future<Either<Failure, PatientCase>> deleteImage(int caseId, int index);
  Future<Either<Failure, List<PatientCase>>> listAvailableCases({
    String? search,
  });
}