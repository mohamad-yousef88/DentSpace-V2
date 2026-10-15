import 'package:dentspace/core/error/exceptions.dart';
import 'package:dentspace/features/patient_cases/data/repositories/cases_repository_impl.dart';
import 'package:dentspace/features/patient_cases/domain/repositories/cases_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_mocks.dart';

void main() {
  late MockCasesRemoteDataSource remote;
  late MockCacheService cache;

  const input = CaseInput(
    symptoms: ['tooth_pain'],
    location: 'upper_right',
    hasPain: true,
    painSeverity: 'medium',
    hasSwelling: false,
  );

  setUpAll(registerFallbackValues);

  setUp(() {
    remote = MockCasesRemoteDataSource();
    cache = MockCacheService();
    when(() => cache.saveMyCases(any())).thenAnswer((_) async {});
    when(() => cache.saveAvailableCases(any())).thenAnswer((_) async {});
    when(() => cache.saveCaseDetail(any(), any())).thenAnswer((_) async {});
    when(() => cache.invalidateCases()).thenAnswer((_) async {});
  });

  CasesRepositoryImpl build() => CasesRepositoryImpl(remote, cache);

  // ═══════════════════════════════════════════════════════════════
  group('listMyCases', () {
    test('success → caches + returns', () async {
      when(() => remote.listMyCases()).thenAnswer(
            (_) async => [TestData.patientCase(id: 1), TestData.patientCase(id: 2)],
      );

      final result = await build().listMyCases();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.length, 2));
      verify(() => cache.saveMyCases(any())).called(1);
    });

    test('failure + cache → cached', () async {
      when(() => remote.listMyCases())
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readMyCases()).thenReturn([TestData.caseJson(id: 7)]);

      final result = await build().listMyCases();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.first.id, 7));
    });

    test('failure + no cache → Left', () async {
      when(() => remote.listMyCases())
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readMyCases()).thenReturn(null);

      expect((await build().listMyCases()).isLeft(), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('listAvailableCases', () {
    test('no search → caches', () async {
      when(() => remote.listAvailableCases(search: any(named: 'search')))
          .thenAnswer((_) async => [TestData.patientCase(id: 1)]);

      await build().listAvailableCases();

      verify(() => cache.saveAvailableCases(any())).called(1);
    });

    test('with search → does NOT cache', () async {
      when(() => remote.listAvailableCases(search: any(named: 'search')))
          .thenAnswer((_) async => [TestData.patientCase(id: 1)]);

      await build().listAvailableCases(search: 'pain');

      verifyNever(() => cache.saveAvailableCases(any()));
    });

    test('search failure → does NOT fall back to cache', () async {
      when(() => remote.listAvailableCases(search: any(named: 'search')))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readAvailableCases())
          .thenReturn([TestData.caseJson(id: 1)]);

      final result = await build().listAvailableCases(search: 'x');

      expect(result.isLeft(), isTrue);
      verifyNever(() => cache.readAvailableCases());
    });

    test('no-search failure → falls back to cache', () async {
      when(() => remote.listAvailableCases(search: any(named: 'search')))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readAvailableCases())
          .thenReturn([TestData.caseJson(id: 3)]);

      final result = await build().listAvailableCases();

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (list) => expect(list.first.id, 3));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('getCaseById', () {
    test('success → caches detail', () async {
      when(() => remote.getCaseById(1))
          .thenAnswer((_) async => TestData.patientCase(id: 1));

      await build().getCaseById(1);

      verify(() => cache.saveCaseDetail(1, any())).called(1);
    });

    test('failure + cache → cached', () async {
      when(() => remote.getCaseById(1))
          .thenThrow(const ServerException(message: 'offline'));
      when(() => cache.readCaseDetail(1))
          .thenReturn(TestData.caseJson(id: 1));

      final result = await build().getCaseById(1);
      expect(result.isRight(), isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('mutations invalidate cache', () {
    test('createCase', () async {
      when(() => remote.createCase(any()))
          .thenAnswer((_) async => TestData.patientCase(id: 1));

      await build().createCase(input);

      verify(() => cache.invalidateCases()).called(1);
    });

    test('updateCase', () async {
      when(() => remote.updateCase(any(), any()))
          .thenAnswer((_) async => TestData.patientCase(id: 1));

      await build().updateCase(1, input);

      verify(() => cache.invalidateCases()).called(1);
    });

    test('deleteCase', () async {
      when(() => remote.deleteCase(any())).thenAnswer((_) async {});

      await build().deleteCase(1);

      verify(() => cache.invalidateCases()).called(1);
    });

    test('uploadImage', () async {
      when(() => remote.uploadImage(any(), any()))
          .thenAnswer((_) async => TestData.patientCase(id: 1));

      await build().uploadImage(1, '/p.jpg');

      verify(() => cache.invalidateCases()).called(1);
    });

    test('deleteImage', () async {
      when(() => remote.deleteImage(any(), any()))
          .thenAnswer((_) async => TestData.patientCase(id: 1));

      await build().deleteImage(1, 0);

      verify(() => cache.invalidateCases()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('previewDiagnosis', () {
    test('is never cached — always hits remote', () async {
      when(() => remote.previewDiagnosis(any())).thenThrow(
        const ServerException(message: 'x'),
      );

      await build().previewDiagnosis(input);

      // No cache read/write must happen — verified by no stub being set
      // (mocktail throws if un-stubbed method is called).
      verifyNever(() => cache.saveCaseDetail(any(), any()));
      verifyNever(() => cache.saveMyCases(any()));
    });
  });
}