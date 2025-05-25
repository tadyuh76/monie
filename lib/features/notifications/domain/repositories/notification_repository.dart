import 'package:dartz/dartz.dart';
import 'package:monie/core/errors/failures.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepository {
  /// Database operations for notifications
  Future<List<Notification>> getUserNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> createNotification(Notification notification);
  Future<void> createGroupNotifications({
    required String groupId,
    required String title,
    required String message,
    required NotificationType type,
    double? amount,
  });
  Future<void> deleteNotification(String notificationId);
  Future<int> getUnreadCount(String userId);
  
  /// Push notification operations with error handling
  Future<Either<Failure, String>> registerDevice();
  Future<Either<Failure, bool>> updateFcmToken(String token);
  Future<Either<Failure, List<Notification>>> getNotifications();
  Future<Either<Failure, bool>> markNotificationAsRead(String notificationId);
  Future<Either<Failure, bool>> markAllNotificationsAsRead();
  Future<Either<Failure, bool>> deleteNotificationWithResult(String notificationId);
  Future<Either<Failure, bool>> setupNotificationListeners();
  Future<Either<Failure, String>> getFcmToken();
  Future<Either<Failure, bool>> sendAppStateChangeNotification(String state);
}
