import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';
import 'package:uuid/uuid.dart';

abstract class NotificationRemoteDataSource {
  /// Register device for push notifications and get FCM token
  Future<String> registerDevice();

  /// Update FCM token on the server
  Future<bool> updateFcmToken(String token);

  /// Set up notification listeners for different app states
  Future<bool> setupNotificationListeners();

  /// Get the current FCM token
  Future<String> getFcmToken();

  /// Send app state change notification to server
  Future<bool> sendAppStateChangeNotification(String state);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final FirebaseMessaging firebaseMessaging;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final http.Client client;
  final String baseUrl;

  NotificationRemoteDataSourceImpl({
    required this.firebaseMessaging,
    required this.flutterLocalNotificationsPlugin,
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<String> registerDevice() async {
    try {
      String? token = await firebaseMessaging.getToken();
      if (token == null) {
        throw ServerException(message: 'Failed to get FCM token');
      }
      
      // Request permission for iOS devices
      if (Platform.isIOS) {
        NotificationSettings settings = await firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          throw PermissionException();
        }
      }

      // Update token on server
      await updateFcmToken(token);
      
      return token;
    } catch (e) {
      throw ServerException(message: 'Failed to register device: ${e.toString()}');
    }
  }

  @override
  Future<bool> updateFcmToken(String token) async {
    try {
      // For Android emulator, localhost needs to be 10.0.2.2
      String effectiveUrl = baseUrl;
      if (Platform.isAndroid && baseUrl.contains('localhost')) {
        effectiveUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
        debugPrint('Using Android emulator URL for update token: $effectiveUrl');
      }
      
      final response = await client.post(
        Uri.parse('$effectiveUrl/update-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fcmToken': token,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(message: 'Failed to update FCM token: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Network error updating FCM token: ${e.toString()}');
    }
  }

  @override
  Future<bool> setupNotificationListeners() async {
    try {
      // Configure local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );
      
      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
          // Handle notification click
        },
      );

      // Configure foreground notification handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground message: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      return true;
    } catch (e) {
      debugPrint('Error setting up notification listeners: $e');
      throw ServerException(message: 'Failed to setup notification listeners: ${e.toString()}');
    }
  }

  void _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: message.data.toString(),
      );
      
      // Store notification in local storage if needed
      final notificationModel = NotificationModel(
        id: const Uuid().v4(), 
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        timestamp: DateTime.now(),
        data: message.data,
      );
      
      // Here you would store the notification in local storage
    }
  }

  @override
  Future<String> getFcmToken() async {
    try {
      String? token = await firebaseMessaging.getToken();
      if (token == null) {
        throw ServerException(message: 'Failed to get FCM token');
      }
      return token;
    } catch (e) {
      throw ServerException(message: 'Error getting FCM token: ${e.toString()}');
    }
  }

  @override
  Future<bool> sendAppStateChangeNotification(String state) async {
    try {
      final token = await getFcmToken();
      debugPrint('Sending app state change to server: $state with token: ${token.substring(0, 10)}...');
      
      // Create the payload in advance
      final payload = {
        'fcmToken': token,
        'appState': state,
      };
      
      try {
        // For Android emulator, localhost needs to be 10.0.2.2
        String effectiveUrl = baseUrl;
        if (Platform.isAndroid && baseUrl.contains('localhost')) {
          effectiveUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
          debugPrint('Using Android emulator URL: $effectiveUrl');
        }
        
        final response = await client.post(
          Uri.parse('$effectiveUrl/app-state-change'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(payload),
        ).timeout(const Duration(seconds: 5)); // Add timeout
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          debugPrint('Server response: ${response.statusCode} - ${responseData['message']}');
          return true;
        } else {
          debugPrint('Server error: ${response.statusCode} - ${response.body}');
          throw ServerException(message: 'Failed to send app state notification: ${response.statusCode} - ${response.body}');
        }
      } catch (connectionError) {
        // If server unreachable, try sending directly to FCM via Firebase Messaging
        debugPrint('Server connection failed, attempting direct FCM message: $connectionError');
        
        if (state == 'background' || state == 'terminated' || state == 'hidden') {
          await _sendDirectLocalNotification(
            title: 'Monie App - ${state.substring(0, 1).toUpperCase()}${state.substring(1)} Update',
            body: state == 'terminated' 
                ? 'You have new transactions to review!' 
                : 'Your finance summary is ready while you were away',
          );
          return true;
        }
        // For foreground state, no need to send notification
        return true;
      }
    } catch (e) {
      debugPrint('Network error sending app state notification: $e');
      throw ServerException(message: 'Network error sending app state notification: ${e.toString()}');
    }
  }
  
  Future<void> _sendDirectLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('Local notification sent: $title');
    } catch (e) {
      debugPrint('Error sending local notification: $e');
    }
  }
} 