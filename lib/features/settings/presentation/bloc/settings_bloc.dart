import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/settings/data/repositories/settings_repository.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/domain/models/user_profile.dart';
import 'package:monie/features/settings/presentation/bloc/settings_event.dart';
import 'package:monie/features/settings/presentation/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;
  final AuthBloc? _authBloc; // Optional for synchronization
  AppSettings _currentSettings = const AppSettings();
  UserProfile? _currentProfile;

  SettingsBloc({
    required SettingsRepository repository, 
    AuthBloc? authBloc,
  }) : _repository = repository,
       _authBloc = authBloc,
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
      _currentSettings = await _repository.getAppSettings();
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
      final profile = await _repository.getUserProfile();
      if (profile != null) {
        _currentProfile = profile;
        emit(ProfileLoaded(
          profile: profile,
          settings: _currentSettings,
        ));
        
        // After loading the profile, try to ensure auth metadata is up-to-date
        // This helps when profile changes haven't been fully propagated
        if (profile.displayName == 'User' || profile.displayName.isEmpty) {
          // Try to update with better name if possible
          try {
            final updatedProfile = profile.copyWith(
              displayName: profile.email.split('@')[0],
            );
            await _repository.updateUserProfile(updatedProfile);
            _currentProfile = updatedProfile;
            emit(ProfileLoaded(
              profile: updatedProfile,
              settings: _currentSettings,
            ));
          } catch (e) {
            // Ignore any errors here, we already have a profile loaded
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
      
      final success = await _repository.saveAppSettings(newSettings);
      
      if (success) {
        _currentSettings = newSettings;
        emit(SettingsUpdateSuccess(
          message: 'Notification settings updated',
          settings: _currentSettings,
        ));
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
      final newSettings = _currentSettings.copyWith(
        themeMode: event.themeMode,
      );
      
      final success = await _repository.saveAppSettings(newSettings);
      
      if (success) {
        _currentSettings = newSettings;
        
        // Giữ lại thông tin profile trong trạng thái thành công
        if (_currentProfile != null) {
          emit(ProfileLoaded(
            profile: _currentProfile!,
            settings: _currentSettings,
          ));
        } else {
          emit(SettingsUpdateSuccess(
            message: 'Theme updated',
            settings: _currentSettings,
          ));
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
      final newSettings = _currentSettings.copyWith(
        language: event.language,
      );
      
      final success = await _repository.saveAppSettings(newSettings);
      
      if (success) {
        _currentSettings = newSettings;
        
        // Giữ lại thông tin profile trong trạng thái thành công
        if (_currentProfile != null) {
          emit(ProfileLoaded(
            profile: _currentProfile!,
            settings: _currentSettings,
          ));
        } else {
          emit(SettingsUpdateSuccess(
            message: 'Language updated',
            settings: _currentSettings,
          ));
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
    print('SettingsBloc: UpdateDisplayName event received: ${event.displayName}');
    if (_currentProfile == null) {
      print('SettingsBloc: ERROR - No user profile loaded');
      emit(const SettingsError('No user profile loaded'));
      return;
    }

    try {
      print('SettingsBloc: Creating updated profile with name: ${event.displayName}');
      final updatedProfile = _currentProfile!.copyWith(
        displayName: event.displayName,
      );
      
      print('SettingsBloc: Calling repository.updateUserProfile');
      final success = await _repository.updateUserProfile(updatedProfile);
      
      if (success) {
        print('SettingsBloc: Profile update successful');
        _currentProfile = updatedProfile;
        
        // If auth bloc is available, trigger a refresh
        if (_authBloc != null) {
          print('SettingsBloc: Triggering auth refresh');
          _authBloc!.add(RefreshUserEvent());
        }
        
        emit(ProfileUpdateSuccess(
          message: 'Profile name updated',
          profile: _currentProfile!,
          settings: _currentSettings,
        ));
      } else {
        print('SettingsBloc: Profile update failed');
        emit(const SettingsError('Failed to update profile name'));
      }
    } catch (e) {
      print('SettingsBloc: Error updating profile: ${e.toString()}');
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
      // Update the profile with the new avatar URL
      final updatedProfile = _currentProfile!.copyWith(
        avatarUrl: event.avatarUrl,
      );
      
      final success = await _repository.updateUserProfile(updatedProfile);
      
      if (success) {
        _currentProfile = updatedProfile;
        
        // If auth bloc is available, trigger a refresh
        if (_authBloc != null) {
          _authBloc!.add(RefreshUserEvent());
        }
        
        emit(ProfileUpdateSuccess(
          message: 'Avatar updated',
          profile: _currentProfile!,
          settings: _currentSettings,
        ));
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
    print('SettingsBloc: UpdatePhoneNumber event received: ${event.phoneNumber}');
    if (_currentProfile == null) {
      print('SettingsBloc: ERROR - No user profile loaded');
      emit(const SettingsError('No user profile loaded'));
      return;
    }

    try {
      print('SettingsBloc: Creating updated profile with phone: ${event.phoneNumber}');
      final updatedProfile = _currentProfile!.copyWith(
        phoneNumber: event.phoneNumber,
      );
      
      print('SettingsBloc: Calling repository.updateUserProfile');
      final success = await _repository.updateUserProfile(updatedProfile);
      
      if (success) {
        print('SettingsBloc: Phone number update successful');
        _currentProfile = updatedProfile;
        emit(ProfileUpdateSuccess(
          message: 'Phone number updated',
          profile: _currentProfile!,
          settings: _currentSettings,
        ));
      } else {
        print('SettingsBloc: Phone number update failed');
        emit(const SettingsError('Failed to update phone number'));
      }
    } catch (e) {
      print('SettingsBloc: Error updating phone number: ${e.toString()}');
      emit(SettingsError('Error updating phone number: ${e.toString()}'));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<SettingsState> emit,
  ) async {
    print('SettingsBloc: Password change requested');
    emit(const SettingsLoading());
    
    try {
      final result = await _repository.changePassword(
        event.currentPassword,
        event.newPassword,
      );
      
      if (result['success'] == true) {
        print('SettingsBloc: Password change was successful');
        emit(const PasswordChangeSuccess(
          message: 'Password changed successfully',
        ));
      } else {
        print('SettingsBloc: Password change failed: ${result['error']}');
        emit(SettingsError(result['error'] ?? 'Current password may be incorrect or another error occurred'));
      }
    } catch (e) {
      print('SettingsBloc: Password change error: ${e.toString()}');
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