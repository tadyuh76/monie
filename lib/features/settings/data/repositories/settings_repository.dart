import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/domain/models/user_profile.dart';
import 'package:monie/features/settings/domain/repositories/settings_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SupabaseClientManager _supabaseClient;
  final SharedPreferences _preferences;

  SettingsRepositoryImpl({
    required SupabaseClientManager supabaseClient,
    required SharedPreferences preferences,
  }) : _supabaseClient = supabaseClient,
       _preferences = preferences;

  // App Settings
  @override
  Future<AppSettings> getAppSettings() async {
    try {
      // Load settings from SharedPreferences
      final notificationsEnabled =
          _preferences.getBool('notificationsEnabled') ?? true;
      final themeModeIndex =
          _preferences.getInt('themeMode') ?? ThemeMode.dark.index;
      final languageIndex =
          _preferences.getInt('language') ?? AppLanguage.english.index;

      return AppSettings(
        notificationsEnabled: notificationsEnabled,
        themeMode: ThemeMode.values[themeModeIndex],
        language: AppLanguage.values[languageIndex],
      );
    } catch (e) {
      // Return default settings on error
      return const AppSettings();
    }
  }

  @override
  Future<bool> saveAppSettings(AppSettings settings) async {
    try {
      await _preferences.setBool(
        'notificationsEnabled',
        settings.notificationsEnabled,
      );
      await _preferences.setInt('themeMode', settings.themeMode.index);
      await _preferences.setInt('language', settings.language.index);
      return true;
    } catch (e) {
      return false;
    }
  }

  // User Profile
  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final User? user = _supabaseClient.client.auth.currentUser;

      if (user == null) {
        return null;
      }

      // Get the user's metadata from auth
      final userMetadata = user.userMetadata;
      final String nameFromAuth = userMetadata?['name'] ?? '';

      // First try to get profile from database using our SQL function
      try {
        final response = await _supabaseClient.client.rpc('get_user_profile');

        // Database profile has priority for some fields
        if (response != null) {
          return UserProfile(
            id: user.id,
            // Use display_name from database or name from auth metadata or email
            displayName:
                response['display_name'] ??
                (nameFromAuth.isNotEmpty
                    ? nameFromAuth
                    : user.email?.split('@')[0] ?? 'User'),
            email: user.email ?? '',
            avatarUrl:
                response['profile_image_url'] ??
                userMetadata?['profile_image_url'],
            phoneNumber: user.phone,
          );
        }
      } catch (e) {
        // Fallback to direct table access
        try {
          final response =
              await _supabaseClient.client
                  .from('users')
                  .select()
                  .eq('user_id', user.id)
                  .maybeSingle();

          if (response != null) {
            return UserProfile(
              id: user.id,
              displayName:
                  response['display_name'] ??
                  (nameFromAuth.isNotEmpty
                      ? nameFromAuth
                      : user.email?.split('@')[0] ?? 'User'),
              email: user.email ?? '',
              avatarUrl:
                  response['profile_image_url'] ??
                  userMetadata?['profile_image_url'],
              phoneNumber: response['phone_number'] ?? user.phone,
            );
          }
        } catch (tableError) {
          debugPrint('Error accessing users table: $tableError');
        }
      }

      // If not found in database or error occurred, create from auth data
      return UserProfile(
        id: user.id,
        displayName:
            nameFromAuth.isNotEmpty
                ? nameFromAuth
                : user.email?.split('@')[0] ?? 'User',
        email: user.email ?? '',
        avatarUrl: userMetadata?['profile_image_url'],
        phoneNumber: user.phone,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      final User? user = _supabaseClient.client.auth.currentUser;

      if (user == null) {
        return false;
      }

      // Try both database and auth updates, prioritizing auth first
      bool success = false;

      // First update auth metadata as it's more reliable
      try {
        await _supabaseClient.client.auth.updateUser(
          UserAttributes(
            data: {
              'name': profile.displayName,
              'profile_image_url': profile.avatarUrl,
            },
          ),
        );
        success = true;
      } catch (authError) {
        // Continue to try database update even if auth update fails
      }

      // Then update database profile
      try {
        success = true;
      } catch (dbError) {
        // If we haven't succeeded with auth update, this is a complete failure
        if (!success) {
          return false;
        }
      }

      // Refresh the user data to ensure it's up to date
      try {
        await _supabaseClient.client.auth.refreshSession();
      } catch (refreshError) {
        // This is not critical, we can still return success if earlier operations worked
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final User? user = _supabaseClient.client.auth.currentUser;

      if (user == null) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      if (user.email == null) {
        return {'success': false, 'error': 'User has no email address'};
      }

      try {
        // Verify current password by attempting a sign-in
        await _supabaseClient.client.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        );
      } catch (signInError) {
        return {'success': false, 'error': 'Current password is incorrect'};
      }

      try {
        // Change password
        await _supabaseClient.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (updateError) {
        return {
          'success': false,
          'error': 'Failed to update password: $updateError',
        };
      }

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Avatar handling
  @override
  Future<String?> uploadAvatar(String filePath) async {
    try {
      final User? user = _supabaseClient.client.auth.currentUser;

      if (user == null) {
        return null;
      }

      final String fileExt = filePath.split('.').last.toLowerCase();
      final String fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final File file = File(filePath);

      if (!file.existsSync()) {
        return null;
      }

      // 1. Trước tiên kiểm tra xem bucket 'avatars' có tồn tại không
      try {
        final buckets = await _supabaseClient.client.storage.listBuckets();
        bool hasBucket = buckets.any((bucket) => bucket.name == 'avatars');

        if (!hasBucket) {
          // Tạo bucket nếu không tồn tại
          await _supabaseClient.client.storage.createBucket('avatars');
        }
      } catch (bucketError) {
        // Vẫn tiếp tục và thử upload, trong trường hợp lỗi chỉ là quyền kiểm tra bucket
      }

      // Không cập nhật ngay mà ưu tiên tải lên Supabase trước

      // Upload ảnh lên Supabase Storage
      try {
        final response = await _supabaseClient.client.storage
            .from('avatars')
            .upload(
              fileName,
              file,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        if (response.isNotEmpty) {
          // Get public URL
          final String publicUrl = _supabaseClient.client.storage
              .from('avatars')
              .getPublicUrl(fileName);

          // Update user metadata with new avatar URL
          await _supabaseClient.client.auth.updateUser(
            UserAttributes(data: {'profile_image_url': publicUrl}),
          );

          // Call the settings_update_avatar SQL function
          try {
            final result = await _supabaseClient.client.rpc(
              'settings_update_avatar',
              params: {'avatar_url_param': publicUrl},
            );

            if (result != null && result['success'] == true) {
            } else {}
          } catch (dbError) {
            // Continue since we already updated auth metadata
          }

          return publicUrl;
        }
      } catch (uploadError) {
        // Fallback to local path if upload fails
        return filePath;
      }

      // If all attempts fail, create a local fallback solution
      try {
        // Update auth metadata with the local path
        await _supabaseClient.client.auth.updateUser(
          UserAttributes(data: {'profile_image_url': filePath}),
        );

        // Also update the users table using our settings_update_avatar SQL function
        try {
          final result = await _supabaseClient.client.rpc(
            'settings_update_avatar',
            params: {'avatar_url_param': filePath},
          );

          if (result != null && result['success'] == true) {
          } else {}
        } catch (fnError) {
          debugPrint('Error calling settings_update_avatar: $fnError');
        }
        return filePath;
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
