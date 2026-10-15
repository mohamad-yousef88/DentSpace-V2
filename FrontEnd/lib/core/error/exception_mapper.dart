import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Converts any thrown object into a [Failure].
Failure mapErrorToFailure(Object error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is ServerException) {
      return ServerFailure(
        message: inner.message,
        statusCode: inner.statusCode,
      );
    }
    if (inner is NetworkException) {
      return NetworkFailure(message: inner.message);
    }
    if (inner is UnauthorizedException) {
      return UnauthorizedFailure(message: inner.message);
    }
    return ServerFailure(message: error.message ?? 'Network error');
  }
  if (error is ServerException) {
    return ServerFailure(message: error.message, statusCode: error.statusCode);
  }
  if (error is NetworkException) {
    return NetworkFailure(message: error.message);
  }
  if (error is UnauthorizedException) {
    return UnauthorizedFailure(message: error.message);
  }
  if (error is CacheException) {
    return CacheFailure(message: error.message);
  }
  return UnknownFailure(message: error.toString());
}

/// Extracts field-level validation errors from a 422 response, if any.
Map<String, List<String>>? extractValidationErrors(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  if (data is! Map) return null;
  final errors = data['errors'];
  if (errors is! List) return null;

  final result = <String, List<String>>{};
  for (final item in errors) {
    if (item is! Map) continue;
    final loc = item['loc'];
    final msg = item['msg'];
    if (loc is! List || msg is! String) continue;
    // loc typically: ["body", "email"]
    final field = loc.length >= 2 ? loc.last.toString() : loc.first.toString();
    result.putIfAbsent(field, () => []).add(msg);
  }
  return result.isEmpty ? null : result;
}