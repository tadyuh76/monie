import 'package:equatable/equatable.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class SignUpSuccess extends AuthState {
  final String email;

  const SignUpSuccess(this.email);

  @override
  List<Object?> get props => [email];
}

class SignInSuccess extends AuthState {
  final User user;

  const SignInSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class VerificationEmailSent extends AuthState {
  final String email;

  const VerificationEmailSent(this.email);

  @override
  List<Object?> get props => [email];
}

class PasswordResetEmailSent extends AuthState {
  final String email;

  const PasswordResetEmailSent(this.email);

  @override
  List<Object?> get props => [email];
}

class EmailVerificationStatus extends AuthState {
  final bool isVerified;

  const EmailVerificationStatus(this.isVerified);

  @override
  List<Object?> get props => [isVerified];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthInfo extends AuthState {
  final String message;

  const AuthInfo(this.message);

  @override
  List<Object?> get props => [message];
}

class EmailExistsState extends AuthState {
  final bool exists;
  final bool verified;
  final String email;

  const EmailExistsState({
    required this.exists,
    required this.verified,
    required this.email,
  });

  @override
  List<Object?> get props => [exists, verified, email];
}
