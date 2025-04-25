import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class CheckRecoveryToken implements UseCase<bool, CheckRecoveryTokenParams> {
  final AuthRepository repository;

  CheckRecoveryToken(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckRecoveryTokenParams params) async {
    return await repository.isRecoveryTokenValid(params.token);
  }
}

class CheckRecoveryTokenParams extends Equatable {
  final String token;

  const CheckRecoveryTokenParams({required this.token});

  @override
  List<Object?> get props => [token];
}
