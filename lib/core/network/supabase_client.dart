import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton class for Supabase client configuration
class SupabaseClientManager {
  static late final SupabaseClientManager _instance;
  static late final GoTrueClient _auth;
  static late final Supabase _supabase;

  /// Private constructor for singleton
  SupabaseClientManager._();

  static Future<void> initialize() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    // Validate that environment variables are set
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'Supabase configuration missing!\n'
        'Please set SUPABASE_URL and SUPABASE_ANON_KEY in your .env file.\n'
        'See README.md for instructions.',
      );
    }

    // Validate that placeholder values are not being used
    if (supabaseUrl.contains('your-project-id') || 
        supabaseAnonKey.contains('your-supabase-anon-key')) {
      throw Exception(
        'Supabase configuration contains placeholder values!\n'
        'Please replace the placeholder values in your .env file with actual Supabase credentials.\n'
        'Get your credentials from: https://app.supabase.com/project/_/settings/api\n'
        'Current values:\n'
        'SUPABASE_URL: $supabaseUrl\n'
        'SUPABASE_ANON_KEY: ${supabaseAnonKey.substring(0, 20)}...',
      );
    }

    _supabase = await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );

    _auth = _supabase.client.auth;
    _instance = SupabaseClientManager._();
  }

  /// Get Supabase instance
  static SupabaseClientManager get instance {
    return _instance;
  }

  /// Get Supabase auth client
  GoTrueClient get auth => _auth;

  /// Get Supabase client
  SupabaseClient get client => Supabase.instance.client;
}
