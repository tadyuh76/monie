import 'dart:developer' as developer;

class ErrorLogger {
  static void logError(
    String errorSource,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    developer.log(
      '=== ERROR IN $errorSource ===',
      name: 'ErrorLogger',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void logWarning(String source, String message) {
    developer.log('⚠️ WARNING: $message', name: source);
  }
}
