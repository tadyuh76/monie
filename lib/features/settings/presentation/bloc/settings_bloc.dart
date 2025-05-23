import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/settings/domain/usecases/get_app_settings.dart';
import 'package:monie/features/settings/domain/usecases/save_app_settings.dart';
import 'package:monie/features/settings/domain/usecases/get_user_profile.dart';
import 'package:monie/features/settings/domain/usecases/update_user_profile.dart';
import 'package:monie/features/settings/domain/usecases/change_password.dart';
import 'package:monie/features/settings/domain/usecases/upload_avatar.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/domain/models/user_profile.dart';
import 'package:monie/features/settings/presentation/bloc/settings_event.dart';
import 'package:monie/features/settings/presentation/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetAppSettings getAppSettings;
  final SaveAppSettings saveAppSettings;
  final GetUserProfile getUserProfile;
  final UpdateUserProfile updateUserProfile;
  final ChangePassword changePassword;
  final UploadAvatar uploadAvatar;
  final AuthBloc? _authBloc;
  AppSettings _currentSettings = const AppSettings();
  UserProfile? _currentProfile;

  SettingsBloc({
    required this.getAppSettings,
    required this.saveAppSettings,
    required this.getUserProfile,
    required this.updateUserProfile,
    required this.changePassword,
    required this.uploadAvatar,
    AuthBloc? authBloc,
  }) : _authBloc = authBloc,
       super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<LoadUserProfileEvent>(_onLoadUserProfile);
    on<UpdateNotificationsEvent>(_onUpdateNotifications);
    on<UpdateThemeModeEvent>(_onUpdateThemeMode);
    on<UpdateLanguageEvent>(_onUpdateLanguage);
    on<UpdateDisplayNameEvent>(_onUpdateDisplayName);
    on<UpdateAvatarEvent>(_onUpdateAvatar);
    on<UpdatePhoneNumberEvent>(_onUpdatePhoneNumber);
    on<ChangePasswordEvent>(_onChangePassword);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      _currentSettings = await getAppSettings();
      emit(SettingsLoaded(_currentSettings));
    } catch (e) {
      emit(SettingsError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfileEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final profile = await getUserProfile();
      if (profile != null) {
        _currentProfile = profile;
        emit(ProfileLoaded(profile: profile, settings: _currentSettings));
        if (profile.displayName == 'User' || profile.displayName.isEmpty) {
          try {
            final updatedProfile = profile.copyWith(
              displayName: profile.email.split('@')[0],
            );
            await updateUserProfile(updatedProfile);
            _currentProfile = updatedProfile;
            emit(
              ProfileLoaded(
                profile: updatedProfile,
                settings: _currentSettings,
              ),
            );
          } catch (e) {
            debugPrint('Error updating profile: $e');
          }
        }
      } else {
        emit(const SettingsError('No user profile found'));
      }
    } catch (e) {
      emit(SettingsError('Failed to load profile: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateNotifications(
    UpdateNotificationsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final newSettings = _currentSettings.copyWith(
        notificationsEnabled: event.enabled,
      );
      final success = await saveAppSettings(newSettings);
      if (success) {
        _currentSettings = newSettings;
        emit(
          SettingsUpdateSuccess(
            message: 'Notification settings updated',
            settings: _currentSettings,
          ),
        );
      } else {
        emit(const SettingsError('Failed to update notification settings'));
      }
    } catch (e) {
      emit(SettingsError('Error updating notifications: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final newSettings = _currentSettings.copyWith(themeMode: event.themeMode);
      final success = await saveAppSettings(newSettings);
      if (success) {
        _currentSettings = newSettings;
        if (_currentProfile != null) {
          emit(
            ProfileLoaded(
              profile: _currentProfile!,
              settings: _currentSettings,
            ),
          );
        } else {
          emit(
            SettingsUpdateSuccess(
              message: 'Theme updated',
              settings: _currentSettings,
            ),
          );
        }
      } else {
        emit(const SettingsError('Failed to update theme'));
      }
    } catch (e) {
      emit(SettingsError('Error updating theme: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateLanguage(
    UpdateLanguageEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final newSettings = _currentSettings.copyWith(language: event.language);
      final success = await saveAppSettings(newSettings);
      if (success) {
        _currentSettings = newSettings;
        if (_currentProfile != null) {
          emit(
            ProfileLoaded(
              profile: _currentProfile!,
              settings: _currentSettings,
            ),
          );
        } else {
          emit(
            SettingsUpdateSuccess(
              message: 'Language updated',
              settings: _currentSettings,
            ),
          );
        }
      } else {
        emit(const SettingsError('Failed to update language'));
      }
    } catch (e) {
      emit(SettingsError('Error updating language: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayNameEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentProfile == null) {
      emit(const SettingsError('No user profile loaded'));
      return;
    }
    try {
      final updatedProfile = _currentProfile!.copyWith(
        displayName: event.displayName,
      );
      final success = await updateUserProfile(updatedProfile);
      if (success) {
        _currentProfile = updatedProfile;
        if (_authBloc != null) {
          _authBloc.add(RefreshUserEvent());
        }
        emit(
          ProfileUpdateSuccess(
            message: 'Profile name updated',
            profile: _currentProfile!,
            settings: _currentSettings,
          ),
        );
        if (_authBloc != null) {
          _authBloc.add(RefreshUserEvent());
        }
        add(LoadUserProfileEvent());
      } else {
        emit(const SettingsError('Failed to update profile name'));
      }
    } catch (e) {
      emit(SettingsError('Error updating profile: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateAvatar(
    UpdateAvatarEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentProfile == null) {
      emit(const SettingsError('No user profile loaded'));
      return;
    }
    try {
      // Use the uploadAvatar use case to upload the avatar and get the URL
      final avatarUrl = await uploadAvatar(event.avatarUrl);
      if (avatarUrl == null) {
        emit(const SettingsError('Failed to upload avatar'));
        return;
      }
      // Update the profile with the new avatar URL
      final updatedProfile = _currentProfile!.copyWith(avatarUrl: avatarUrl);
      final success = await updateUserProfile(updatedProfile);
      if (success) {
        _currentProfile = updatedProfile;
        if (_authBloc != null) {
          _authBloc.add(RefreshUserEvent());
        }
        emit(
          ProfileUpdateSuccess(
            message: 'Avatar updated',
            profile: _currentProfile!,
            settings: _currentSettings,
          ),
        );
        add(LoadUserProfileEvent());
      } else {
        emit(const SettingsError('Failed to update avatar'));
      }
    } catch (e) {
      emit(SettingsError('Error updating avatar: ${e.toString()}'));
    }
  }

  Future<void> _onUpdatePhoneNumber(
    UpdatePhoneNumberEvent event,
    Emitter<SettingsState> emit,
  ) async {
    if (_currentProfile == null) {
      emit(const SettingsError('No user profile loaded'));
      return;
    }

    try {
      final updatedProfile = _currentProfile!.copyWith(
        phoneNumber: event.phoneNumber,
      );

      final success = await updateUserProfile(updatedProfile);

      if (success) {
        _currentProfile = updatedProfile;
        emit(
          ProfileUpdateSuccess(
            message: 'Phone number updated',
            profile: _currentProfile!,
            settings: _currentSettings,
          ),
        );
      } else {
        emit(const SettingsError('Failed to update phone number'));
      }
    } catch (e) {
      emit(SettingsError('Error updating phone number: ${e.toString()}'));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    try {
      final result = await changePassword(
        event.currentPassword,
        event.newPassword,
      );

      if (result['success'] == true) {
        emit(
          const PasswordChangeSuccess(message: 'Password changed successfully'),
        );
      } else {
        emit(
          SettingsError(
            result['error'] ??
                'Current password may be incorrect or another error occurred',
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error changing password';

      // Provide more specific error messages
      if (e.toString().contains('incorrect password')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error, please check your connection';
      }

      emit(SettingsError('$errorMessage: ${e.toString()}'));
    }
  }
}
