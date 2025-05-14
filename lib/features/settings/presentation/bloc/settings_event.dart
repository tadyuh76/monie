import 'package:flutter/material.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';

abstract class SettingsEvent {
  const SettingsEvent();
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class LoadUserProfileEvent extends SettingsEvent {
  const LoadUserProfileEvent();
}

class UpdateNotificationsEvent extends SettingsEvent {
  final bool enabled;
  
  const UpdateNotificationsEvent({required this.enabled});
}

class UpdateThemeModeEvent extends SettingsEvent {
  final ThemeMode themeMode;
  
  const UpdateThemeModeEvent({required this.themeMode});
}

class UpdateLanguageEvent extends SettingsEvent {
  final AppLanguage language;
  
  const UpdateLanguageEvent({required this.language});
}

class UpdateDisplayNameEvent extends SettingsEvent {
  final String displayName;
  
  const UpdateDisplayNameEvent({required this.displayName});
}

class UpdateAvatarEvent extends SettingsEvent {
  final String avatarUrl;
  
  const UpdateAvatarEvent({required this.avatarUrl});
}

class UpdatePhoneNumberEvent extends SettingsEvent {
  final String phoneNumber;
  
  const UpdatePhoneNumberEvent({required this.phoneNumber});
}

class ChangePasswordEvent extends SettingsEvent {
  final String currentPassword;
  final String newPassword;
  
  const ChangePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });
} 