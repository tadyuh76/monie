import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/domain/models/user_profile.dart';

abstract class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  
  const SettingsLoaded(this.settings);
}

class ProfileLoading extends SettingsState {
  const ProfileLoading();
}

class ProfileLoaded extends SettingsState {
  final UserProfile profile;
  final AppSettings settings;
  
  const ProfileLoaded({
    required this.profile,
    required this.settings,
  });
}

class SettingsUpdateSuccess extends SettingsState {
  final String message;
  final AppSettings settings;
  
  const SettingsUpdateSuccess({
    required this.message,
    required this.settings,
  });
}

class ProfileUpdateSuccess extends SettingsState {
  final String message;
  final UserProfile profile;
  final AppSettings settings;
  
  const ProfileUpdateSuccess({
    required this.message,
    required this.profile,
    required this.settings,
  });
}

class PasswordChangeSuccess extends SettingsState {
  final String message;
  
  const PasswordChangeSuccess({
    required this.message,
  });
}

class SettingsError extends SettingsState {
  final String message;
  
  const SettingsError(this.message);
} 