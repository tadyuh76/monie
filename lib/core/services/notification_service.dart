import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monie/main.dart' show navigatorKey;

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
}

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      // Initialize local notifications plugin
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('📱 Local notification tapped: ${response.payload}');

          // Parse the payload and handle navigation
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              // The payload is a JSON string containing notification data
              final Map<String, dynamic> data = jsonDecode(response.payload!);
              _handleNotificationData(data);
            } catch (e) {
              debugPrint('⚠️ Error parsing notification payload: $e');
            }
          }
        },
      );

      // Create Android notification channel for high priority notifications
      const androidChannel = AndroidNotificationChannel(
        'monie_notifications',
        'Monie Notifications',
        description: 'Notifications for group transactions and updates.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Request notification permissions (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Notification permission granted');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('Provisional notification permission granted');
      } else {
        debugPrint('Notification permission denied');
        return;
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        updateFCMToken(); // Update token in Supabase
      });

      // Set up message handlers
      _setupMessageHandlers();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      debugPrint('Notification Service initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  /// Set up foreground and background message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // Show local notification banner when app is in foreground
      _handleForegroundMessage(message);
    });

    // Background messages (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from background notification');
      debugPrint('Data: ${message.data}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App opened from terminated state notification');
        debugPrint('Data: ${message.data}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    // Display the notification using flutter_local_notifications
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'monie_notifications',
            'Monie Notifications',
            channelDescription: 'Notifications for group transactions and updates.',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );

      debugPrint('Notification displayed: ${notification.title}');
    }
  }

  /// Handle notification tap from FCM
  void _handleNotificationTap(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  /// Handle navigation based on notification data
  /// This is used by both FCM notifications and local notifications
  void _handleNotificationData(Map<String, dynamic> data) {
    // Route based on notification type
    switch (data['type']) {
      case 'daily_reminder':
        debugPrint('📱 Navigate to home/transactions page');
        // Navigate to home page
        navigatorKey.currentState?.pushNamed('/home');
        break;
      case 'group_transaction':
      case 'group_invitation':
        final groupId = data['group_id'];
        debugPrint('📱 Navigate to group: $groupId');

        if (groupId != null && groupId.isNotEmpty) {
          // Navigate to group detail page with group ID as argument
          navigatorKey.currentState?.pushNamed(
            '/group-details',
            arguments: groupId,
          );
        } else {
          debugPrint('⚠️ Group ID is missing in notification data');
        }
        break;
      default:
        debugPrint('⚠️ Unknown notification type: ${data['type']}');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    _fcmToken ??= await _firebaseMessaging.getToken();
    return _fcmToken;
  }

  /// Update FCM token in Supabase database
  Future<void> updateFCMToken() async {
    try {
      final token = await getToken();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (token != null && userId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'fcm_token': token})
            .eq('user_id', userId);
        
        debugPrint('FCM token updated in database');
      } else {
        debugPrint('Cannot update FCM token: token=$token, userId=$userId');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Request notification permission (iOS/Android 13+)
  Future<bool> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
