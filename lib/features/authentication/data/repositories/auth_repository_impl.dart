import 'package:dartz/dartz.dart';
import 'package:monie/core/error/exceptions.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/network/network_info.dart';
import 'package:monie/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:monie/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';
import 'package:monie/core/utils/error_logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signIn(
          email: email,
          password: password,
        );
        localDataSource.cacheUser(user);
        return Right(user);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signUp(
          email: email,
          password: password,
          name: name,
        );
        await localDataSource.cacheUser(user);
        return Right(user);
      } on AuthException catch (e) {
        ErrorLogger.logError('AuthRepository.signUp', e, null);
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        ErrorLogger.logError('AuthRepository.signUp', e, null);
        return Left(ServerFailure(message: e.message));
      } catch (e, stackTrace) {
        ErrorLogger.logError('AuthRepository.signUp', e, stackTrace);
        return Left(
          ServerFailure(message: 'Registration failed: ${e.toString()}'),
        );
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      // Execute these operations concurrently to speed up the process
      await Future.wait([
        remoteDataSource.signOut(),
        localDataSource.removeUser(),
      ]);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSignedIn() async {
    try {
      final isSignedIn = await remoteDataSource.isSignedIn();
      return Right(isSignedIn);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, User>> getSignedInUser() async {
    try {
      if (await networkInfo.isConnected) {
        // Try to get from remote first
        try {
          final remoteUser = await remoteDataSource.getCurrentUser();
          // Cache the user locally
          await localDataSource.cacheUser(remoteUser);
          return Right(remoteUser);
        } on AuthException {
          // If not signed in remotely, try local cache
          final localUser = await localDataSource.getLastLoggedInUser();
          return Right(localUser);
        } catch (e) {
          return Left(ServerFailure(message: e.toString()));
        }
      } else {
        // If offline, try to get from local cache
        try {
          final localUser = await localDataSource.getLastLoggedInUser();
          return Right(localUser);
        } catch (e) {
          return Left(CacheFailure(message: e.toString()));
        }
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final isVerified = await remoteDataSource.isEmailVerified();
      return Right(isVerified);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.sendEmailVerification();
      return const Right(null);
    } on AuthException catch (e) {
      ErrorLogger.logError('AuthRepository.sendEmailVerification', e, null);
      return Left(AuthFailure(message: e.message));
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'AuthRepository.sendEmailVerification',
        e,
        stackTrace,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateEmail(String newEmail) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.updateEmail(newEmail);
      return const Right(null);
    } on AuthException catch (e) {
      ErrorLogger.logError('AuthRepository.updateEmail', e, null);
      return Left(AuthFailure(message: e.message));
    } catch (e, stackTrace) {
      ErrorLogger.logError('AuthRepository.updateEmail', e, stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on AuthException catch (e) {
      ErrorLogger.logError('AuthRepository.resetPassword', e, null);
      return Left(AuthFailure(message: e.message));
    } catch (e, stackTrace) {
      ErrorLogger.logError('AuthRepository.resetPassword', e, stackTrace);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmPasswordReset({
    required String password,
    required String token,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      await remoteDataSource.confirmPasswordReset(
        password: password,
        token: token,
      );
      return const Right(null);
    } on AuthException catch (e) {
      ErrorLogger.logError('AuthRepository.confirmPasswordReset', e, null);
      return Left(AuthFailure(message: e.message));
    } catch (e, stackTrace) {
      ErrorLogger.logError(
        'AuthRepository.confirmPasswordReset',
        e,
        stackTrace,
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isRecoveryTokenValid(String token) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final isValid = await remoteDataSource.isRecoveryTokenValid(token);
      return Right(isValid);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
