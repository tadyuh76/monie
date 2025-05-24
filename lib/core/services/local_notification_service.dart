import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  late FlutterLocalNotificationsPlugin _localNotifications;
  bool _isInitialized = false;

  FlutterLocalNotificationsPlugin get plugin => _localNotifications;
  bool get isInitialized => _isInitialized;

  /// Initialize local notifications
  Future<void> initialize({
    void Function(NotificationResponse)? onNotificationTap,
  }) async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize with settings
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;
      debugPrint('Local notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
      rethrow;
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    try {
      // High importance channel for reminders and critical notifications
      const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'High priority notifications for reminders and critical updates',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
      );

      // Default channel for general notifications
      const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
        'default_channel_id',
        'Default Notifications',
        description: 'General app notifications',
        importance: Importance.high,
      );

      // App state channel for debugging
      const AndroidNotificationChannel appStateChannel = AndroidNotificationChannel(
        'app_state_channel',
        'App State Notifications',
        description: 'Notifications about app state changes for debugging',
        importance: Importance.low,
      );

      // Create channels
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(highImportanceChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(defaultChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(appStateChannel);

      debugPrint('Notification channels created successfully');
    } catch (e) {
      debugPrint('Error creating notification channels: $e');
    }
  }

  /// Show a local notification from RemoteMessage
  Future<void> showNotificationFromRemoteMessage(RemoteMessage message) async {
    if (!_isInitialized) {
      debugPrint('Local notifications not initialized');
      return;
    }

    try {
      // Determine if this is a transaction reminder
      final isTransactionReminder = message.data['type'] == 'transaction_reminder' || 
                                   message.data['type'] == 'transaction_reminder_data';

      // Extract title and body
      final title = message.notification?.title ?? 
                   message.data['title'] ?? 
                   (isTransactionReminder ? "Don't forget to add your expenses!" : "New Notification");
      
      final body = message.notification?.body ?? 
                  message.data['body'] ?? 
                  (isTransactionReminder ? 'Take a moment to add your recent transactions.' : 'You have a new update.');

      // Choose notification details based on type
      AndroidNotificationDetails androidDetails;
      
      if (isTransactionReminder) {
        androidDetails = const AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'High priority notifications for reminders and critical updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          enableLights: true,
          ledColor: Color(0xFF4CAF50),
          ledOnMs: 1000,
          ledOffMs: 500,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
        );
      } else {
        androidDetails = const AndroidNotificationDetails(
          'default_channel_id',
          'Default Notifications',
          importance: Importance.high,
          priority: Priority.high,
        );      }

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Generate unique notification ID
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );

      debugPrint("Local notification shown: $title");
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Show a custom local notification
  Future<void> showCustomNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel_id',
    String channelName = 'Default Notifications',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    if (!_isInitialized) {
      debugPrint('Local notifications not initialized');
      return;
    }

    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: priority,      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint("Custom local notification shown: $title");
    } catch (e) {
      debugPrint('Error showing custom notification: $e');
    }
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      debugPrint('Notification $id cancelled');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error getting pending notifications: $e');
      return [];
    }
  }
}
