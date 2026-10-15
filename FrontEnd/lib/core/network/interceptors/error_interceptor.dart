import 'package:dio/dio.dart';

import '../../error/exceptions.dart';

/// Maps Dio errors into domain exceptions, so the repository layer has
/// one consistent vocabulary to work with.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.receiveTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(message: 'Connection timed out'),
            type: err.type,
          ),
        );
        return;

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(),
            type: err.type,
          ),
        );
        return;

      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 500;
        final data = err.response?.data;
        final message = _extractMessage(data) ?? _defaultFor(status);

        if (status == 401) {
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const UnauthorizedException(),
              response: err.response,
              type: err.type,
            ),
          );
          return;
        }

        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ServerException(message: message, statusCode: status),
            response: err.response,
            type: err.type,
          ),
        );
        return;

      case DioExceptionType.cancel:
        handler.next(err);
        return;

      case DioExceptionType.badCertificate:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(message: 'Bad certificate'),
            type: err.type,
          ),
        );
        return;
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      if (data['detail'] is String) return data['detail'] as String;
      if (data['message'] is String) return data['message'] as String;
    }
    return null;
  }

  String _defaultFor(int status) {
    if (status >= 500) return 'Server error, please try again later.';
    if (status == 403) return 'You do not have permission to do that.';
    if (status == 404) return 'The requested resource was not found.';
    if (status == 422) return 'Some of the provided data is invalid.';
    return 'Request failed (code $status)';
  }
}