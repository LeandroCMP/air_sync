class ServerException implements Exception {
  ServerException(this.message);
  final String message;
}

class CacheException implements Exception {
  CacheException(this.message);
  final String message;
}

class UnauthorizedException implements Exception {}

class ForbiddenException implements Exception {}

class NotFoundException implements Exception {}

class ConflictException implements Exception {}

class ValidationException implements Exception {
  ValidationException(this.errors);
  final Map<String, dynamic> errors;
}
