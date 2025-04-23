import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:monie/core/error/exceptions.dart';
import 'package:monie/features/authentication/data/models/user_model.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthService({firebase_auth.FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: 'Sign in failed');
      }

      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        photoUrl: user.photoURL,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Authentication failed');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException(message: 'Sign up failed');
      }

      // Try to update display name - handle potential errors
      try {
        await user.updateDisplayName(name);
      } catch (e) {
        print('Warning: Could not update display name: $e');
        // Continue with the process - this isn't critical
      }

      // Try to send verification email - handle potential errors separately
      try {
        await user.sendEmailVerification();
      } catch (e) {
        print('Warning: Could not send verification email: $e');
        // Continue with the process - this isn't critical
      }

      return UserModel(
        id: user.uid,
        email: user.email ?? '',
        name:
            name, // Use the provided name since displayName might not be updated yet
        photoUrl: user.photoURL,
        emailVerified: user.emailVerified,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Registration failed');
    } catch (e) {
      throw ServerException(
        message: 'Unexpected error during registration: ${e.toString()}',
      );
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    // Reload user to get latest state
    await user.reload();
    return user.emailVerified;
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException(message: 'No user signed in');
      }
      await user.sendEmailVerification();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Failed to send verification email',
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw AuthException(message: 'No user signed in');
    }

    try {
      await user.verifyBeforeUpdateEmail(newEmail);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Failed to update email');
    }
  }
}
