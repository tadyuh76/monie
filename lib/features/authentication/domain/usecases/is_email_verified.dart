import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class IsEmailVerified {
  final AuthRepository repository;

  IsEmailVerified(this.repository);

  Future<Either<Failure, bool>> call(IsEmailVerifiedParams params) async {
    return await repository.isEmailVerified(email: params.email);
  }
}

class IsEmailVerifiedParams extends Equatable {
  final String email;

  const IsEmailVerifiedParams({required this.email});

  @override
  List<Object> get props => [email];
}
