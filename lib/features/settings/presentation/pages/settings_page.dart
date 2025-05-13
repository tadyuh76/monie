import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:monie/features/settings/presentation/bloc/settings_event.dart';
import 'package:monie/features/settings/presentation/bloc/settings_state.dart';
import 'package:monie/features/settings/presentation/widgets/settings_section_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // First load settings, then the user profile
    context.read<SettingsBloc>().add(const LoadSettingsEvent());
    
    // Use a small delay to ensure we get the correct sequence of loading
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<SettingsBloc>().add(const LoadUserProfileEvent());
      }
    });
    
    // Also initialize controllers with current auth data if available
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _displayNameController.text = authState.user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        // Upload the image to storage
        final bloc = context.read<SettingsBloc>();
        
        // Show loading indicator
        _showLoadingDialog('Uploading avatar...');

        // Simulate uploading (in a real app, you would call a repository method here)
        await Future.delayed(const Duration(seconds: 1));

        // For demonstration, we're directly passing the URL
        // In a real app, you'd use the repository to upload the file and get the URL
        bloc.add(UpdateAvatarEvent(avatarUrl: image.path));

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('Failed to upload image: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.expense,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsError) {
          _showErrorSnackBar(state.message);
        } else if (state is SettingsUpdateSuccess) {
          _showSuccessSnackBar(state.message);
        } else if (state is ProfileUpdateSuccess) {
          _showSuccessSnackBar(state.message);
          
          // Update text controllers with new profile data
          if (_isEditingProfile) {
            setState(() {
              _isEditingProfile = false;
            });
          }
        } else if (state is PasswordChangeSuccess) {
          _showSuccessSnackBar(state.message);
          setState(() {
            _isChangingPassword = false;
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          });
        } else if (state is ProfileLoaded) {
          // Update text controllers with profile data
          _displayNameController.text = state.profile.displayName;
          _phoneNumberController.text = state.profile.phoneNumber ?? '';
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SettingsState state) {
    if (state is SettingsLoading || state is SettingsInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(state),
          const SizedBox(height: 24),
          SettingsSectionWidget(
            title: 'App Settings',
            children: [
              _buildNotificationsToggle(state),
              const Divider(color: AppColors.divider),
              _buildThemeSelector(state),
              const Divider(color: AppColors.divider),
              _buildLanguageSelector(state),
            ],
          ),
          const SizedBox(height: 24),
          if (!_isEditingProfile && !_isChangingPassword)
            SettingsSectionWidget(
              title: 'Account',
              children: [
                _buildEditProfileButton(),
                const Divider(color: AppColors.divider),
                _buildChangePasswordButton(),
              ],
            ),
          if (_isEditingProfile) _buildEditProfileForm(state),
          if (_isChangingPassword) _buildChangePasswordForm(),
          const SizedBox(height: 100), // Extra space at bottom
        ],
      ),
    );
  }

  Widget _buildProfileSection(SettingsState state) {
    // Try to get the profile from auth state first for consistent naming
    final authState = context.watch<AuthBloc>().state;
    final authName = authState is Authenticated ? authState.user.displayName : null;
    
    final profile = state is ProfileLoaded
        ? state.profile
        : state is ProfileUpdateSuccess
            ? state.profile
            : null;

    if (profile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Use authName if available, otherwise fall back to profile name
    final displayName = authName ?? profile.displayName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              InkWell(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: profile.avatarUrl != null
                      ? _getImageProvider(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 20),
                  color: Colors.white,
                  onPressed: _pickImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                profile.phoneNumber!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  Widget _buildNotificationsToggle(SettingsState state) {
    final settings = state is ProfileLoaded
        ? state.settings
        : state is SettingsLoaded
            ? state.settings
            : state is SettingsUpdateSuccess
                ? state.settings
                : state is ProfileUpdateSuccess
                    ? state.settings
                    : const AppSettings();

    return SwitchListTile(
      title: const Text(
        'Notifications',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Enable push notifications',
        style: TextStyle(color: Colors.white70),
      ),
      value: settings.notificationsEnabled,
      activeColor: AppColors.primary,
      onChanged: (value) {
        context
            .read<SettingsBloc>()
            .add(UpdateNotificationsEvent(enabled: value));
      },
    );
  }

  Widget _buildThemeSelector(SettingsState state) {
    final settings = state is ProfileLoaded
        ? state.settings
        : state is SettingsLoaded
            ? state.settings
            : state is SettingsUpdateSuccess
                ? state.settings
                : state is ProfileUpdateSuccess
                    ? state.settings
                    : const AppSettings();

    return ListTile(
      title: const Text(
        'Theme',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        _getThemeModeName(settings.themeMode),
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: DropdownButton<ThemeMode>(
        value: settings.themeMode,
        dropdownColor: AppColors.surface,
        underline: Container(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        onChanged: (ThemeMode? newValue) {
          if (newValue != null) {
            context
                .read<SettingsBloc>()
                .add(UpdateThemeModeEvent(themeMode: newValue));
          }
        },
        items: [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Row(
              children: [
                Icon(
                  Icons.settings_suggest,
                  color: settings.themeMode == ThemeMode.system
                      ? AppColors.primary
                      : Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  'System',
                  style: TextStyle(
                    color: settings.themeMode == ThemeMode.system
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Row(
              children: [
                Icon(
                  Icons.light_mode,
                  color: settings.themeMode == ThemeMode.light
                      ? AppColors.primary
                      : Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  'Light',
                  style: TextStyle(
                    color: settings.themeMode == ThemeMode.light
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Row(
              children: [
                Icon(
                  Icons.dark_mode,
                  color: settings.themeMode == ThemeMode.dark
                      ? AppColors.primary
                      : Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  'Dark',
                  style: TextStyle(
                    color: settings.themeMode == ThemeMode.dark
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Widget _buildLanguageSelector(SettingsState state) {
    final settings = state is ProfileLoaded
        ? state.settings
        : state is SettingsLoaded
            ? state.settings
            : state is SettingsUpdateSuccess
                ? state.settings
                : state is ProfileUpdateSuccess
                    ? state.settings
                    : const AppSettings();

    return ListTile(
      title: const Text(
        'Language',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        _getLanguageName(settings.language),
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: DropdownButton<AppLanguage>(
        value: settings.language,
        dropdownColor: AppColors.surface,
        underline: Container(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        onChanged: (AppLanguage? newValue) {
          if (newValue != null) {
            context
                .read<SettingsBloc>()
                .add(UpdateLanguageEvent(language: newValue));
          }
        },
        items: [
          DropdownMenuItem(
            value: AppLanguage.english,
            child: Row(
              children: [
                Text(
                  '🇬🇧',
                  style: TextStyle(
                    fontSize: 20,
                    color: settings.language == AppLanguage.english
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'English',
                  style: TextStyle(
                    color: settings.language == AppLanguage.english
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          DropdownMenuItem(
            value: AppLanguage.vietnamese,
            child: Row(
              children: [
                Text(
                  '🇻🇳',
                  style: TextStyle(
                    fontSize: 20,
                    color: settings.language == AppLanguage.vietnamese
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Vietnamese',
                  style: TextStyle(
                    color: settings.language == AppLanguage.vietnamese
                        ? AppColors.primary
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.vietnamese:
        return 'Vietnamese';
    }
  }

  Widget _buildEditProfileButton() {
    return ListTile(
      leading: const Icon(Icons.edit, color: Colors.white),
      title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
      onTap: () {
        setState(() {
          _isEditingProfile = true;
          _isChangingPassword = false;
        });
      },
    );
  }

  Widget _buildChangePasswordButton() {
    return ListTile(
      leading: const Icon(Icons.lock, color: Colors.white),
      title:
          const Text('Change Password', style: TextStyle(color: Colors.white)),
      onTap: () {
        setState(() {
          _isChangingPassword = true;
          _isEditingProfile = false;
        });
      },
    );
  }

  Widget _buildEditProfileForm(SettingsState state) {
    // Get the current auth state to ensure name matches home page
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is Authenticated 
        ? authState.user.displayName
        : null;
    
    // Update controller if auth state has a display name and form is just opened
    if (userName != null && _displayNameController.text.isEmpty) {
      _displayNameController.text = userName;
    }
    
    return Form(
      key: _formKey,
      child: SettingsSectionWidget(
        title: 'Edit Profile',
        children: [
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingProfile = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<SettingsBloc>().add(
                            UpdateDisplayNameEvent(
                              displayName: _displayNameController.text.trim(),
                            ),
                          );
                      if (_phoneNumberController.text.isNotEmpty) {
                        context.read<SettingsBloc>().add(
                              UpdatePhoneNumberEvent(
                                phoneNumber: _phoneNumberController.text.trim(),
                              ),
                            );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    return Form(
      key: _passwordFormKey,
      child: SettingsSectionWidget(
        title: 'Change Password',
        children: [
          TextFormField(
            controller: _currentPasswordController,
            decoration: const InputDecoration(
              labelText: 'Current Password',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your current password';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            decoration: const InputDecoration(
              labelText: 'New Password',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a new password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'Confirm New Password',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            style: const TextStyle(color: Colors.white),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your new password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isChangingPassword = false;
                      _currentPasswordController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_passwordFormKey.currentState!.validate()) {
                      context.read<SettingsBloc>().add(
                            ChangePasswordEvent(
                              currentPassword: _currentPasswordController.text,
                              newPassword: _newPasswordController.text,
                            ),
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Change'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 