import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class GetCurrentUserEvent extends AuthEvent {}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;

  const SignUpEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignOutEvent extends AuthEvent {}

class ResendVerificationEmailEvent extends AuthEvent {
  final String email;

  const ResendVerificationEmailEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class CheckEmailVerificationEvent extends AuthEvent {
  final String email;
  final bool isSilent;

  const CheckEmailVerificationEvent({
    required this.email,
    this.isSilent = false,
  });

  @override
  List<Object> get props => [email, isSilent];
}

class ResetPasswordEvent extends AuthEvent {
  final String email;

  const ResetPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class CheckEmailExistsEvent extends AuthEvent {
  final String email;

  const CheckEmailExistsEvent({required this.email});

  @override
  List<Object> get props => [email];
}
