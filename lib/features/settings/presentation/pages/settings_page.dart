import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/domain/models/user_profile.dart';
import 'package:monie/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:monie/features/settings/presentation/bloc/settings_event.dart';
import 'package:monie/features/settings/presentation/bloc/settings_state.dart';
import 'package:monie/features/settings/presentation/widgets/settings_section_widget.dart';
import 'package:monie/core/localization/app_localizations.dart';

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
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final ImagePicker _imagePicker = ImagePicker();
  UserProfile? _currentProfile;

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
      listenWhen: (previous, current) {
        print('SettingsPage: State transition from ${previous.runtimeType} to ${current.runtimeType}');
        return true; // Listen to all state changes
      },
      listener: (context, state) {
        print('SettingsPage: State changed to ${state.runtimeType}');
        
        if (state is SettingsError) {
          print('SettingsPage: Error state with message: ${state.message}');
          _showErrorSnackBar(state.message);
        } else if (state is SettingsUpdateSuccess) {
          _showSuccessSnackBar(state.message);
        } else if (state is ProfileUpdateSuccess) {
          print('SettingsPage: Profile updated successfully: ${state.profile.displayName}, ${state.profile.phoneNumber}');
          _showSuccessSnackBar(state.message);
          
          // Only close the form after a successful update
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
          print('SettingsPage: Profile loaded - name: ${state.profile.displayName}, phone: ${state.profile.phoneNumber}');
          _displayNameController.text = state.profile.displayName;
          _phoneNumberController.text = state.profile.phoneNumber ?? '';
        }
      },
      builder: (context, state) {
        // Show loading indicator for password change and other operations
        final bool isLoading = state is SettingsLoading;
        
        return Stack(
          children: [
            Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(
                  context.tr('settings_title'),
                  style: const TextStyle(color: Colors.white)
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: _buildBody(context, state),
            ),
            // Show loading overlay when needed
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SettingsState state) {
    // Chỉ hiển thị loading indicator cho trạng thái khởi tạo hoặc đang tải profile
    if (state is SettingsInitial || state is ProfileLoading) {
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
            title: context.tr('settings_app_settings'),
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
              title: context.tr('settings_account'),
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
    
    // Trong trạng thái sau khi thay đổi theme hoặc language, giữ lại thông tin profile cũ
    // Nếu không có profile, hiển thị trạng thái loading
    final profile = state is ProfileLoaded
        ? state.profile
        : state is ProfileUpdateSuccess
            ? state.profile
            : state is SettingsUpdateSuccess && _currentProfile != null
                ? _currentProfile
                : null;

    // Chỉ hiển thị loading khi state là ProfileLoading hoặc SettingsInitial
    // Không hiển thị loading trong các trạng thái khác
    if (profile == null && (state is ProfileLoading || state is SettingsInitial)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                context.tr('settings_loading_profile'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
    
    // Nếu profile là null nhưng state không phải loading, hiển thị placeholder
    if (profile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.account_circle, size: 100, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                context.tr('settings_profile_unavailable'),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Cache profile để sử dụng cho các state khác
    _currentProfile = profile;

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
      title: Text(
        context.tr('settings_notifications'),
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        context.tr('settings_enable_notifications'),
        style: const TextStyle(color: Colors.white70),
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
      title: Text(
        context.tr('settings_theme'),
        style: const TextStyle(color: Colors.white),
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
                  context.tr('settings_theme_light'),
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
                  context.tr('settings_theme_dark'),
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
      case ThemeMode.light:
        return context.tr('settings_theme_light');
      case ThemeMode.dark:
        return context.tr('settings_theme_dark');
      case ThemeMode.system:
        return context.tr('settings_theme_light'); // Default to Light if system is somehow set
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
      title: Text(
        context.tr('settings_language'),
        style: const TextStyle(color: Colors.white),
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
                  context.tr('settings_language_english'),
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
                  context.tr('settings_language_vietnamese'),
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
        return context.tr('settings_language_english');
      case AppLanguage.vietnamese:
        return context.tr('settings_language_vietnamese');
    }
  }

  Widget _buildEditProfileButton() {
    return ListTile(
      leading: const Icon(Icons.edit, color: Colors.white),
      title: Text(
        context.tr('settings_edit_profile'),
        style: const TextStyle(color: Colors.white)
      ),
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
      title: Text(
        context.tr('settings_change_password'),
        style: const TextStyle(color: Colors.white)
      ),
      onTap: () {
        setState(() {
          _isChangingPassword = true;
          _isEditingProfile = false;
        });
      },
    );
  }

  // New method to handle profile updates
  void _saveProfileChanges() {
    print('SettingsPage: _saveProfileChanges called');
    if (_formKey.currentState!.validate()) {
      print('SettingsPage: Form validation passed');
      
      // Get the trimmed values
      final name = _displayNameController.text.trim();
      final phone = _phoneNumberController.text.trim();
      
      print('SettingsPage: Saving name: "$name", phone: "$phone"');
      
      // First update the name
      context.read<SettingsBloc>().add(
            UpdateDisplayNameEvent(displayName: name),
          );
      
      // Then update the phone if provided
      if (phone.isNotEmpty) {
        context.read<SettingsBloc>().add(
              UpdatePhoneNumberEvent(phoneNumber: phone),
            );
      }
      
      // Note: We don't immediately close the form here
      // Let the BlocListener handle it based on the success state
    } else {
      print('SettingsPage: Form validation failed');
    }
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

    // Check if we're currently saving profile changes
    final bool isSaving = state is SettingsLoading;
    
    final errorStyle = const TextStyle(color: Colors.red, fontSize: 13.0, fontWeight: FontWeight.w500);
    
    return Form(
      key: _formKey,
      child: SettingsSectionWidget(
        title: context.tr('settings_edit_profile'),
        children: [
          TextFormField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: context.tr('settings_name'),
              labelStyle: const TextStyle(color: Colors.white),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('settings_please_enter_name');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneNumberController,
            decoration: InputDecoration(
              labelText: context.tr('settings_phone_number'),
              labelStyle: const TextStyle(color: Colors.white),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  child: Text(
                    context.tr('settings_cancel'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSaving ? null : _saveProfileChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  ),
                  child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : Text(
                        context.tr('settings_save'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordForm() {
    final errorStyle = const TextStyle(color: Colors.red, fontSize: 13.0, fontWeight: FontWeight.w500);
    
    return Form(
      key: _passwordFormKey,
      child: SettingsSectionWidget(
        title: context.tr('settings_change_password'),
        children: [
          TextFormField(
            controller: _currentPasswordController,
            decoration: InputDecoration(
              labelText: context.tr('settings_current_password'),
              labelStyle: const TextStyle(color: Colors.white),
              hintStyle: const TextStyle(color: Colors.white70),
              errorStyle: errorStyle,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isCurrentPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            obscureText: !_isCurrentPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('settings_please_enter_current_password');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              labelText: context.tr('settings_new_password'),
              labelStyle: const TextStyle(color: Colors.white),
              hintStyle: const TextStyle(color: Colors.white70),
              errorStyle: errorStyle,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            obscureText: !_isNewPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('settings_please_enter_new_password');
              }
              if (value.length < 6) {
                return context.tr('settings_password_min_length');
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: context.tr('settings_confirm_password'),
              labelStyle: const TextStyle(color: Colors.white),
              hintStyle: const TextStyle(color: Colors.white70),
              errorStyle: errorStyle,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            obscureText: !_isConfirmPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return context.tr('settings_please_confirm_password');
              }
              if (value != _newPasswordController.text) {
                return context.tr('settings_passwords_not_match');
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  child: Text(
                    context.tr('settings_cancel'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
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
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                  ),
                  child: Text(
                    context.tr('settings_change'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 