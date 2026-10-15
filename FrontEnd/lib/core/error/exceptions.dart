/// Low-level exceptions thrown by data sources (network, cache, etc.).
///
/// These are caught in the repository layer and mapped to [Failure]s.
class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;
}

class CacheException implements Exception {
  const CacheException({this.message = 'Cache error'});
  final String message;
}

class NetworkException implements Exception {
  const NetworkException({this.message = 'No network connection'});
  final String message;
}

class UnauthorizedException implements Exception {
  const UnauthorizedException({this.message = 'Unauthorized'});
  final String message;
}

class ValidationException implements Exception {
  const ValidationException({required this.message, this.errors});
  final String message;
  final Map<String, List<String>>? errors;
}