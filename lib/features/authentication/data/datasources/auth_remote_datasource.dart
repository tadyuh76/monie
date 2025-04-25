import 'package:monie/core/error/exceptions.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/core/supabase/supabase_auth_service.dart';
import 'package:monie/features/authentication/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> resetPassword(String email);
  Future<void> confirmPasswordReset({
    required String password,
    required String token,
  });
  Future<bool> isRecoveryTokenValid(String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseAuthService authService;
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl({
    required this.authService,
    required this.supabaseClient,
  });

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await authService.signIn(email: email, password: password);
    } catch (e) {
      if (e is AuthFailure) rethrow;
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
      return await authService.signUp(
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw AuthFailure(message: 'Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<bool> isSignedIn() async {
    return supabaseClient.auth.currentUser != null;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final user = supabaseClient.auth.currentUser;

    if (user == null) {
      throw AuthFailure(message: 'Not signed in');
    }

    try {
      // Get user metadata from Supabase user table
      final userData =
          await supabaseClient
              .from('users')
              .select()
              .eq('id', user.id)
              .single();

      // Update email verification status if needed
      final emailVerified = user.emailConfirmedAt != null;
      if (userData['email_verified'] != emailVerified && emailVerified) {
        await supabaseClient
            .from('users')
            .update({'email_verified': emailVerified})
            .eq('id', user.id);
      }

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['photo_url'],
        emailVerified: emailVerified,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    try {
      return await authService.isEmailVerified();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await authService.sendEmailVerification();
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await authService.updateEmail(newEmail);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await authService.resetPassword(email: email);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String password,
    required String token,
  }) async {
    try {
      await authService.confirmPasswordReset(password: password, token: token);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> isRecoveryTokenValid(String token) async {
    try {
      return await authService.isRecoveryTokenValid(token);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
