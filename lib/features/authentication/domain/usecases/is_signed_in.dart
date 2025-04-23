import 'package:dartz/dartz.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class IsSignedIn extends UseCase<bool, NoParams> {
  final AuthRepository repository;

  IsSignedIn(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.isSignedIn();
  }
}
