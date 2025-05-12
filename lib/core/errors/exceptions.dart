/// Base exception class for all exceptions in the app
abstract class AppException implements Exception {
  final String message;

  AppException({required this.message});

  @override
  String toString() => message;
}

/// Exception thrown when there is a server error
class ServerException extends AppException {
  ServerException({required super.message});
}

/// Exception thrown when there is an error with local data source
class CacheException extends AppException {
  CacheException({required super.message});
}

/// Exception thrown when there is no internet connection
class NetworkException extends AppException {
  NetworkException({required super.message});
}

/// Exception thrown when authentication fails
class AuthException extends AppException {
  AuthException({required super.message});
}

/// Exception for validation errors
class ValidationException extends AppException {
  ValidationException({required super.message});
}
