import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper class for Supabase URLs
class SupabaseUrlHelper {
  /// Gets the domain part of the Supabase URL from .env
  static String getSupabaseDomain() {
    // Get the Supabase URL from .env
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';

    // Extract just the domain part (remove https:// if present)
    final domainOnly = supabaseUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '');

    return domainOnly;
  }

  /// Gets the verification URL to use in email redirects
  static String getVerificationUrl() {
    final domain = getSupabaseDomain();
    if (domain.isEmpty) {
      // Fallback if domain is not found
      return 'https://app.supabase.com/auth/v1/verify';
    }

    return 'https://$domain/auth/v1/verify';
  }

  /// Gets the deep link URL for the app
  static String getAppDeepLinkUrl() {
    return 'com.tadyuh.monie://login-callback/';
  }

  /// Gets the redirect URL to use for authentication
  /// This URL should be where the user is redirected after email confirmation
  static String getRedirectUrl() {
    // Use the Supabase site's auth confirmation success page
    // This will work on any device and show a success message
    return 'https://app.supabase.com/auth/callback';
  }
}
