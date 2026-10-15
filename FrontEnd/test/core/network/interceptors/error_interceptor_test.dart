import 'package:dentspace/core/error/exceptions.dart';
import 'package:dentspace/core/network/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures both next / reject calls, so we can assert what the
/// interceptor forwards downstream.
class _Handler extends ErrorInterceptorHandler {
  DioException? forwarded;
  bool wasRejected = false;

  @override
  void next(DioException err) {
    forwarded = err;
  }

  @override
  void reject(
      DioException error, [
        bool callFollowingErrorInterceptor = false,
      ]) {
    forwarded = error;
    wasRejected = true;
  }
}

void main() {
  late ErrorInterceptor interceptor;

  setUp(() {
    interceptor = ErrorInterceptor();
  });

  RequestOptions r(String path) => RequestOptions(path: path);

  DioException dio({
    required DioExceptionType type,
    int? status,
    dynamic data,
  }) =>
      DioException(
        requestOptions: r('/api/v1/x'),
        type: type,
        response: status != null
            ? Response(
          requestOptions: r('/api/v1/x'),
          statusCode: status,
          data: data,
        )
            : null,
      );

  // ═══════════════════════════════════════════════════════════════
  group('timeout → NetworkException', () {
    for (final type in const [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('$type', () {
        final h = _Handler();
        interceptor.onError(dio(type: type), h);

        expect(h.wasRejected, isTrue);
        expect(h.forwarded!.error, isA<NetworkException>());
        expect(
          (h.forwarded!.error as NetworkException).message.toLowerCase(),
          contains('timed out'),
        );
      });
    }
  });

  // ═══════════════════════════════════════════════════════════════
  group('connection failure → NetworkException', () {
    test('connectionError', () {
      final h = _Handler();
      interceptor.onError(
        dio(type: DioExceptionType.connectionError),
        h,
      );
      expect(h.forwarded!.error, isA<NetworkException>());
    });

    test('unknown', () {
      final h = _Handler();
      interceptor.onError(dio(type: DioExceptionType.unknown), h);
      expect(h.forwarded!.error, isA<NetworkException>());
    });

    test('badCertificate', () {
      final h = _Handler();
      interceptor.onError(
        dio(type: DioExceptionType.badCertificate),
        h,
      );
      expect(h.forwarded!.error, isA<NetworkException>());
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('cancel → passthrough', () {
    test('calls next, not reject', () {
      final h = _Handler();
      interceptor.onError(dio(type: DioExceptionType.cancel), h);

      expect(h.wasRejected, isFalse);
      expect(h.forwarded, isNotNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('badResponse', () {
    test('401 → UnauthorizedException', () {
      final h = _Handler();
      interceptor.onError(
        dio(
          type: DioExceptionType.badResponse,
          status: 401,
          data: {'detail': 'expired'},
        ),
        h,
      );
      expect(h.forwarded!.error, isA<UnauthorizedException>());
    });

    test('404 with detail → ServerException(message, 404)', () {
      final h = _Handler();
      interceptor.onError(
        dio(
          type: DioExceptionType.badResponse,
          status: 404,
          data: {'detail': 'Case not found'},
        ),
        h,
      );
      final inner = h.forwarded!.error as ServerException;
      expect(inner.message, 'Case not found');
      expect(inner.statusCode, 404);
    });

    test('extracts from {message: "..."} as well', () {
      final h = _Handler();
      interceptor.onError(
        dio(
          type: DioExceptionType.badResponse,
          status: 400,
          data: {'message': 'Custom error'},
        ),
        h,
      );
      final inner = h.forwarded!.error as ServerException;
      expect(inner.message, 'Custom error');
    });

    test('500 with no body → default server message', () {
      final h = _Handler();
      interceptor.onError(
        dio(type: DioExceptionType.badResponse, status: 500),
        h,
      );
      final inner = h.forwarded!.error as ServerException;
      expect(inner.message.toLowerCase(), contains('server error'));
      expect(inner.statusCode, 500);
    });

    test('403 → permission message', () {
      final h = _Handler();
      interceptor.onError(
        dio(type: DioExceptionType.badResponse, status: 403),
        h,
      );
      final inner = h.forwarded!.error as ServerException;
      expect(inner.message.toLowerCase(), contains('permission'));
    });

    test('422 → invalid data message', () {
      final h = _Handler();
      interceptor.onError(
        dio(type: DioExceptionType.badResponse, status: 422),
        h,
      );
      final inner = h.forwarded!.error as ServerException;
      expect(inner.message.toLowerCase(), contains('invalid'));
    });
  });
}