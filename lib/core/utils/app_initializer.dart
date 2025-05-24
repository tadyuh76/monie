import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:monie/firebase_options.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/core/services/push_notification_manager.dart';
import 'package:monie/core/services/app_lifecycle_service.dart';
import 'package:monie/di/injection.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';

class AppInitializer {  static Future<void> initialize() async {
    try {
      // Ensure Flutter binding is initialized
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      await dotenv.load();

      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Lock orientation to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Configure system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      // Initialize Supabase client
      await SupabaseClientManager.initialize();

      // Setup dependency injection
      await configureDependencies();

      debugPrint('✅ App initialization completed successfully');
    } catch (e) {
      debugPrint('❌ Error during app initialization: $e');
      rethrow;
    }
  }

  static Future<String?> initializeNotifications() async {
    try {
      debugPrint('🔔 Initializing notification system...');

      // Get required services from dependency injection
      final notificationBloc = sl<NotificationBloc>();
      final pushNotificationManager = sl<PushNotificationManager>();
      sl<AppLifecycleService>(); // Initialize app lifecycle service

      // Initialize push notification manager
      final fcmToken = await pushNotificationManager.initialize(
        notificationBloc: notificationBloc,
      );

      if (fcmToken != null) {
        // Register device with notification system
        notificationBloc.add(RegisterDeviceEvent());
        debugPrint('📱 Device registration initiated');

        // Set up notification listeners
        notificationBloc.add(SetupNotificationListenersEvent());
        debugPrint('👂 Notification listeners setup initiated');

        // Initialize app lifecycle service
        // This will handle app state changes for push notifications
        await Future.delayed(const Duration(milliseconds: 500));

        // Send initial app state notification as 'foreground'
        debugPrint('📤 Sending initial foreground state to server');
        notificationBloc.add(const SendAppStateChangeEvent(state: 'foreground'));

        debugPrint('✅ Notification system initialized successfully');
        debugPrint('🔑 FCM Token: ${fcmToken.substring(0, 20)}...');

        return fcmToken;
      } else {
        debugPrint('⚠️ Failed to initialize notifications - no FCM token received');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error initializing notification system: $e');
      return null;
    }
  }

  /// Update notification system with user ID when user logs in
  static void updateNotificationUserId(String userId) {
    try {
      final pushNotificationManager = sl<PushNotificationManager>();
      pushNotificationManager.updateUserId(userId);
      debugPrint('👤 Notification system updated with user ID: $userId');
    } catch (e) {
      debugPrint('❌ Error updating notification user ID: $e');
    }
  }

  /// Clean up notification system resources
  static void disposeNotifications() {
    try {
      final pushNotificationManager = sl<PushNotificationManager>();
      pushNotificationManager.dispose();
      debugPrint('🧹 Notification system resources disposed');
    } catch (e) {
      debugPrint('❌ Error disposing notification resources: $e');
    }
  }
}
