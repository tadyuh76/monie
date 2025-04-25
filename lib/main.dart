import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:monie/core/di/injection_container.dart' as di;
import 'package:monie/core/routes/app_router.dart';
import 'package:monie/core/supabase/supabase_service.dart';
import 'package:monie/core/theme/app_theme.dart';
import 'package:monie/core/theme/cubit/theme_cubit.dart';
import 'package:monie/core/utils/error_logger.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/hive/adapters/user_adapter.dart';
import 'package:monie/hive/boxes/boxes.dart';

void main() async {
  // Add a global error handler for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.logError('FlutterError', details.exception, details.stack);
    FlutterError.dumpErrorToConsole(details);
  };

  // Add a global error handler for Dart errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      await dotenv.load(fileName: '.env');

      // Initialize Hive first as it's critical
      await Hive.initFlutter();
      Hive.registerAdapter(UserAdapter());
      await HiveBoxes.init();

      try {
        // Initialize Supabase
        await SupabaseService.initialize();
        debugPrint('Supabase initialized successfully');
      } catch (e) {
        debugPrint('Error initializing Supabase: $e');
        // Continue with app initialization - dependency injection will use mocks if Supabase init fails
      }

      // Initialize dependency injection
      await di.init();

      // Run the app
      runApp(const MainApp());
    },
    (error, stackTrace) {
      ErrorLogger.logError('ZoneError', error, stackTrace);
    },
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) {
            try {
              return di.sl<ThemeCubit>();
            } catch (e) {
              debugPrint('Error creating ThemeCubit: $e');
              // Fallback to default theme
              return ThemeCubit(HiveBoxes.settingsBox);
            }
          },
          lazy: false,
        ),
        BlocProvider<AuthBloc>(
          create: (context) {
            try {
              final bloc = di.sl<AuthBloc>();
              // Make sure we have a theme before proceeding
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  bloc.add(CheckAuthStatusEvent());
                }
              });
              return bloc;
            } catch (e, stackTrace) {
              debugPrint('Error creating AuthBloc: $e');
              debugPrint('$stackTrace');
              // Return a minimal auth bloc that can show error state
              // In a real app, you would create a proper fallback here
              throw Exception(
                'Failed to initialize authentication. Please restart the app.',
              );
            }
          },
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocListener<AuthBloc, BLoCAuthState>(
            listener: (context, state) {
              // Reset auth bloc state to initial when user is unauthenticated
              // This ensures a clean login screen experience
              if (state is Unauthenticated) {
                // Use WidgetsBinding.instance instead of Future.microtask to safely schedule after frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.read<AuthBloc>().add(ResetAuthEvent());
                  }
                });
              }
            },
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Monie',
              themeMode: themeState.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              routerConfig: AppRouter.router,
            ),
          );
        },
      ),
    );
  }
}
