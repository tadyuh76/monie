import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
    String? displayName,
    String? profileImageUrl,
    String colorMode = 'light',
    String language = 'en',
  }) async {
    try {
      // First check if the email exists
      final emailStatus = await remoteDataSource.checkEmailExists(email: email);

      // If email exists and is verified, return an error
      if (emailStatus['exists'] == true && emailStatus['verified'] == true) {
        return Left(
          AuthFailure(
            message: 'This email is already registered. Please sign in.',
          ),
        );
      }

      // If email exists but is not verified, we can proceed
      // Or if the email doesn't exist, we can also proceed
      await remoteDataSource.signUp(
        email: email,
        password: password,
        displayName: displayName,
        profileImageUrl: profileImageUrl,
        colorMode: colorMode,
        language: language,
      );
      return const Right(null);
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signIn(
        email: email,
        password: password,
      );
      return Right(user);
    } on EmailVerificationFailure catch (e) {
      return Left(e);
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resendVerificationEmail({
    required String email,
  }) async {
    try {
      await remoteDataSource.resendVerificationEmail(email: email);
      return const Right(null);
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified({required String email}) async {
    try {
      final isVerified = await remoteDataSource.isEmailVerified(email: email);
      return Right(isVerified);
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await remoteDataSource.resetPassword(email: email);
      return const Right(null);
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> checkEmailExists({
    required String email,
  }) async {
    try {
      final result = await remoteDataSource.checkEmailExists(email: email);
      return Right(result);
    } on AuthFailure catch (e) {
      return Left(e);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
