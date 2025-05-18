import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepository {
  /// Register device for push notifications and store FCM token
  Future<Either<Failure, String>> registerDevice();
  
  /// Update FCM token on the server
  Future<Either<Failure, bool>> updateFcmToken(String token);
  
  /// Get all notifications for the current user
  Future<Either<Failure, List<Notification>>> getNotifications();
  
  /// Mark a notification as read
  Future<Either<Failure, bool>> markAsRead(String notificationId);
  
  /// Mark all notifications as read
  Future<Either<Failure, bool>> markAllAsRead();
  
  /// Delete a specific notification
  Future<Either<Failure, bool>> deleteNotification(String notificationId);
  
  /// Set up notification listeners for different app states
  Future<Either<Failure, bool>> setupNotificationListeners();
  
  /// Get the current FCM token
  Future<Either<Failure, String>> getFcmToken();
  
  /// Send app state change notification to server (foreground, background, terminated)
  Future<Either<Failure, bool>> sendAppStateChangeNotification(String state);
} 