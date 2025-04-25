import 'package:monie/core/config/supabase_config.dart';
import 'package:monie/core/error/exceptions.dart';
import 'package:monie/core/error/failures.dart';
import 'package:monie/features/authentication/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final GoTrueClient _authClient;

  SupabaseAuthService({GoTrueClient? authClient})
    : _authClient = authClient ?? Supabase.instance.client.auth;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _authClient.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw AuthFailure(message: 'Sign in failed');
      }

      // Fetch user metadata from Supabase user table
      final userData =
          await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', user.id)
              .single();

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        name: userData['name'] ?? '',
        photoUrl: userData['photo_url'],
        emailVerified: user.emailConfirmedAt != null,
      );
    } on AuthFailure catch (e) {
      throw AuthFailure(message: e.message);
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
      // Create the user with Supabase auth
      final response = await _authClient.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.monie://login-callback/',
        data: {'name': name},
      );

      final user = response.user;
      if (user == null) {
        throw AuthFailure(message: 'Sign up failed');
      }

      // Create user entry in the users table
      try {
        await Supabase.instance.client.from('users').insert({
          'id': user.id,
          'email': email,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
          'email_verified': false,
        });
      } catch (e) {
        print('Warning: Could not create user record: $e');
      }

      return UserModel(
        id: user.id,
        email: user.email ?? '',
        name: name,
        emailVerified: user.emailConfirmedAt != null,
      );
    } on AuthFailure catch (e) {
      throw AuthFailure(message: e.message);
    } catch (e) {
      throw ServerException(message: 'Registration error: ${e.toString()}');
    }
  }

  Future<bool> isEmailVerified() async {
    try {
      // Refresh the session to get the latest user data
      await _authClient.refreshSession();
      final user = _authClient.currentUser;
      if (user == null) return false;

      return user.emailConfirmedAt != null;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authClient.resend(
        type: OtpType.signup,
        email: _authClient.currentUser?.email,
      );
    } catch (e) {
      throw AuthFailure(
        message: 'Failed to send verification email: ${e.toString()}',
      );
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      await _authClient.updateUser(UserAttributes(email: newEmail));
    } catch (e) {
      throw AuthFailure(message: 'Failed to update email: ${e.toString()}');
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _authClient.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.passwordResetRedirectUrl,
      );
    } catch (e) {
      throw AuthFailure(
        message: 'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  Future<void> confirmPasswordReset({
    required String password,
    required String token,
  }) async {
    try {
      await _authClient.updateUser(
        UserAttributes(password: password),
        emailRedirectTo: SupabaseConfig.emailVerificationRedirectUrl,
      );
    } catch (e) {
      throw AuthFailure(message: 'Failed to reset password: ${e.toString()}');
    }
  }

  Future<bool> isRecoveryTokenValid(String token) async {
    try {
      // Unfortunately Supabase doesn't provide a direct way to check token validity
      // This is a simple placeholder to indicate a place where token validation would happen
      // In a real implementation, you might need to use a server-side function
      return token.isNotEmpty;
    } catch (e) {
      throw AuthFailure(
        message: 'Failed to validate recovery token: ${e.toString()}',
      );
    }
  }
}
