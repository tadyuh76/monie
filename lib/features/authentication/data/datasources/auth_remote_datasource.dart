import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:monie/core/error/exceptions.dart';
import 'package:monie/features/authentication/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signOut();
  Future<bool> isSignedIn();
  Future<UserModel> getCurrentUser();
  Future<bool> isEmailVerified();
  Future<void> sendEmailVerification();
  Future<void> updateEmail(String newEmail);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException(message: 'User not found');
      }

      final firebaseUser = userCredential.user!;
      final userDoc =
          await firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        throw AuthException(message: 'User data not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['photoUrl'],
        emailVerified: firebaseUser.emailVerified,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Authentication failed');
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create the user first
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException(message: 'Failed to create user');
      }

      final firebaseUser = userCredential.user!;

      // Update user profile - wrap in try/catch to prevent this from causing the entire registration to fail
      try {
        await firebaseUser.updateDisplayName(name);
      } catch (e) {
        print('Warning: Could not update display name: $e');
        // Continue with the process
      }

      // Send verification email - handle errors separately
      try {
        await firebaseUser.sendEmailVerification();
      } catch (e) {
        print('Warning: Could not send verification email: $e');
        // Continue with the process
      }

      // Create user document in Firestore
      try {
        await firestore.collection('users').doc(firebaseUser.uid).set({
          'email': email,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false,
        });
      } catch (e) {
        print('Warning: Could not create user document in Firestore: $e');
        // We don't want to throw here as the user is already created in Auth
      }

      return UserModel(
        id: firebaseUser.uid,
        email: email,
        name: name,
        emailVerified: false,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Registration failed');
    } catch (e) {
      throw ServerException(message: 'Registration error: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Clear any cached credentials or tokens first
      await Future.wait([
        firebaseAuth.signOut(),
        // Add any additional cleanup operations here if needed
        // For example, clearing specific cached data
      ]);
    } catch (e) {
      throw AuthException(message: 'Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<bool> isSignedIn() async {
    return firebaseAuth.currentUser != null;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;

    if (firebaseUser == null) {
      throw AuthException(message: 'Not signed in');
    }

    try {
      // Reload user to get latest data
      await firebaseUser.reload();

      final userDoc =
          await firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        throw AuthException(message: 'User data not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Update emailVerified status in Firestore if needed
      if (userData['emailVerified'] != firebaseUser.emailVerified &&
          firebaseUser.emailVerified) {
        await firestore.collection('users').doc(firebaseUser.uid).update({
          'emailVerified': firebaseUser.emailVerified,
        });
      }

      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['photoUrl'],
        emailVerified: firebaseUser.emailVerified,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return false;

    // Reload user to get latest state
    await firebaseUser.reload();
    return firebaseUser.emailVerified;
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw AuthException(message: 'No user signed in');
      }

      await firebaseUser.sendEmailVerification();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Failed to send verification email',
      );
    } catch (e) {
      throw ServerException(
        message: 'Error sending verification: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw AuthException(message: 'No user signed in');
      }

      // Use verifyBeforeUpdateEmail instead of directly updating
      await firebaseUser.verifyBeforeUpdateEmail(newEmail);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Failed to update email');
    } catch (e) {
      throw ServerException(message: 'Error updating email: ${e.toString()}');
    }
  }
}
