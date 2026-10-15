import 'package:dentspace/core/network/interceptors/auth_interceptor.dart';
import 'package:dentspace/core/services/local_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {}

/// Captures what the interceptor does with the request.
class _RequestHandler extends RequestInterceptorHandler {
  RequestOptions? nextOptions;
  DioException? rejected;

  @override
  void next(RequestOptions requestOptions) {
    nextOptions = requestOptions;
  }

  @override
  void reject(
      DioException error, [
        bool callFollowingErrorInterceptor = false,
      ]) {
    rejected = error;
  }
}

class _ErrorHandler extends ErrorInterceptorHandler {
  DioException? nextError;
  DioException? rejectedError;

  @override
  void next(DioException err) {
    nextError = err;
  }

  @override
  void reject(
      DioException error, [
        bool callFollowingErrorInterceptor = false,
      ]) {
    rejectedError = error;
  }
}

void main() {
  late MockLocalStorageService storage;
  late AuthInterceptor interceptor;

  setUp(() {
    storage = MockLocalStorageService();
    interceptor = AuthInterceptor(storage);
  });

  RequestOptions req(String path) =>
      RequestOptions(path: path, method: 'GET');

  // ═══════════════════════════════════════════════════════════════
  group('onRequest — bearer header', () {
    test('attaches header for non-whitelisted path', () async {
      when(() => storage.readAccessToken()).thenAnswer((_) async => 'TOK');
      final h = _RequestHandler();

      await interceptor.onRequest(req('/cases'), h);

      expect(h.nextOptions, isNotNull);
      expect(h.nextOptions!.headers['Authorization'], 'Bearer TOK');
    });

    test('skips header for /auth/login', () async {
      when(() => storage.readAccessToken()).thenAnswer((_) async => 'TOK');
      final h = _RequestHandler();

      await interceptor.onRequest(req('/auth/login'), h);

      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('skips header + skips read for /auth/register', () async {
      final h = _RequestHandler();
      await interceptor.onRequest(req('/auth/register'), h);

      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
      verifyNever(() => storage.readAccessToken());
    });

    test('skips header for /auth/verify-email', () async {
      final h = _RequestHandler();
      await interceptor.onRequest(req('/auth/verify-email'), h);
      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('skips header for /auth/resend-otp', () async {
      final h = _RequestHandler();
      await interceptor.onRequest(req('/auth/resend-otp'), h);
      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('skips header for /auth/forgot-password', () async {
      final h = _RequestHandler();
      await interceptor.onRequest(req('/auth/forgot-password'), h);
      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('skips header for /auth/reset-password', () async {
      final h = _RequestHandler();
      await interceptor.onRequest(req('/auth/reset-password'), h);
      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('whitelist matches substrings (base url prefix)', () async {
      final h = _RequestHandler();
      await interceptor.onRequest(
        req('/api/v1/auth/verify-email'),
        h,
      );
      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('no header when token is null', () async {
      when(() => storage.readAccessToken()).thenAnswer((_) async => null);
      final h = _RequestHandler();
      await interceptor.onRequest(req('/cases'), h);
      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('no header when token is empty', () async {
      when(() => storage.readAccessToken()).thenAnswer((_) async => '');
      final h = _RequestHandler();
      await interceptor.onRequest(req('/cases'), h);
      expect(
        h.nextOptions!.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('onError — 401 handling', () {
    test('clears auth on 401 for protected path', () async {
      when(() => storage.clearAuth()).thenAnswer((_) async {});
      final h = _ErrorHandler();

      final err = DioException(
        requestOptions: req('/cases'),
        response: Response(
          requestOptions: req('/cases'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      await interceptor.onError(err, h);

      verify(() => storage.clearAuth()).called(1);
      expect(h.nextError, isNotNull);
    });

    test('does NOT clear auth on 401 for /auth/login', () async {
      final h = _ErrorHandler();
      final err = DioException(
        requestOptions: req('/auth/login'),
        response: Response(
          requestOptions: req('/auth/login'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      await interceptor.onError(err, h);

      verifyNever(() => storage.clearAuth());
    });

    test('does NOT clear auth on 500', () async {
      final h = _ErrorHandler();
      final err = DioException(
        requestOptions: req('/cases'),
        response: Response(
          requestOptions: req('/cases'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );

      await interceptor.onError(err, h);

      verifyNever(() => storage.clearAuth());
    });

    test('does NOT clear auth when no response', () async {
      final h = _ErrorHandler();
      final err = DioException(
        requestOptions: req('/cases'),
        type: DioExceptionType.connectionError,
      );

      await interceptor.onError(err, h);

      verifyNever(() => storage.clearAuth());
    });
  });
}