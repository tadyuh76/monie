import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:monie/firebase_options.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  late FirebaseMessaging _messaging;
  String? _fcmToken;

  FirebaseMessaging get messaging => _messaging;
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase and Firebase Messaging
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _messaging = FirebaseMessaging.instance;
      
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// Request notification permissions and get FCM token
  Future<String?> requestPermissionsAndGetToken() async {
    try {
      // Request iOS permissions
      if (Platform.isIOS) {
        await _messaging.getAPNSToken();
      }

      // Request permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get and cache the FCM token
        _fcmToken = await _messaging.getToken();
        debugPrint('FCM Token: $_fcmToken');
        
        // Enable auto-init
        await _messaging.setAutoInitEnabled(true);
        
        return _fcmToken;
      } else {
        debugPrint('Permission denied');
        return null;
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return null;
    }
  }

  /// Set up foreground notification presentation options
  Future<void> configureForegroundPresentation() async {
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Foreground notification presentation configured');
    } catch (e) {
      debugPrint('Error configuring foreground presentation: $e');
    }
  }

  /// Set up message handlers
  void setupMessageHandlers({
    required void Function(RemoteMessage) onForegroundMessage,
    required void Function(RemoteMessage) onBackgroundMessageOpened,
    required void Function(RemoteMessage) onTerminatedMessageOpened,
    required Future<void> Function(RemoteMessage) backgroundHandler,
  }) {
    try {
      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(onForegroundMessage);

      // Set up background message opened handler
      FirebaseMessaging.onMessageOpenedApp.listen(onBackgroundMessageOpened);

      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(backgroundHandler);

      // Handle messages when app was terminated
      _messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          onTerminatedMessageOpened(message);
        }
      });

      debugPrint('Firebase message handlers set up successfully');
    } catch (e) {
      debugPrint('Error setting up message handlers: $e');
    }
  }

  /// Get fresh FCM token
  Future<String?> getFreshToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      return _fcmToken;
    } catch (e) {
      debugPrint('Error getting fresh token: $e');
      return null;
    }
  }

  /// Listen to token refresh
  void listenToTokenRefresh(void Function(String) onTokenRefresh) {
    _messaging.onTokenRefresh.listen(onTokenRefresh);
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }
}
