import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class CheckEmailExistsParams {
  final String email;

  CheckEmailExistsParams({required this.email});
}

class CheckEmailExists {
  final AuthRepository repository;

  CheckEmailExists(this.repository);

  Future<Either<Failure, Map<String, bool>>> call(
    CheckEmailExistsParams params,
  ) async {
    return await repository.checkEmailExists(email: params.email);
  }
}
