import 'package:dentspace/core/error/exception_mapper.dart';
import 'package:dentspace/core/error/exceptions.dart';
import 'package:dentspace/core/error/failures.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════
  group('mapErrorToFailure', () {
    test('DioException(ServerException) → ServerFailure with statusCode', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: const ServerException(
          message: 'Bad request',
          statusCode: 400,
        ),
      );
      final failure = mapErrorToFailure(dio);

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Bad request');
      expect((failure as ServerFailure).statusCode, 400);
    });

    test('DioException(NetworkException) → NetworkFailure', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: const NetworkException(message: 'no internet'),
      );
      final failure = mapErrorToFailure(dio);

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, 'no internet');
    });

    test('DioException(UnauthorizedException) → UnauthorizedFailure', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        error: const UnauthorizedException(message: 'expired'),
      );
      final failure = mapErrorToFailure(dio);

      expect(failure, isA<UnauthorizedFailure>());
    });

    test('DioException(unknown inner) → ServerFailure', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/x'),
        message: 'weird error',
      );
      final failure = mapErrorToFailure(dio);

      expect(failure, isA<ServerFailure>());
    });

    test('raw ServerException → ServerFailure', () {
      final failure = mapErrorToFailure(
        const ServerException(message: 'raw', statusCode: 500),
      );
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 500);
    });

    test('raw NetworkException → NetworkFailure', () {
      expect(
        mapErrorToFailure(const NetworkException(message: 'net')),
        isA<NetworkFailure>(),
      );
    });

    test('raw UnauthorizedException → UnauthorizedFailure', () {
      expect(
        mapErrorToFailure(const UnauthorizedException()),
        isA<UnauthorizedFailure>(),
      );
    });

    test('raw CacheException → CacheFailure', () {
      expect(
        mapErrorToFailure(const CacheException(message: 'cache miss')),
        isA<CacheFailure>(),
      );
    });

    test('unknown error → UnknownFailure', () {
      expect(mapErrorToFailure(Exception('boom')), isA<UnknownFailure>());
      expect(mapErrorToFailure('plain string'), isA<UnknownFailure>());
    });
  });

  // ═══════════════════════════════════════════════════════════════
  group('extractValidationErrors', () {
    test('returns null for non-DioException', () {
      expect(extractValidationErrors(Exception('x')), isNull);
      expect(extractValidationErrors('string'), isNull);
    });

    test('returns null when response.data is not a Map', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: 'plain text',
        ),
      );
      expect(extractValidationErrors(dio), isNull);
    });

    test('returns null when errors key is missing', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: {'detail': 'x'},
        ),
      );
      expect(extractValidationErrors(dio), isNull);
    });

    test('parses field-level errors correctly', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: {
            'errors': [
              {
                'loc': ['body', 'email'],
                'msg': 'invalid email',
              },
              {
                'loc': ['body', 'password'],
                'msg': 'too short',
              },
              {
                'loc': ['body', 'password'],
                'msg': 'missing digit',
              },
            ],
          },
        ),
      );

      final errors = extractValidationErrors(dio);

      expect(errors, isNotNull);
      expect(errors!['email'], ['invalid email']);
      expect(errors['password'], hasLength(2));
      expect(errors['password'], contains('too short'));
      expect(errors['password'], contains('missing digit'));
    });

    test('handles single-element loc arrays', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: {
            'errors': [
              {'loc': ['field_a'], 'msg': 'bad'},
            ],
          },
        ),
      );

      final errors = extractValidationErrors(dio);
      expect(errors, isNotNull);
      expect(errors!['field_a'], ['bad']);
    });

    test('skips malformed items silently', () {
      final dio = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          data: {
            'errors': [
              'not a map',
              {'loc': 'not a list', 'msg': 'bad'},
              {'loc': ['body', 'ok'], 'msg': 'valid'},
              {'loc': ['body', 'x']}, // no msg
            ],
          },
        ),
      );

      final errors = extractValidationErrors(dio);
      expect(errors, isNotNull);
      expect(errors!.keys, contains('ok'));
      expect(errors.keys, isNot(contains('x')));
    });
  });
}