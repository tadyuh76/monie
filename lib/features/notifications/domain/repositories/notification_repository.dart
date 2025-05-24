import 'package:monie/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepository {
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
}
