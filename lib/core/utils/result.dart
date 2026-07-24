import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// The standard return type for every repository and use-case method in
/// IronCoach: either a [Failure] (`Left`) or a success value `T` (`Right`).
///
/// Using `Either` (from `fpdart`) instead of throwing lets callers handle
/// errors exhaustively at compile time via `.match`/`.fold` rather than
/// relying on try/catch at arbitrary call sites.
typedef Result<T> = Either<Failure, T>;

/// Convenience constructors mirroring `Either.left` / `Either.right` so
/// call sites read as domain language instead of FP jargon.
extension ResultX<T> on T {
  Result<T> get asSuccess => Right(this);
}

extension FailureX on Failure {
  Result<T> asFailure<T>() => Left(this);
}
