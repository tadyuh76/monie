import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANNON_KEY'] ?? '';

  // Password reset flow paths
  static String get passwordResetRedirectUrl =>
      'io.supabase.monie://reset-password/';
  static String get emailVerificationRedirectUrl =>
      'io.supabase.monie://email-verification/';

  // Validate configuration
  static bool get isValid => url.isNotEmpty && anonKey.isNotEmpty;
}
