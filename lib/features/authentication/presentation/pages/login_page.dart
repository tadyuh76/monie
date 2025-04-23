import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:monie/core/theme/app_theme.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/widgets/auth_page_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignInEvent(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/dashboard');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return AuthPageScaffold(
          title: 'Sign In',
          showBackButton: false,
          child: _buildLoginForm(context, state),
        );
      },
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to access your account',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Email Field
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
            enabled: !isLoading,
          ),

          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
            enabled: !isLoading,
          ),

          const SizedBox(height: 8),

          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  isLoading
                      ? null
                      : () {
                        // TODO: Implement forgot password
                      },
              child: const Text('Forgot Password?'),
            ),
          ),

          const SizedBox(height: 24),

          // Sign In Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primarySwatch.shade500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Text('SIGN IN'),
            ),
          ),

          const SizedBox(height: 24),

          // Register Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Don\'t have an account?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                          context.go('/register');
                        },
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primarySwatch.shade500,
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
