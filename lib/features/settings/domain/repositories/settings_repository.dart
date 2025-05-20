import '../models/app_settings.dart';
import '../models/user_profile.dart';

abstract class SettingsRepository {
  Future<AppSettings> getAppSettings();
  Future<bool> saveAppSettings(AppSettings settings);
  Future<UserProfile?> getUserProfile();
  Future<bool> updateUserProfile(UserProfile profile);
  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  );
  Future<String?> uploadAvatar(String filePath);
}
