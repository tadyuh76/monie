import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/core/utils/validator.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/verification_page.dart';
import 'package:monie/features/authentication/presentation/widgets/auth_button.dart';
import 'package:monie/features/authentication/presentation/widgets/auth_input_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    // Add listener to password controller to update the current password and
    // trigger confirm password validation when password changes
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    // Update the current password value
    setState(() {
      _currentPassword = _passwordController.text;
    });

    // If confirm password field has been touched, validate it again
    if (_confirmPasswordFocusNode.hasFocus ||
        _confirmPasswordController.text.isNotEmpty) {
      _formKey.currentState?.validate();
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _onSignUpPressed() {
    if (_formKey.currentState!.validate()) {
      // First check if the email already exists
      context.read<AuthBloc>().add(
        CheckEmailExistsEvent(email: _emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Account'),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            // Friendlier error messages for specific cases
            String message = state.message;

            // Check for duplicate email errors
            if (message.contains('duplicate key value') &&
                message.contains('users_email_key')) {
              message =
                  'This email is already registered. Please sign in or reset your password.';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (state is SignUpSuccess) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VerificationPage(email: state.email),
              ),
            );
          } else if (state is EmailExists) {
            if (state.canSignIn) {
              // Email exists and is verified - show error message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'This email is already registered. Please sign in.',
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 5),
                ),
              );
            } else {
              // Email exists but is not verified - proceed to verification page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          VerificationPage(email: _emailController.text),
                ),
              );
            }
          } else if (state is EmailDoesNotExist) {
            // Email doesn't exist - proceed with sign up
            context.read<AuthBloc>().add(
              SignUpEvent(
                email: _emailController.text,
                password: _passwordController.text,
                displayName:
                    _displayNameController.text.isNotEmpty
                        ? _displayNameController.text
                        : null,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Logo or Title
                      Center(
                        child: Text(
                          'Create Account',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Sign up to start tracking your finances',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Email Field
                      AuthInputField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'example@email.com',
                        prefixIcon: Icons.email_outlined,
                        validator: Validator.email,
                        textInputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Display Name Field
                      AuthInputField(
                        controller: _displayNameController,
                        labelText: 'Display Name (optional)',
                        hintText: 'How you want to be called',
                        prefixIcon: Icons.person_outline,
                        textInputType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      AuthInputField(
                        controller: _passwordController,
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        validator: Validator.password,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      AuthInputField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        labelText: 'Confirm Password',
                        hintText: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isConfirmPasswordVisible,
                        validator: Validator.passwordMatch(_currentPassword),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Sign Up Button
                      AuthButton(
                        text: 'Sign Up',
                        isLoading: state is AuthLoading,
                        onPressed: _onSignUpPressed,
                      ),
                      const SizedBox(height: 24),

                      // Already have an account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
