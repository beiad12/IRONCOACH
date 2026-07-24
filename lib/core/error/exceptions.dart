/// Low-level exceptions thrown by data sources (remote/local). These are
/// caught at the repository boundary and mapped to [Failure]s — they must
/// never leak past the data layer.
class NetworkException implements Exception {
  const NetworkException([this.message]);
  final String? message;
}

class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message]);
  final String? message;
}

class CacheException implements Exception {
  const CacheException([this.message]);
  final String? message;
}

class NotFoundException implements Exception {
  const NotFoundException([this.message]);
  final String? message;
}

class ConflictException implements Exception {
  const ConflictException([this.message]);
  final String? message;
}

class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;
}
