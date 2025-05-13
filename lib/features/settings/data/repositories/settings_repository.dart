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
            displayName: response['display_name'] ?? nameFromAuth.isNotEmpty ? nameFromAuth : user.email?.split('@')[0] ?? 'User',
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
      final User? user = _supabaseClient.client.auth.currentUser;
      
      if (user == null) {
        return false;
      }

      // Update database profile
      await _supabaseClient.client
          .from('profiles')
          .upsert({
            'id': profile.id,
            'display_name': profile.displayName,
            'avatar_url': profile.avatarUrl,
            'phone_number': profile.phoneNumber,
            'updated_at': DateTime.now().toIso8601String(),
            'email': profile.email,
          });

      // Also update auth metadata where possible
      await _supabaseClient.client.auth.updateUser(
        UserAttributes(
          data: {
            'name': profile.displayName,
            'avatar_url': profile.avatarUrl,
          },
        ),
      );

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final User? user = _supabaseClient.client.auth.currentUser;
      
      if (user == null) {
        return false;
      }

      // Verify current password by attempting a sign-in
      await _supabaseClient.client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );

      // Change password
      await _supabaseClient.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Avatar handling
  Future<String?> uploadAvatar(String filePath) async {
    try {
      final User? user = _supabaseClient.client.auth.currentUser;
      
      if (user == null) {
        return null;
      }

      final String fileExt = filePath.split('.').last;
      final String fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final File file = File(filePath);
      
      final response = await _supabaseClient.client.storage
          .from('avatars')
          .upload(fileName, file);

      if (response.isNotEmpty) {
        // Get public URL
        final String publicUrl = _supabaseClient.client.storage
            .from('avatars')
            .getPublicUrl(fileName);
        
        return publicUrl;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
} 