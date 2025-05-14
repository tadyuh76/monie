import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/domain/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsRepository {
  final SupabaseClientManager _supabaseClient;
  final SharedPreferences _preferences;

  SettingsRepository({
    required SupabaseClientManager supabaseClient,
    required SharedPreferences preferences,
  })  : _supabaseClient = supabaseClient,
        _preferences = preferences;

  // App Settings
  Future<AppSettings> getAppSettings() async {
    try {
      // Load settings from SharedPreferences
      final notificationsEnabled = _preferences.getBool('notificationsEnabled') ?? true;
      final themeModeIndex = _preferences.getInt('themeMode') ?? ThemeMode.dark.index;
      final languageIndex = _preferences.getInt('language') ?? AppLanguage.english.index;

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

  Future<bool> saveAppSettings(AppSettings settings) async {
    try {
      await _preferences.setBool('notificationsEnabled', settings.notificationsEnabled);
      await _preferences.setInt('themeMode', settings.themeMode.index);
      await _preferences.setInt('language', settings.language.index);
      return true;
    } catch (e) {
      return false;
    }
  }

  // User Profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final User? user = _supabaseClient.client.auth.currentUser;
      
      if (user == null) {
        return null;
      }

      // Get the user's metadata from auth
      final userMetadata = user.userMetadata;
      final String nameFromAuth = userMetadata?['name'] ?? '';
      
      // First try to get profile from database
      try {
        final response = await _supabaseClient.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        // Database profile has priority for some fields
        if (response != null) {
          return UserProfile(
            id: user.id,
            // Use display_name from database or name from auth metadata or email
            displayName: response['display_name'] ?? (nameFromAuth.isNotEmpty ? nameFromAuth : user.email?.split('@')[0] ?? 'User'),
            email: user.email ?? '',
            avatarUrl: response['avatar_url'] ?? userMetadata?['avatar_url'],
            phoneNumber: response['phone_number'] ?? user.phone,
          );
        }
      } catch (e) {
        print('Error fetching profile from database: $e');
      }
      
      // If not found in database or error occurred, create from auth data
      return UserProfile(
        id: user.id,
        displayName: nameFromAuth.isNotEmpty ? nameFromAuth : user.email?.split('@')[0] ?? 'User',
        email: user.email ?? '',
        avatarUrl: userMetadata?['avatar_url'],
        phoneNumber: user.phone,
      );
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      print('SettingsRepo: updateUserProfile started for user ${profile.id}');
      print('SettingsRepo: update data - name: ${profile.displayName}, phone: ${profile.phoneNumber}');
      
      final User? user = _supabaseClient.client.auth.currentUser;
      
      if (user == null) {
        print('SettingsRepo: ERROR - No authenticated user found');
        return false;
      }

      print('SettingsRepo: Found authenticated user: ${user.id}');
      
      // Try both database and auth updates, prioritizing auth first
      bool success = false;
      
      // First update auth metadata as it's more reliable
      try {
        print('SettingsRepo: Updating auth metadata');
        await _supabaseClient.client.auth.updateUser(
          UserAttributes(
            data: {
              'name': profile.displayName,
              'avatar_url': profile.avatarUrl,
            },
          ),
        );
        print('SettingsRepo: Auth metadata updated successfully');
        success = true;
      } catch (authError) {
        print('SettingsRepo: ERROR updating auth metadata: $authError');
        // Continue to try database update even if auth update fails
      }
      
      // Then update database profile
      try {
        print('SettingsRepo: Updating profile in database');
        final response = await _supabaseClient.client
            .from('profiles')
            .upsert({
              'id': profile.id,
              'display_name': profile.displayName,
              'avatar_url': profile.avatarUrl,
              'phone_number': profile.phoneNumber,
              'updated_at': DateTime.now().toIso8601String(),
              'email': profile.email,
            });

        print('SettingsRepo: Database profile updated successfully');
        success = true;
      } catch (dbError) {
        print('SettingsRepo: ERROR updating profile in database: $dbError');
        // If we haven't succeeded with auth update, this is a complete failure
        if (!success) {
          return false;
        }
      }
      
      // Refresh the user data to ensure it's up to date
      try {
        print('SettingsRepo: Refreshing user session');
        await _supabaseClient.client.auth.refreshSession();
        print('SettingsRepo: Session refreshed');
      } catch (refreshError) {
        print('SettingsRepo: Warning - Error refreshing session: $refreshError');
        // This is not critical, we can still return success if earlier operations worked
      }
      
      return success;
    } catch (e) {
      print('SettingsRepo: ERROR updating user profile: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      print('ChangePassword: Starting password change process');
      final User? user = _supabaseClient.client.auth.currentUser;
      
      if (user == null) {
        print('ChangePassword: No current user found');
        return {'success': false, 'error': 'User not authenticated'};
      }

      if (user.email == null) {
        print('ChangePassword: User has no email');
        return {'success': false, 'error': 'User has no email address'};
      }

      print('ChangePassword: Found user with email ${user.email}');
      
      try {
        // Verify current password by attempting a sign-in
        print('ChangePassword: Verifying current password by signing in');
        await _supabaseClient.client.auth.signInWithPassword(
          email: user.email!,
          password: currentPassword,
        );
      } catch (signInError) {
        print('ChangePassword: Current password verification failed: $signInError');
        return {'success': false, 'error': 'Current password is incorrect'};
      }

      print('ChangePassword: Current password verified successfully');
      
      try {
        // Change password
        print('ChangePassword: Updating password');
        await _supabaseClient.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (updateError) {
        print('ChangePassword: Password update failed: $updateError');
        return {'success': false, 'error': 'Failed to update password: $updateError'};
      }

      print('ChangePassword: Password updated successfully');
      return {'success': true};
    } catch (e) {
      print('ChangePassword ERROR: ${e.toString()}');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Avatar handling
  Future<String?> uploadAvatar(String filePath) async {
    try {
      print('SettingsRepository: uploadAvatar started for file: $filePath');
      final User? user = _supabaseClient.client.auth.currentUser;
      
      if (user == null) {
        print('SettingsRepository: ERROR - No authenticated user found');
        return null;
      }

      final String fileExt = filePath.split('.').last.toLowerCase();
      final String fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final File file = File(filePath);
      
      if (!file.existsSync()) {
        print('SettingsRepository: ERROR - File not found: $filePath');
        return null;
      }
      
      // 1. Trước tiên kiểm tra xem bucket 'avatars' có tồn tại không
      try {
        print('SettingsRepository: Checking if bucket exists');
        final buckets = await _supabaseClient.client.storage.listBuckets();
        bool hasBucket = buckets.any((bucket) => bucket.name == 'avatars');
        
        if (!hasBucket) {
          print('SettingsRepository: Bucket "avatars" does not exist, trying to create it');
          // Tạo bucket nếu không tồn tại
          await _supabaseClient.client.storage.createBucket('avatars');
          print('SettingsRepository: Bucket "avatars" created successfully');
        }
      } catch (bucketError) {
        print('SettingsRepository: ERROR checking/creating bucket: $bucketError');
        // Vẫn tiếp tục và thử upload, trong trường hợp lỗi chỉ là quyền kiểm tra bucket
      }

      // Thay thế bằng cách sử dụng path local để lưu trong profile
      try {
        // Update avatar URL in user profile directly
        // Đây là giải pháp tạm thời nếu không thể upload lên Supabase
        print('SettingsRepository: Updating profile with local file path');
        await updateUserProfile(
          UserProfile(
            id: user.id,
            displayName: user.userMetadata?['name'] ?? '',
            email: user.email ?? '',
            avatarUrl: filePath,
            phoneNumber: user.phone,
          ),
        );
        
        // Chúng ta sẽ trả về đường dẫn cục bộ như một phương án dự phòng
        // TOTO: Cần thay đổi để sử dụng đường dẫn tạm thời cho mục đích demo
        return filePath;
      } catch (localPathError) {
        print('SettingsRepository: ERROR updating profile with local path: $localPathError');
      }

      // Vẫn thử upload lên Supabase nếu cập nhật local path thành công
      try {
        print('SettingsRepository: Uploading file to storage bucket');
        final response = await _supabaseClient.client.storage
            .from('avatars')
            .upload(fileName, file, fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true
            ));

        print('SettingsRepository: Storage response: $response');
        
        if (response.isNotEmpty) {
          // Get public URL
          final String publicUrl = _supabaseClient.client.storage
              .from('avatars')
              .getPublicUrl(fileName);
          
          print('SettingsRepository: Avatar uploaded successfully, URL: $publicUrl');
          
          // Update user metadata with new avatar URL
          await _supabaseClient.client.auth.updateUser(
            UserAttributes(
              data: {
                'avatar_url': publicUrl,
              },
            ),
          );
          
          print('SettingsRepository: User metadata updated with new avatar URL');
          
          return publicUrl;
        }
      } catch (uploadError) {
        print('SettingsRepository: ERROR uploading to Supabase: $uploadError');
        // Đã cập nhật local path ở trên, vẫn trả về đường dẫn local
        return filePath;
      }

      // Nếu có lỗi nhưng đã cập nhật đường dẫn local, vẫn trả về đường dẫn local
      return filePath;
    } catch (e) {
      print('SettingsRepository: ERROR in uploadAvatar: $e');
      return null;
    }
  }
} 