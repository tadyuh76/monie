import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class UpdateEmail implements UseCase<void, UpdateEmailParams> {
  final AuthRepository repository;

  UpdateEmail(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateEmailParams params) {
    return repository.updateEmail(params.newEmail);
  }
}

class UpdateEmailParams extends Equatable {
  final String newEmail;

  const UpdateEmailParams({required this.newEmail});

  @override
  List<Object?> get props => [newEmail];
}
