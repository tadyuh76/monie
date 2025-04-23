import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:monie/core/di/injection_container.dart' as di;
import 'package:monie/core/routes/app_router.dart';
import 'package:monie/core/utils/error_logger.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/firebase/firebase_options.dart';
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

      try {
        // Initialize Firebase
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized successfully');
      } catch (e) {
        debugPrint('Error initializing Firebase: $e');
        // Continue with app initialization - dependency injection will use mocks if Firebase init fails
      }

      // Initialize Hive
      await Hive.initFlutter();
      Hive.registerAdapter(UserAdapter());
      await HiveBoxes.init();

      // Initialize dependency injection
      await di.init();

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
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
          lazy: false, // Make sure the bloc is created immediately
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Reset auth bloc state to initial when user is unauthenticated
          // This ensures a clean login screen experience
          if (state is Unauthenticated) {
            Future.microtask(() {
              context.read<AuthBloc>().add(ResetAuthEvent());
            });
          }
        },
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Monie',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
