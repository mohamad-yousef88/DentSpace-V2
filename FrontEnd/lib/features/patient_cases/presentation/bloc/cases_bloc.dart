import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/cases_usecases.dart';
import 'cases_event.dart';
import 'cases_state.dart';

class CasesBloc extends Bloc<CasesEvent, CasesState> {
  CasesBloc({
    required PreviewDiagnosisUseCase previewDiagnosis,
    required CreateCaseUseCase createCase,
    required ListMyCasesUseCase listMyCases,
    required ListAvailableCasesUseCase listAvailableCases,
    required GetCaseUseCase getCase,
    required DeleteCaseUseCase deleteCase,
    required UploadCaseImageUseCase uploadImage,
    required DeleteCaseImageUseCase deleteImage,
  })  : _preview = previewDiagnosis,
        _create = createCase,
        _list = listMyCases,
        _listAvailable = listAvailableCases,
        _getCase = getCase,
        _delete = deleteCase,
        _upload = uploadImage,
        _deleteImage = deleteImage,
        super(const CasesState()) {
    on<LoadMyCasesEvent>(_onLoad);
    on<LoadAvailableCasesEvent>(_onLoadAvailable);
    on<LoadCaseByIdEvent>(_onLoadById);
    on<PreviewDiagnosisEvent>(_onPreview);
    on<ClearPreviewEvent>(_onClearPreview);
    on<CreateCaseEvent>(_onCreate);
    on<DeleteCaseEvent>(_onDelete);
    on<UploadImageEvent>(_onUpload);
    on<DeleteImageEvent>(_onDeleteImage);
  }

  final PreviewDiagnosisUseCase _preview;
  final CreateCaseUseCase _create;
  final ListMyCasesUseCase _list;
  final ListAvailableCasesUseCase _listAvailable;
  final GetCaseUseCase _getCase;
  final DeleteCaseUseCase _delete;
  final UploadCaseImageUseCase _upload;
  final DeleteCaseImageUseCase _deleteImage;

  // ═══════════════════════════════════════════════════════════════
  // Load: my cases
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoad(
      LoadMyCasesEvent event,
      Emitter<CasesState> emit,
      ) async {
    emit(state.copyWith(
      status: CasesStatus.loading,
      viewMode: CasesViewMode.myCases,
      clearError: true,
    ),);
    final result = await _list(const NoParams());
    result.fold(
          (f) => emit(state.copyWith(
        status: CasesStatus.failure,
        errorMessage: f.message,
      ),),
          (cases) => emit(state.copyWith(
        status: CasesStatus.loaded,
        cases: cases,
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Load: available cases (doctor)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoadAvailable(
      LoadAvailableCasesEvent event,
      Emitter<CasesState> emit,
      ) async {
    emit(state.copyWith(
      status: CasesStatus.loading,
      viewMode: CasesViewMode.available,
      clearError: true,
    ),);
    final result = await _listAvailable(event.search);
    result.fold(
          (f) => emit(state.copyWith(
        status: CasesStatus.failure,
        errorMessage: f.message,
      ),),
          (cases) => emit(state.copyWith(
        status: CasesStatus.loaded,
        cases: cases,
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Load: single case by id (detail page)
  // ═══════════════════════════════════════════════════════════════
  Future<void> _onLoadById(
      LoadCaseByIdEvent event,
      Emitter<CasesState> emit,
      ) async {
    emit(state.copyWith(
      status: CasesStatus.loading,
      clearError: true,
      clearCurrentCase: true,
    ),);
    final result = await _getCase(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: CasesStatus.failure,
        errorMessage: f.message,
      ),),
          (caseEntity) => emit(state.copyWith(
        status: CasesStatus.loaded,
        currentCase: caseEntity,
      ),),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  Future<void> _onPreview(
      PreviewDiagnosisEvent event,
      Emitter<CasesState> emit,
      ) async {
    emit(state.copyWith(
      status: CasesStatus.previewing,
      clearError: true,
      clearPreview: true,
    ),);
    final result = await _preview(event.input);
    result.fold(
          (f) => emit(state.copyWith(
        status: CasesStatus.failure,
        errorMessage: f.message,
      ),),
          (preview) => emit(state.copyWith(
        status: CasesStatus.loaded,
        preview: preview,
      ),),
    );
  }

  void _onClearPreview(ClearPreviewEvent event, Emitter<CasesState> emit) {
    emit(state.copyWith(clearPreview: true, clearError: true));
  }

  Future<void> _onCreate(
      CreateCaseEvent event,
      Emitter<CasesState> emit,
      ) async {
    emit(state.copyWith(status: CasesStatus.loading, clearError: true));
    final result = await _create(event.input);
    result.fold(
          (f) => emit(state.copyWith(
        status: CasesStatus.failure,
        errorMessage: f.message,
      ),),
          (created) {
        emit(state.copyWith(
          status: CasesStatus.loaded,
          cases: [created, ...state.cases],
          successMessage: 'case_created',
          clearPreview: true,
        ),);
      },
    );
  }

  Future<void> _onDelete(
      DeleteCaseEvent event,
      Emitter<CasesState> emit,
      ) async {
    final result = await _delete(event.id);
    result.fold(
          (f) => emit(state.copyWith(
        status: CasesStatus.failure,
        errorMessage: f.message,
      ),),
          (_) => emit(state.copyWith(
        status: CasesStatus.loaded,
        cases: state.cases.where((c) => c.id != event.id).toList(),
        successMessage: 'case_deleted',
      ),),
    );
  }

  Future<void> _onUpload(
      UploadImageEvent event,
      Emitter<CasesState> emit,
      ) async {
    final result = await _upload(UploadCaseImageParams(
      caseId: event.caseId,
      path: event.path,
    ),);
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (updated) {
        // Update both the list and the current case (if present).
        final list = state.cases
            .map((c) => c.id == updated.id ? updated : c)
            .toList();
        final current = state.currentCase?.id == updated.id
            ? updated
            : state.currentCase;
        emit(state.copyWith(
          status: CasesStatus.loaded,
          cases: list,
          currentCase: current,
        ),);
      },
    );
  }

  Future<void> _onDeleteImage(
      DeleteImageEvent event,
      Emitter<CasesState> emit,
      ) async {
    final result = await _deleteImage(DeleteCaseImageParams(
      caseId: event.caseId,
      index: event.index,
    ),);
    result.fold(
          (f) => emit(state.copyWith(errorMessage: f.message)),
          (updated) {
        final list = state.cases
            .map((c) => c.id == updated.id ? updated : c)
            .toList();
        final current = state.currentCase?.id == updated.id
            ? updated
            : state.currentCase;
        emit(state.copyWith(
          status: CasesStatus.loaded,
          cases: list,
          currentCase: current,
        ),);
      },
    );
  }
}