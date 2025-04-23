import 'package:dartz/dartz.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class GetSignedInUser {
  final AuthRepository repository;

  GetSignedInUser(this.repository);

  Future<Either<Failure, User>> call() async {
    return await repository.getSignedInUser();
  }
}
