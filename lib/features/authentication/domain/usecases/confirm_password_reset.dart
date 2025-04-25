import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class ConfirmPasswordReset
    implements UseCase<void, ConfirmPasswordResetParams> {
  final AuthRepository repository;

  ConfirmPasswordReset(this.repository);

  @override
  Future<Either<Failure, void>> call(ConfirmPasswordResetParams params) async {
    return await repository.confirmPasswordReset(
      password: params.password,
      token: params.token,
    );
  }
}

class ConfirmPasswordResetParams extends Equatable {
  final String password;
  final String token;

  const ConfirmPasswordResetParams({
    required this.password,
    required this.token,
  });

  @override
  List<Object?> get props => [password, token];
}
