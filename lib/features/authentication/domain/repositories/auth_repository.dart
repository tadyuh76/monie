import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/authentication/domain/entities/user.dart';
import 'package:dartz/dartz.dart';

/// Authentication repository interface in the domain layer
abstract class AuthRepository {
  /// Gets the currently authenticated user if any
  Future<Either<Failure, User?>> getCurrentUser();

  /// Signs up a new user with email and password
  /// Email verification will be sent automatically
  Future<Either<Failure, void>> signUp({
    required String email,
    required String password,
    String? displayName,
    String? profileImageUrl,
    String colorMode = 'light',
    String language = 'en',
  });

  /// Signs in a user with email and password
  /// Only verified emails can sign in
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });

  /// Signs out the current user
  Future<Either<Failure, void>> signOut();

  /// Resends the verification email
  Future<Either<Failure, void>> resendVerificationEmail({
    required String email,
  });

  /// Checks if an email is verified
  Future<Either<Failure, bool>> isEmailVerified({required String email});

  /// Sends a password reset email
  Future<Either<Failure, void>> resetPassword({required String email});

  /// Checks if an email exists and its verification status
  /// Returns a map with 'exists' and 'verified' keys
  Future<Either<Failure, Map<String, bool>>> checkEmailExists({
    required String email,
  });
}
