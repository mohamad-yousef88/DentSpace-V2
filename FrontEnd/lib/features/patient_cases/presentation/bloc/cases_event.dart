import 'package:equatable/equatable.dart';

import '../../domain/repositories/cases_repository.dart';

sealed class CasesEvent extends Equatable {
  const CasesEvent();
  @override
  List<Object?> get props => [];
}

// ═══════════════════════════════════════════════════════════════
// List events
// ═══════════════════════════════════════════════════════════════
class LoadMyCasesEvent extends CasesEvent {
  const LoadMyCasesEvent();
}

class LoadAvailableCasesEvent extends CasesEvent {
  const LoadAvailableCasesEvent({this.search});
  final String? search;

  @override
  List<Object?> get props => [search];
}

// ═══════════════════════════════════════════════════════════════
// Single-case event (used by CaseDetailPage)
// ═══════════════════════════════════════════════════════════════
class LoadCaseByIdEvent extends CasesEvent {
  const LoadCaseByIdEvent(this.id);
  final int id;

  @override
  List<Object?> get props => [id];
}

// ═══════════════════════════════════════════════════════════════
// Create / preview
// ═══════════════════════════════════════════════════════════════
class PreviewDiagnosisEvent extends CasesEvent {
  const PreviewDiagnosisEvent(this.input);
  final CaseInput input;
  @override
  List<Object?> get props => [input.symptoms, input.location];
}

class ClearPreviewEvent extends CasesEvent {
  const ClearPreviewEvent();
}

class CreateCaseEvent extends CasesEvent {
  const CreateCaseEvent(this.input);
  final CaseInput input;
  @override
  List<Object?> get props => [input.symptoms, input.location];
}

// ═══════════════════════════════════════════════════════════════
// Mutations
// ═══════════════════════════════════════════════════════════════
class DeleteCaseEvent extends CasesEvent {
  const DeleteCaseEvent(this.id);
  final int id;
  @override
  List<Object?> get props => [id];
}

class UploadImageEvent extends CasesEvent {
  const UploadImageEvent({required this.caseId, required this.path});
  final int caseId;
  final String path;
  @override
  List<Object?> get props => [caseId, path];
}

class DeleteImageEvent extends CasesEvent {
  const DeleteImageEvent({required this.caseId, required this.index});
  final int caseId;
  final int index;
  @override
  List<Object?> get props => [caseId, index];
}