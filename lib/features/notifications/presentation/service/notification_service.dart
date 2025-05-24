import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:monie/features/notifications/data/models/notification_model.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';

class NotificationService with WidgetsBindingObserver {
  final NotificationBloc notificationBloc;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String? _currentUserId;
  AppLifecycleState? _previousAppState;
  // Server URL for localhost testing
  final String _serverBaseUrl = 'http://10.0.2.2:4000'; // For Android emulator
  // Use 'http://localhost:4000' for iOS simulator or 'http://<your-computer-ip>:4000' for real devices

  // Notification channel details
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'monie_push_channel',
    'Monie Push Notifications',
    description: 'Channel for receiving push notifications in Monie app',
    importance: Importance.high,
  );

  // High importance channel for reminders that can wake terminated apps
  static const AndroidNotificationChannel _reminderChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'High priority notifications for reminders and critical updates',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color(0xFF4CAF50),
  );

  // App state notification channel
  static const AndroidNotificationChannel _appStateChannel = AndroidNotificationChannel(
    'app_state_channel',
    'App State Notifications',
    description: 'Channel for notifications about app state changes',
    importance: Importance.high,
  );

  NotificationService({required this.notificationBloc});

  Future<void> initialize() async {
    // Register as observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    _previousAppState = WidgetsBinding.instance.lifecycleState;

    await _configureLocalNotifications();
    await _configureFirebaseMessaging();

    debugPrint('NotificationService initialized with app state: $_previousAppState');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App state changed: $_previousAppState -> $state');

    // Only process if have a user ID
    if (_currentUserId != null) {
      _notifyAppStateChange(_previousAppState, state);
    }

    _previousAppState = state;
  }

  // Cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  // Notify server about app state change
  Future<void> _notifyAppStateChange(AppLifecycleState? previousState, AppLifecycleState currentState) async {
    try {
      final response = await http.post(
        Uri.parse('$_serverBaseUrl/app-state-changed'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _currentUserId,
          'previousState': previousState?.name,
          'currentState': currentState.name,
        }),
      );

      final responseData = jsonDecode(response.body);
      debugPrint('App state notification response: ${responseData['message']}');
    } catch (e) {
      debugPrint('Error sending app state change: $e');
    }
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  String? get currentUserId => _currentUserId;

  // Get device token for FCM
  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Register the device token with the server
  Future<void> registerDeviceToken(String userId) async {
    final token = await getDeviceToken();
    if (token != null) {
      // First, register with our notification bloc
      notificationBloc.add(RegisterDeviceTokenEvent(
        userId: userId,
        token: token,
      ));

      // Also register directly with our local server
      try {
        final response = await http.post(
          Uri.parse('$_serverBaseUrl/register-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'token': token,
          }),
        );

        final responseData = jsonDecode(response.body);
        debugPrint('Device token registration response: ${responseData['message']}');
      } catch (e) {
        debugPrint('Error registering device token with local server: $e');
      }

      setCurrentUserId(userId);
    }
  }

  // Configure local notifications
  Future<void> _configureLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [],
    );

    // Create the initialization settings for all platforms
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );    // Initialize the plugin
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
    );    // Create Android notification channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_reminderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_appStateChannel);
  }

  // Handle notification taps
  void _onSelectNotification(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        final notification = NotificationModel.fromJson(data);
        notificationBloc.add(NotificationReceivedEvent(notification));
      } catch (e) {
        debugPrint('Error processing notification payload: $e');
      }
    }
  }

  // Configure Firebase Messaging
  Future<void> _configureFirebaseMessaging() async {
    // Request permission (iOS only, Android doesn't need this)
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Configure foreground notification settings
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle notifications when the app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageOpened);

    // Handle notification when app is terminated and opened from notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleTerminatedMessageOpened(initialMessage);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    // Show the local notification
    _showLocalNotification(message);

    // Process the notification in the bloc
    final notification = NotificationModel.fromRemoteMessage(
      message.toMap(),
      message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );
    notificationBloc.add(NotificationReceivedEvent(notification));
  }

  // Handle background messages opened
  void _handleBackgroundMessageOpened(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(
      message.toMap(),
      message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );
    notificationBloc.add(NotificationReceivedEvent(notification));
  }
  // Handle terminated messages opened
  void _handleTerminatedMessageOpened(RemoteMessage message) {
    debugPrint('Handling terminated app message: ${message.data}');
    
    final notification = NotificationModel.fromRemoteMessage(
      message.toMap(),
      message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );
    
    // If this is a transaction reminder, add specific navigation context
    if (message.data['type'] == 'transaction_reminder' || message.data['type'] == 'transaction_reminder_data') {
      debugPrint('Transaction reminder opened from terminated state');
      
      // Add special event to navigate to add transaction screen
      notificationBloc.add(NotificationReceivedEvent(notification));
      
      // You can add navigation logic here if needed
      // For example, navigate to add transaction screen
      if (message.data['screen'] == 'add_transaction') {
        debugPrint('Should navigate to add transaction screen');
        // This could trigger navigation to the specific screen
      }
    } else {
      notificationBloc.add(NotificationReceivedEvent(notification));
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? 'mipmap/ic_launcher',
            importance: Importance.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode({
          'id': message.messageId,
          'title': notification.title,
          'body': notification.body,
          'data': message.data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    }
  }

  // Test methods for different notification states
  Future<void> testForegroundNotification() async {
    if (_currentUserId != null) {
      notificationBloc.add(TestForegroundNotificationEvent(_currentUserId!));
    }
  }

  Future<void> testBackgroundNotification() async {
    if (_currentUserId != null) {
      notificationBloc.add(TestBackgroundNotificationEvent(_currentUserId!));
    }
  }

  Future<void> testTerminatedNotification() async {
    if (_currentUserId != null) {
      notificationBloc.add(TestTerminatedNotificationEvent(_currentUserId!));
    }
  }
}
