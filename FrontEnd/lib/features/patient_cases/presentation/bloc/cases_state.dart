import 'package:equatable/equatable.dart';

import '../../domain/entities/diagnosis_preview.dart';
import '../../domain/entities/patient_case.dart';

enum CasesStatus { idle, loading, loaded, previewing, failure }

/// Distinguishes between the two list contexts the BLoC serves:
///   • [myCases]   — patient's own cases (default)
///   • [available] — doctor browsing pending cases from other patients
enum CasesViewMode { myCases, available }

class CasesState extends Equatable {
  const CasesState({
    this.status = CasesStatus.idle,
    this.viewMode = CasesViewMode.myCases,
    this.cases = const [],
    this.currentCase,
    this.preview,
    this.errorMessage,
    this.successMessage,
  });

  final CasesStatus status;
  final CasesViewMode viewMode;
  final List<PatientCase> cases;

  /// Single case loaded via `GET /cases/{id}`.
  /// Used exclusively by [CaseDetailPage] so doctors can open cases
  /// that are not in their own list.
  final PatientCase? currentCase;

  /// Latest diagnosis preview (from /cases/preview).
  final DiagnosisPreview? preview;

  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == CasesStatus.loading;
  bool get isPreviewing => status == CasesStatus.previewing;

  CasesState copyWith({
    CasesStatus? status,
    CasesViewMode? viewMode,
    List<PatientCase>? cases,
    PatientCase? currentCase,
    DiagnosisPreview? preview,
    String? errorMessage,
    String? successMessage,
    bool clearPreview = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearCurrentCase = false,
  }) {
    return CasesState(
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      cases: cases ?? this.cases,
      currentCase:
      clearCurrentCase ? null : (currentCase ?? this.currentCase),
      preview: clearPreview ? null : (preview ?? this.preview),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
      clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, viewMode, cases, currentCase, preview, errorMessage];
}