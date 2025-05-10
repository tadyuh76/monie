import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class ResendVerificationEmail {
  final AuthRepository repository;

  ResendVerificationEmail(this.repository);

  Future<Either<Failure, void>> call(
    ResendVerificationEmailParams params,
  ) async {
    return await repository.resendVerificationEmail(email: params.email);
  }
}

class ResendVerificationEmailParams extends Equatable {
  final String email;

  const ResendVerificationEmailParams({required this.email});

  @override
  List<Object> get props => [email];
}
