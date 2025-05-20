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
   

    final supabaseUrl = dotenv.env['SUPABASE_URL']!;
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

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
