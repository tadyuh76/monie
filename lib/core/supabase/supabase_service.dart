import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monie/core/config/supabase_config.dart';

class SupabaseService {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');

      if (!SupabaseConfig.isValid) {
        throw Exception('Missing Supabase configuration in .env file');
      }

      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );

      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      rethrow;
    }
  }

  static GoTrueClient get auth => Supabase.instance.client.auth;
  static SupabaseClient get client => Supabase.instance.client;
}
