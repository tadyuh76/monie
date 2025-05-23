import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/di/injection.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';
import 'package:monie/features/settings/domain/models/app_settings.dart';
import 'package:monie/features/settings/domain/models/user_profile.dart';
import 'package:monie/features/settings/domain/repositories/settings_repository.dart';
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
  final SettingsRepository _settingsRepository = sl<SettingsRepository>();
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

  // Helper method to get divider color based on theme
  Color _getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.divider
        : Colors.black.withValues(alpha: 0.05); // Much lighter for light theme
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (!mounted) return;

      if (image != null) {
        // Upload the image to storage

        final bloc = context.read<SettingsBloc>();

        // Show loading indicator
        _showLoadingDialog(context.tr('common_loading'));

        try {
          // Lấy repository để thực hiện việc upload

          // Upload ảnh và lấy URL công khai hoặc đường dẫn cục bộ
          final String? avatarUrl = await _settingsRepository.uploadAvatar(
            image.path,
          );

          if (avatarUrl != null) {
            // Nếu có URL hoặc đường dẫn, cập nhật avatar
            bloc.add(UpdateAvatarEvent(avatarUrl: avatarUrl));

            // Đóng dialog loading
            if (mounted) {
              Navigator.of(context).pop();
              _showSuccessSnackBar(context.tr('settings_profile_updated'));
            }
          } else {
            // Nếu không có URL, hiển thị lỗi
            if (mounted) {
              Navigator.of(context).pop(); // Close loading dialog
              _showErrorSnackBar(context.tr('common_error'));
            }
          }
        } catch (uploadError) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            _showErrorSnackBar(context.tr('common_error'));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
        _showErrorSnackBar(context.tr('common_error'));
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.expense),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) {
        return true; // Listen to all state changes
      },
      listener: (context, state) {
        if (state is SettingsError) {
          _showErrorSnackBar(state.message);
        } else if (state is SettingsUpdateSuccess) {
          _showSuccessSnackBar(state.message);
        } else if (state is ProfileUpdateSuccess) {
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(
                  context.tr('settings_title'),
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: _buildBody(context, state),
            ),
            // Show loading overlay when needed
            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SettingsState state) {
    // Get user's name from auth state for fallback if profile isn't loaded
    String? authName;
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      authName = authState.user.displayName;
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(context, state, authName),
          const SizedBox(height: 16),
          if (_isEditingProfile)
            _buildEditProfileForm(state)
          else if (_isChangingPassword)
            _buildChangePasswordForm()
          else
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.surface
                            : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow:
                        Theme.of(context).brightness == Brightness.light
                            ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ]
                            : null,
                  ),
                  child: Column(
                    children: [
                      _buildThemeSelector(state),
                      const SizedBox(height: 16),
                      _buildLanguageSelector(state),
                      const SizedBox(height: 16),
                      _buildNotificationsToggle(state),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SettingsSectionWidget(
                  title: context.tr('settings_account'),
                  children: [
                    ListTile(
                      title: Text(
                        context.tr('settings_change_password'),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      leading: Icon(
                        Icons.lock_outline,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                      onTap: () {
                        setState(() {
                          _isChangingPassword = true;
                        });
                      },
                    ),
                    Divider(color: _getDividerColor(context)),
                    // Logout option
                    ListTile(
                      title: Text(
                        context.tr('auth_logout'),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.expense,
                        ),
                      ),
                      leading: Icon(Icons.logout, color: AppColors.expense),
                      onTap: () {
                        // Show logout confirmation dialog
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                backgroundColor:
                                    isDarkMode
                                        ? AppColors.surface
                                        : Colors.white,
                                title: Text(
                                  context.tr('auth_logout'),
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                ),
                                content: Text(
                                  context.tr('auth_logout_confirm'),
                                  style: TextStyle(
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text(context.tr('common_cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.read<AuthBloc>().add(
                                        SignOutEvent(),
                                      );

                                      // Also manually navigate to login page for redundancy
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => const LoginPage(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    child: Text(
                                      context.tr('auth_logout'),
                                      style: TextStyle(
                                        color: AppColors.expense,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    SettingsState state,
    String? authName,
  ) {
    // Try to get the profile from auth state first for consistent naming
    final authState = context.watch<AuthBloc>().state;
    final authName =
        authState is Authenticated ? authState.user.displayName : null;

    // Trong trạng thái sau khi thay đổi theme hoặc language, giữ lại thông tin profile cũ
    // Nếu không có profile, hiển thị trạng thái loading
    final profile =
        state is ProfileLoaded
            ? state.profile
            : state is ProfileUpdateSuccess
            ? state.profile
            : state is SettingsUpdateSuccess && _currentProfile != null
            ? _currentProfile
            : null;

    // Chỉ hiển thị loading khi state là ProfileLoading hoặc SettingsInitial
    // Không hiển thị loading trong các trạng thái khác
    if (profile == null &&
        (state is ProfileLoading || state is SettingsInitial)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surface
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              Theme.of(context).brightness == Brightness.light
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                context.tr('settings_loading_profile'),
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                ),
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
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surface
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              Theme.of(context).brightness == Brightness.light
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : null,
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('settings_profile_unavailable'),
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                ),
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
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.surface
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            Theme.of(context).brightness == Brightness.light
                ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
                : null,
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
                  backgroundImage:
                      profile.avatarUrl != null
                          ? _getImageProvider(profile.avatarUrl!)
                          : null,
                  child:
                      profile.avatarUrl == null
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  _showQuickNameEditDialog(context, displayName);
                },
                child: Icon(
                  Icons.border_color,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: TextStyle(
              fontSize: 16,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
            ),
          ),
          if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                profile.phoneNumber!,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
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
    final settings =
        state is ProfileLoaded
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
        style: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
        ),
      ),
      subtitle: Text(
        context.tr('settings_enable_notifications'),
        style: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
        ),
      ),
      value: settings.notificationsEnabled,
      activeColor: AppColors.primary,
      onChanged: (value) {
        context.read<SettingsBloc>().add(
          UpdateNotificationsEvent(enabled: value),
        );
      },
    );
  }

  Widget _buildThemeSelector(SettingsState state) {
    final settings =
        state is ProfileLoaded
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
        style: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
        ),
      ),
      subtitle: Text(
        _getThemeModeName(settings.themeMode),
        style: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
        ),
      ),
      trailing: DropdownButton<ThemeMode>(
        value: settings.themeMode,
        dropdownColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.surface
                : Colors.white,
        underline: Container(),
        icon: Icon(
          Icons.arrow_drop_down,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
        ),
        onChanged: (ThemeMode? newValue) {
          if (newValue != null) {
            context.read<SettingsBloc>().add(
              UpdateThemeModeEvent(themeMode: newValue),
            );
          }
        },
        items: [
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Row(
              children: [
                Icon(
                  Icons.light_mode,
                  color:
                      settings.themeMode == ThemeMode.light
                          ? AppColors.primary
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('settings_theme_light'),
                  style: TextStyle(
                    color:
                        settings.themeMode == ThemeMode.light
                            ? AppColors.primary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
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
                  color:
                      settings.themeMode == ThemeMode.dark
                          ? AppColors.primary
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('settings_theme_dark'),
                  style: TextStyle(
                    color:
                        settings.themeMode == ThemeMode.dark
                            ? AppColors.primary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
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
        return context.tr(
          'settings_theme_light',
        ); // Default to Light if system is somehow set
    }
  }

  Widget _buildLanguageSelector(SettingsState state) {
    final settings =
        state is ProfileLoaded
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
        style: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
        ),
      ),
      subtitle: Text(
        _getLanguageName(settings.language),
        style: TextStyle(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
        ),
      ),
      trailing: DropdownButton<AppLanguage>(
        value: settings.language,
        dropdownColor:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.surface
                : Colors.white,
        underline: Container(),
        icon: Icon(
          Icons.arrow_drop_down,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
        ),
        onChanged: (AppLanguage? newValue) {
          if (newValue != null) {
            context.read<SettingsBloc>().add(
              UpdateLanguageEvent(language: newValue),
            );
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
                    color:
                        settings.language == AppLanguage.english
                            ? AppColors.primary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('settings_language_english'),
                  style: TextStyle(
                    color:
                        settings.language == AppLanguage.english
                            ? AppColors.primary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
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
                    color:
                        settings.language == AppLanguage.vietnamese
                            ? AppColors.primary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('settings_language_vietnamese'),
                  style: TextStyle(
                    color:
                        settings.language == AppLanguage.vietnamese
                            ? AppColors.primary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
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

  // New method to handle profile updates
  void _saveProfileChanges() {
    if (_formKey.currentState!.validate()) {
      // Get the trimmed values
      final name = _displayNameController.text.trim();
      final phone = _phoneNumberController.text.trim();

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
    } else {}
  }

  Widget _buildEditProfileForm(SettingsState state) {
    // Get the current auth state to ensure name matches home page
    final authState = context.watch<AuthBloc>().state;
    final userName =
        authState is Authenticated ? authState.user.displayName : null;

    // Update controller if auth state has a display name and form is just opened
    if (userName != null && _displayNameController.text.isEmpty) {
      _displayNameController.text = userName;
    }

    // Check if we're currently saving profile changes
    final bool isSaving = state is SettingsLoading;

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: SettingsSectionWidget(
        title: context.tr('settings_edit_profile'),
        children: [
          TextFormField(
            controller: _displayNameController,
            decoration: InputDecoration(
              labelText: context.tr('settings_name'),
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black54,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey : Colors.black26,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
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
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
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
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black54,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey : Colors.black26,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
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
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
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
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  child: Text(
                    context.tr('settings_cancel'),
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
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
                    disabledBackgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child:
                      isSaving
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
    final errorStyle = TextStyle(
      color: Colors.red,
      fontSize: 13.0,
      fontWeight: FontWeight.w500,
    );

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _passwordFormKey,
      child: SettingsSectionWidget(
        title: context.tr('settings_change_password'),
        children: [
          TextFormField(
            controller: _currentPasswordController,
            decoration: InputDecoration(
              labelText: context.tr('settings_current_password'),
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black54,
              ),
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black38,
              ),
              errorStyle: errorStyle,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey : Colors.black26,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                  _isCurrentPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: isDarkMode ? Colors.white : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
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
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black54,
              ),
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black38,
              ),
              errorStyle: errorStyle,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey : Colors.black26,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                  _isNewPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: isDarkMode ? Colors.white : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
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
              labelStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black54,
              ),
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black38,
              ),
              errorStyle: errorStyle,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.grey : Colors.black26,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: isDarkMode ? Colors.white : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
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
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  child: Text(
                    context.tr('settings_cancel'),
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
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

  // Method to show a quick dialog for editing just the display name
  void _showQuickNameEditDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDarkMode ? AppColors.surface : Colors.white,
            title: Text(
              context.tr('settings_edit_profile'),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            content: TextField(
              controller: nameController,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: context.tr('settings_name'),
                labelStyle: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey : Colors.black26,
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.tr('settings_cancel'),
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    context.read<SettingsBloc>().add(
                      UpdateDisplayNameEvent(displayName: newName),
                    );
                  }
                  Navigator.of(context).pop();
                },
                child: Text(
                  context.tr('settings_save'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
