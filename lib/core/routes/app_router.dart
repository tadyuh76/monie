import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:monie/features/authentication/presentation/pages/login_page.dart';
import 'package:monie/features/authentication/presentation/pages/signup_page.dart';
import 'package:monie/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:monie/features/splash/presentation/pages/splash_page.dart';
import 'package:monie/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:monie/features/authentication/presentation/pages/reset_password_page.dart';

/// Router configuration for the app
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SplashPage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const LoginPage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SignUpPage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardPage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordPage(token: token);
        },
      ),
    ],
    redirect: (context, state) {
      final uri = Uri.parse(state.uri.toString());

      // Handle password reset deep links
      if (state.uri.toString().startsWith(
        'io.supabase.monie://reset-password',
      )) {
        final token = uri.queryParameters['token'] ?? '';
        return '/reset-password/$token';
      }

      // Handle email verification deep links
      if (state.uri.toString().startsWith(
        'io.supabase.monie://email-verification',
      )) {
        // After email verification, redirect to dashboard or profile page
        return '/dashboard';
      }

      return null; // No redirect needed
    },
  );
}
