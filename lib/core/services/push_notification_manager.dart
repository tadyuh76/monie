import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:monie/core/services/firebase_notification_service.dart';
import 'package:monie/core/services/local_notification_service.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';

/// Top-level background message handler
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(RemoteMessage message) async {
  await PushNotificationManager.handleBackgroundMessage(message);
}

class PushNotificationManager {
  static final PushNotificationManager _instance = PushNotificationManager._internal();
  factory PushNotificationManager() => _instance;
  PushNotificationManager._internal();

  final FirebaseNotificationService _firebaseService = FirebaseNotificationService();
  final LocalNotificationService _localService = LocalNotificationService();
  
  NotificationBloc? _notificationBloc;
  String? _currentUserId;

  /// Initialize the complete push notification system
  Future<String?> initialize({
    required NotificationBloc notificationBloc,
    String? userId,
  }) async {
    try {
      _notificationBloc = notificationBloc;
      _currentUserId = userId;

      debugPrint('Initializing Push Notification Manager...');

      // Initialize Firebase
      await _firebaseService.initialize();

      // Initialize local notifications
      await _localService.initialize(
        onNotificationTap: _handleNotificationTap,
      );

      // Request permissions and get token
      final token = await _firebaseService.requestPermissionsAndGetToken();
      
      if (token != null) {
        // Configure foreground presentation
        await _firebaseService.configureForegroundPresentation();

        // Set up message handlers
        _firebaseService.setupMessageHandlers(
          onForegroundMessage: _handleForegroundMessage,
          onBackgroundMessageOpened: _handleBackgroundMessageOpened,
          onTerminatedMessageOpened: _handleTerminatedMessageOpened,
          backgroundHandler: backgroundMessageHandler,
        );

        // Listen to token refresh
        _firebaseService.listenToTokenRefresh(_handleTokenRefresh);

        debugPrint('Push Notification Manager initialized successfully');
        debugPrint('FCM Token: $token');

        return token;
      } else {
        debugPrint('Failed to get FCM token - permissions may be denied');
        return null;
      }
    } catch (e) {
      debugPrint('Error initializing Push Notification Manager: $e');
      return null;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
    debugPrint('Message data: ${message.data}');

    // Show local notification for foreground messages
    _localService.showNotificationFromRemoteMessage(message);

    // Add to notification bloc
    _addNotificationToBloc(message);
  }

  /// Handle background message opened (app was in background)
  void _handleBackgroundMessageOpened(RemoteMessage message) {
    debugPrint('Background message opened: ${message.notification?.title}');
    debugPrint('Message data: ${message.data}');

    // Add to notification bloc
    _addNotificationToBloc(message);

    // Handle navigation if needed
    _handleMessageNavigation(message);
  }

  /// Handle terminated message opened (app was terminated)
  void _handleTerminatedMessageOpened(RemoteMessage message) {
    debugPrint('Terminated message opened: ${message.notification?.title}');
    debugPrint('Message data: ${message.data}');

    // Add to notification bloc
    _addNotificationToBloc(message);

    // Handle navigation if needed
    _handleMessageNavigation(message);
  }

  /// Static method to handle background messages
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint("Handling a background message: ${message.messageId}");
    debugPrint("Message data: ${message.data}");
    debugPrint("Message notification: ${message.notification?.title} - ${message.notification?.body}");

    // Initialize local notifications for background handler
    final localService = LocalNotificationService();
    if (!localService.isInitialized) {
      await localService.initialize();
    }

    // Show local notification
    await localService.showNotificationFromRemoteMessage(message);
    debugPrint("Background local notification shown");
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        // Handle the notification tap based on data
        _handleNotificationData(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle token refresh
  void _handleTokenRefresh(String newToken) {
    debugPrint('FCM Token refreshed: $newToken');
    
    // Update the token with notification bloc
    if (_notificationBloc != null && _currentUserId != null) {
      _notificationBloc!.add(RegisterDeviceTokenEvent(
        userId: _currentUserId!,
        token: newToken,
      ));
    }
  }

  /// Add notification to bloc
  void _addNotificationToBloc(RemoteMessage message) {
    if (_notificationBloc != null) {
      final notification = NotificationModel.fromRemoteMessage(
        message.toMap(),
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _notificationBloc!.add(NotificationReceivedEvent(notification));
    }
  }

  /// Handle message navigation
  void _handleMessageNavigation(RemoteMessage message) {
    final messageType = message.data['type'];
    final screen = message.data['screen'];

    switch (messageType) {
      case 'transaction_reminder':
      case 'transaction_reminder_data':
        debugPrint('Transaction reminder - should navigate to add transaction');
        // Navigation logic can be handled by the UI layer
        break;
      default:
        if (screen != null) {
          debugPrint('Should navigate to screen: $screen');
          // Navigation logic can be handled by the UI layer
        }
        break;
    }
  }

  /// Handle notification data
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'];
    final screen = data['screen'];

    debugPrint('Handling notification data: $type, screen: $screen');

    // Additional handling logic can be added here
    // For example, updating local state, triggering specific actions, etc.
  }

  /// Update current user ID
  void updateUserId(String? userId) {
    _currentUserId = userId;
  }

  /// Get current FCM token
  String? get currentToken => _firebaseService.fcmToken;

  /// Get fresh FCM token
  Future<String?> getFreshToken() => _firebaseService.getFreshToken();

  /// Show a custom notification
  Future<void> showCustomNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel_id',
  }) async {
    await _localService.showCustomNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: payload,
      channelId: channelId,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localService.cancelAllNotifications();
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    await _firebaseService.deleteToken();
  }

  /// Dispose resources
  void dispose() {
    _notificationBloc = null;
    _currentUserId = null;
  }
}
