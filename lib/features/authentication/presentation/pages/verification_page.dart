import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';
import 'package:monie/features/authentication/presentation/widgets/auth_button.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({super.key, required this.email});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  Timer? _resendCooldownTimer;
  bool _canResend = true;
  bool _hasRequestedVerification = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  void _manualCheckVerification() {
    // Show checking message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking verification status...'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );

    // Request a verification check
    context.read<AuthBloc>().add(
      CheckVerificationStatusEvent(email: widget.email, isSilent: false),
    );
  }

  void _onResendPressed() {
    if (_canResend) {
      // Disable resend button for 120 seconds
      setState(() {
        _canResend = false;
        _hasRequestedVerification = true;
      });

      // Send the verification email only when explicitly requested
      context.read<AuthBloc>().add(
        ResendVerificationEmailEvent(email: widget.email),
      );

      // Show cooldown message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait 2 minutes before requesting another verification email',
          ),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.blue,
        ),
      );

      // Start cooldown timer
      _resendCooldownTimer?.cancel();
      _resendCooldownTimer = Timer(const Duration(seconds: 120), () {
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
      });
    } else {
      // Show message if user tries to click during cooldown
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please wait before requesting another verification email',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onBackToLoginPressed() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!context.mounted) return;
        if (state is VerificationEmailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is VerificationSuccess) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email successfully verified! You can now login.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to login
          final navigator = Navigator.of(context);
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            navigator.pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          });
        } else if (state is VerificationPending) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Email is not yet verified. Please check your inbox and click the verification link.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else if (state is AuthError) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Email Verification'),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email Icon
                  const Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Verify your email',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    _hasRequestedVerification
                        ? 'We\'ve sent a verification email to:\n${widget.email}'
                        : 'Click the button below to send a verification email to:\n${widget.email}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  if (_hasRequestedVerification)
                    Text(
                      'Please check your inbox and click the verification link to complete your registration.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 40),

                  // Resend Button - now labeled as "Send Verification Email" initially
                  AuthButton(
                    text:
                        _hasRequestedVerification
                            ? 'Resend Email'
                            : 'Send Verification Email',
                    onPressed: _onResendPressed,
                    isLoading: state is AuthLoading,
                    isOutlined: true,
                    color: _canResend ? AppColors.primary : Colors.grey,
                  ),
                  const SizedBox(height: 16),

                  // Manual verification check button
                  AuthButton(
                    text: 'Check Verification Status',
                    onPressed: _manualCheckVerification,
                    isLoading: state is AuthLoading,
                    isOutlined: true,
                    icon: Icons.refresh,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),

                  // Back to Login Button
                  AuthButton(
                    text: 'Back to Login',
                    onPressed: _onBackToLoginPressed,
                  ),
                  const SizedBox(height: 24),

                  // Help text
                  if (_hasRequestedVerification)
                    Text(
                      'Didn\'t receive an email? Check your spam folder or try again.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
