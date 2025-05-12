import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repository;

  SignUp(this.repository);

  Future<Either<Failure, void>> call(SignUpParams params) async {
    return await repository.signUp(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
      profileImageUrl: params.profileImageUrl,
      colorMode: params.colorMode,
      language: params.language,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String? displayName;
  final String? profileImageUrl;
  final String colorMode;
  final String language;

  const SignUpParams({
    required this.email,
    required this.password,
    this.displayName,
    this.profileImageUrl,
    this.colorMode = 'light',
    this.language = 'en',
  });

  @override
  List<Object?> get props => [
    email,
    password,
    displayName,
    profileImageUrl,
    colorMode,
    language,
  ];
}
