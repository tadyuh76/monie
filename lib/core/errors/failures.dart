import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

/// Server failure when API requests fail
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Cache failure for local storage issues
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Network failure for connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Authentication failure for auth-related issues
class AuthFailure extends Failure {
  const AuthFailure({required super.message});
}

/// Email verification failure
class EmailVerificationFailure extends Failure {
  const EmailVerificationFailure({required super.message});
}

/// Speech recognition not available failure
class SpeechNotAvailableFailure extends Failure {
  const SpeechNotAvailableFailure()
      : super(message: 'Speech recognition is not available on this device');
}

/// Invalid command failure
class InvalidCommandFailure extends Failure {
  const InvalidCommandFailure({required super.message});
}

/// Speech recognition failure
class SpeechRecognitionFailure extends Failure {
  const SpeechRecognitionFailure({required super.message});
}