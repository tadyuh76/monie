import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';
import 'package:monie/features/authentication/presentation/pages/signup_page.dart';
import 'package:monie/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:monie/features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash screen route
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
      // Main app routes
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
    ],
    // Add redirect to handle auth state changes
    redirect: (BuildContext context, GoRouterState state) {
      // Get the current auth state
      final authState = context.read<AuthBloc>().state;
      final isAuthenticated = authState is Authenticated;

      // Current path
      final path = state.matchedLocation;
      final isAuthRoute =
          path == '/login' || path == '/signup' || path == '/splash';

      // Logic for redirects
      if (!isAuthenticated && !isAuthRoute) {
        // If not authenticated and trying to access protected route, redirect to login
        return '/login';
      } else if (isAuthenticated && isAuthRoute) {
        // If authenticated and on an auth route, redirect to dashboard
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },
    // Add error handler
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${state.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/splash'),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        ),
  );
}
