import 'package:dartz/dartz.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, bool>> isSignedIn();
  Future<Either<Failure, User>> getSignedInUser();
  Future<Either<Failure, bool>> isEmailVerified();
  Future<Either<Failure, void>> sendEmailVerification();
  Future<Either<Failure, void>> updateEmail(String newEmail);

  Future<Either<Failure, void>> resetPassword(String email);
  Future<Either<Failure, void>> confirmPasswordReset({
    required String password,
    required String token,
  });
  Future<Either<Failure, bool>> isRecoveryTokenValid(String token);
}
