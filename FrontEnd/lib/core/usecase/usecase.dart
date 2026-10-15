import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Base contract for every use case.
///
///   • [Result] – the value produced on success.
///   • [Params] – the input; use [NoParams] when there is none.
abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

/// Marker for use cases that take no input.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Marker for stream-based use cases.
abstract class StreamUseCase<Result, Params> {
  Stream<Either<Failure, Result>> call(Params params);
}