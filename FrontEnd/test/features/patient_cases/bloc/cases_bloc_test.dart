import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' hide Order;
import 'package:dentspace/core/error/failures.dart';
import 'package:dentspace/features/patient_cases/domain/entities/diagnosis_match.dart';
import 'package:dentspace/features/patient_cases/domain/entities/diagnosis_preview.dart';
import 'package:dentspace/features/patient_cases/domain/entities/patient_case.dart';
import 'package:dentspace/features/patient_cases/domain/repositories/cases_repository.dart';
import 'package:dentspace/features/patient_cases/presentation/bloc/cases_bloc.dart';
import 'package:dentspace/features/patient_cases/presentation/bloc/cases_event.dart';
import 'package:dentspace/features/patient_cases/presentation/bloc/cases_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_data.dart';
import '../../../helpers/test_mocks.dart';

void main() {
  late MockPreviewDiagnosisUseCase preview;
  late MockCreateCaseUseCase create;
  late MockListMyCasesUseCase listMine;
  late MockListAvailableCasesUseCase listAvailable;
  late MockGetCaseUseCase getCase;
  late MockDeleteCaseUseCase delete;
  late MockUploadCaseImageUseCase upload;
  late MockDeleteCaseImageUseCase deleteImage;

  const input = CaseInput(
    symptoms: ['tooth_pain'],
    location: 'upper_right',
    hasPain: true,
    painSeverity: 'medium',
    hasSwelling: false,
  );

  setUpAll(registerFallbackValues);

  setUp(() {
    preview = MockPreviewDiagnosisUseCase();
    create = MockCreateCaseUseCase();
    listMine = MockListMyCasesUseCase();
    listAvailable = MockListAvailableCasesUseCase();
    getCase = MockGetCaseUseCase();
    delete = MockDeleteCaseUseCase();
    upload = MockUploadCaseImageUseCase();
    deleteImage = MockDeleteCaseImageUseCase();
  });

  CasesBloc build() => CasesBloc(
    previewDiagnosis: preview,
    createCase: create,
    listMyCases: listMine,
    listAvailableCases: listAvailable,
    getCase: getCase,
    deleteCase: delete,
    uploadImage: upload,
    deleteImage: deleteImage,
  );

  // ═══════════════════════════════════════════════════════════
  group('LoadMyCasesEvent', () {
    blocTest<CasesBloc, CasesState>(
      'loads my cases',
      setUp: () {
        when(() => listMine(any())).thenAnswer(
              (_) async => Right<Failure, List<PatientCase>>([
            TestData.patientCase(id: 1),
            TestData.patientCase(id: 2),
          ]),
        );
      },
      build: build,
      act: (b) => b.add(const LoadMyCasesEvent()),
      expect: () => [
        isA<CasesState>().having((s) => s.status, 's', CasesStatus.loading),
        isA<CasesState>()
            .having((s) => s.status, 's', CasesStatus.loaded)
            .having((s) => s.cases.length, 'len', 2)
            .having((s) => s.viewMode, 'v', CasesViewMode.myCases),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('LoadAvailableCasesEvent', () {
    blocTest<CasesBloc, CasesState>(
      'loads available cases as doctor',
      setUp: () {
        when(() => listAvailable(any())).thenAnswer(
              (_) async => Right<Failure, List<PatientCase>>([
            TestData.patientCase(id: 1, status: 'pending'),
          ]),
        );
      },
      build: build,
      act: (b) => b.add(const LoadAvailableCasesEvent()),
      expect: () => [
        isA<CasesState>().having((s) => s.status, 's', CasesStatus.loading),
        isA<CasesState>()
            .having((s) => s.viewMode, 'v', CasesViewMode.available)
            .having((s) => s.cases.length, 'len', 1),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('LoadCaseByIdEvent', () {
    blocTest<CasesBloc, CasesState>(
      'sets currentCase',
      setUp: () {
        when(() => getCase(any())).thenAnswer(
              (_) async => Right<Failure, PatientCase>(
            TestData.patientCase(id: 42),
          ),
        );
      },
      build: build,
      act: (b) => b.add(const LoadCaseByIdEvent(42)),
      expect: () => [
        isA<CasesState>().having((s) => s.status, 's', CasesStatus.loading),
        isA<CasesState>()
            .having((s) => s.currentCase?.id, 'id', 42)
            .having((s) => s.status, 's', CasesStatus.loaded),
      ],
    );

    blocTest<CasesBloc, CasesState>(
      'emits failure when case not found',
      setUp: () {
        when(() => getCase(any())).thenAnswer(
              (_) async => const Left(ServerFailure(message: 'not found')),
        );
      },
      build: build,
      act: (b) => b.add(const LoadCaseByIdEvent(999)),
      expect: () => [
        isA<CasesState>().having((s) => s.status, 's', CasesStatus.loading),
        isA<CasesState>()
            .having((s) => s.status, 's', CasesStatus.failure)
            .having((s) => s.errorMessage, 'err', 'not found'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('CreateCaseEvent', () {
    blocTest<CasesBloc, CasesState>(
      'prepends the new case + emits case_created',
      setUp: () {
        when(() => create(any())).thenAnswer(
              (_) async => Right<Failure, PatientCase>(
            TestData.patientCase(id: 100),
          ),
        );
      },
      build: build,
      act: (b) => b.add(const CreateCaseEvent(input)),
      expect: () => [
        isA<CasesState>().having((s) => s.status, 's', CasesStatus.loading),
        isA<CasesState>()
            .having((s) => s.cases.first.id, 'id', 100)
            .having((s) => s.successMessage, 'ok', 'case_created'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('DeleteCaseEvent', () {
    blocTest<CasesBloc, CasesState>(
      'removes the case from the list',
      setUp: () {
        when(() => delete(any()))
            .thenAnswer((_) async => const Right(null));
      },
      seed: () => CasesState(
        status: CasesStatus.loaded,
        cases: [
          TestData.patientCase(id: 1),
          TestData.patientCase(id: 2),
        ],
      ),
      build: build,
      act: (b) => b.add(const DeleteCaseEvent(1)),
      expect: () => [
        isA<CasesState>()
            .having((s) => s.cases.length, 'len', 1)
            .having((s) => s.cases.first.id, 'id', 2)
            .having((s) => s.successMessage, 'ok', 'case_deleted'),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════
  group('Diagnosis preview (from CasesBloc)', () {
    blocTest<CasesBloc, CasesState>(
      'emits preview state on success',
      setUp: () {
        when(() => preview(any())).thenAnswer(
              (_) async => const Right<Failure, DiagnosisPreview>(
            DiagnosisPreview(
              primary: DiagnosisMatch(
                key: 'caries',
                nameAr: 'تسوس',
                confidence: 0.9,
                confidencePct: 90,
                category: 'restorative',
                urgency: 'routine',
                notesAr: '',
                recommendationAr: '',
              ),
              alternatives: [],
              urgency: 'routine',
              redFlags: [],
              warnings: [],
              emergencyInstructions: [],
            ),
          ),
        );
      },
      build: build,
      act: (b) => b.add(const PreviewDiagnosisEvent(input)),
      expect: () => [
        isA<CasesState>()
            .having((s) => s.status, 's', CasesStatus.previewing),
        isA<CasesState>()
            .having((s) => s.preview, 'preview', isNotNull)
            .having((s) => s.status, 's', CasesStatus.loaded),
      ],
    );
  });
}