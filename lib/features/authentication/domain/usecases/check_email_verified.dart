import 'package:dartz/dartz.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class CheckEmailVerified implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  CheckEmailVerified(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.isEmailVerified();
  }
}
