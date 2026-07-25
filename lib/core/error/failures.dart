import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

/// Domain-level failure taxonomy. Repositories translate low-level
/// exceptions (network, database, platform) into these before they cross
/// into the domain/presentation layers, so use cases and widgets never
/// depend on `dio`, `postgrest`, or `drift` types.
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network([String? message]) = NetworkFailure;

  const factory Failure.server({
    required String message,
    int? statusCode,
  }) = ServerFailure;

  const factory Failure.unauthorized([String? message]) = UnauthorizedFailure;

  const factory Failure.validation(String message) = ValidationFailure;

  const factory Failure.notFound([String? message]) = NotFoundFailure;

  const factory Failure.cache([String? message]) = CacheFailure;

  const factory Failure.conflict([String? message]) = ConflictFailure;

  const factory Failure.rateLimited([String? message]) = RateLimitedFailure;

  const factory Failure.unexpected([String? message]) = UnexpectedFailure;

  const Failure._();

  /// Human-readable message safe to show directly in the UI.
  String get displayMessage => when(
        network: (m) =>
            m ?? 'No internet connection. Please check your network.',
        server: (m, _) => m,
        unauthorized: (m) =>
            m ?? 'Your session has expired. Please sign in again.',
        validation: (m) => m,
        notFound: (m) => m ?? 'We couldn\'t find what you were looking for.',
        cache: (m) => m ?? 'Something went wrong reading local data.',
        conflict: (m) =>
            m ?? 'This was already updated elsewhere. Please refresh.',
        rateLimited: (m) => m ?? 'Too many requests. Please try again shortly.',
        unexpected: (m) => m ?? 'Something unexpected happened.',
      );
}
