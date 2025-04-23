import 'package:dartz/dartz.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class VerifyEmail implements UseCase<void, NoParams> {
  final AuthRepository repository;

  VerifyEmail(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.sendEmailVerification();
  }
}
