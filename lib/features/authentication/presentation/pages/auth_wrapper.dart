import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/widgets/loading_screen.dart';
import 'package:monie/core/widgets/main_screen.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_state.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Only trigger navigation when auth state changes between authenticated/unauthenticated
        return (previous is Authenticated && current is Unauthenticated) ||
            (previous is Unauthenticated && current is Authenticated) ||
            (previous is AuthInitial);
      },
      listener: (context, state) {
        if (!context.mounted) return;
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Authentication error: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is Unauthenticated) {
          // Force navigation to login when unauthenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          });
        } else if (state is Authenticated) {
          // Force navigation to main screen when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => MainScreen()),
              (route) => false,
            );
          });
        }
      },
      builder: (context, state) {
        if (state is AuthInitial) {
          // If we're in initial state, trigger auth check
          context.read<AuthBloc>().add(GetCurrentUserEvent());
          return const LoadingScreen();
        } else if (state is AuthLoading) {
          return const LoadingScreen();
        } else if (state is Authenticated) {
          return MainScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}
