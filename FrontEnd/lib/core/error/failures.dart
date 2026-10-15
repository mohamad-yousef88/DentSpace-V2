import 'package:equatable/equatable.dart';

/// High-level error type exposed to the placeholder layer.
///
/// The placeholder layer never sees raw exceptions — it only sees
/// [Failure]s returned by use cases wrapped in `Either<Failure, T>`.
abstract class Failure extends Equatable {
  const Failure({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, this.statusCode});
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache failure'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Session expired'});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, this.errors});
  final Map<String, List<String>>? errors;

  @override
  List<Object?> get props => [message, errors];
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'Something went wrong'});
}