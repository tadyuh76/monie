import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/core/services/app_lifecycle_service.dart';
import 'package:monie/core/themes/app_theme.dart';
// import 'package:monie/core/themes/color_extensions.dart';
import 'package:monie/di/injection.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_event.dart';
import 'package:monie/features/authentication/presentation/pages/auth_wrapper.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/budgets/presentation/pages/budgets_page.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/home/presentation/pages/home_page.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:monie/features/transactions/presentation/pages/transactions_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Register background message handler at the top level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This is needed to handle messages in the background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

// Global key for ScaffoldMessenger to manage snackbars app-wide
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  Future<void> _showNotification(RemoteNotification notification) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'default_channel_id',
    'Notification',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    notification.title,
    notification.body,
    notificationDetails,
  );
}

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Request iOS permissions
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.getAPNSToken();
  }
  
  // Get and log the FCM token
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM Token: $fcmToken');
    
  // Request permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  
  debugPrint('User granted permission: ${settings.authorizationStatus}');
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  
  // Set up foreground message handler (there should only be one)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
    debugPrint('Message data: ${message.data}');
    
    if (message.notification != null) {
      _showNotification(message.notification!);
    }
  });
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
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
  
  // Initialize notification system
  final notificationBloc = getIt<NotificationBloc>();
  notificationBloc.add(RegisterDeviceEvent());
  debugPrint('Device registration initiated');
  notificationBloc.add(SetupNotificationListenersEvent());
  debugPrint('Notification listeners setup initiated');
  
  // Give time for the operations to complete
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Initialize app lifecycle service to track app state changes
  final appLifecycleService = getIt<AppLifecycleService>();
  
  // Delay slightly to ensure everything is initialized
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Send initial app state notification as 'foreground'
  debugPrint('Sending initial foreground state to server');
  notificationBloc.add(const SendAppStateChangeEvent(state: 'foreground'));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(GetCurrentUserEvent()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => getIt<HomeBloc>()..add(const LoadHomeData()),
        ),
        BlocProvider<TransactionsBloc>(
          create: (context) => getIt<TransactionsBloc>()..add(const LoadTransactions()),
        ),
        BlocProvider<BudgetsBloc>(
          create: (context) => getIt<BudgetsBloc>()..add(const LoadBudgets()),
        ),
        BlocProvider<CategoriesBloc>(
          create: (context) => getIt<CategoriesBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => getIt<NotificationBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Monie',
        theme: AppTheme.darkTheme,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomePage(),
          '/transactions': (context) => const TransactionsPage(),
          '/budgets': (context) => const BudgetsPage(),
        },
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          // Handle dynamic routes here if needed in the future
          return null;
        },
        onUnknownRoute: (settings) {
          // Fallback for unknown routes
          return MaterialPageRoute(builder: (context) => const HomePage());
        },
      ),
    );
  }
}