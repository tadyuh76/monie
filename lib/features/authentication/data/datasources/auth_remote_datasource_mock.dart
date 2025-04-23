import 'package:flutter/foundation.dart';
import 'package:monie/core/error/exceptions.dart';
import 'package:monie/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:monie/features/authentication/data/models/user_model.dart';

class AuthRemoteDataSourceMock implements AuthRemoteDataSource {
  // In-memory storage for simulating user auth
  UserModel? _currentUser;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('Mock: SignIn with $email');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Simple validation for demo
    if (email.isEmpty || !email.contains('@')) {
      throw AuthException(message: 'Invalid email format');
    }

    if (password.length < 6) {
      throw AuthException(message: 'Password must be at least 6 characters');
    }

    // Create a mock user
    _currentUser = UserModel(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: email.split('@').first,
      emailVerified: false,
    );

    return _currentUser!;
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    debugPrint('Mock: SignUp with $email, name: $name');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Simple validation
    if (email.isEmpty || !email.contains('@')) {
      throw AuthException(message: 'Invalid email format');
    }

    if (password.length < 6) {
      throw AuthException(message: 'Password must be at least 6 characters');
    }

    if (name.isEmpty) {
      throw AuthException(message: 'Name cannot be empty');
    }

    // Create a mock user
    _currentUser = UserModel(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      name: name,
      emailVerified: false,
    );

    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    debugPrint('Mock: SignOut');
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<bool> isSignedIn() async {
    return _currentUser != null;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentUser == null) {
      throw AuthException(message: 'User not signed in');
    }
    return _currentUser!;
  }

  @override
  Future<bool> isEmailVerified() async {
    if (_currentUser == null) {
      throw AuthException(message: 'User not signed in');
    }
    return _currentUser!.emailVerified;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (_currentUser == null) {
      throw AuthException(message: 'User not signed in');
    }
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate email verification sent
    debugPrint('Mock: Email verification sent to ${_currentUser!.email}');
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    if (_currentUser == null) {
      throw AuthException(message: 'User not signed in');
    }

    if (newEmail.isEmpty || !newEmail.contains('@')) {
      throw AuthException(message: 'Invalid email format');
    }

    await Future.delayed(const Duration(milliseconds: 800));

    // Update the user's email
    _currentUser = UserModel(
      id: _currentUser!.id,
      email: newEmail,
      name: _currentUser!.name,
      photoUrl: _currentUser!.photoUrl,
      emailVerified: false, // Reset verification status
    );

    debugPrint('Mock: Email updated to $newEmail');
  }
}
