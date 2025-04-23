import 'package:dartz/dartz.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class IsEmailVerified extends UseCase<bool, NoParams> {
  final AuthRepository repository;

  IsEmailVerified(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.isEmailVerified();
  }
}
