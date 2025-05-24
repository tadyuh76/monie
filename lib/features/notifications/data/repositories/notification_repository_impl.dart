import 'package:monie/features/notifications/data/datasources/notification_datasource.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<List<Notification>> getUserNotifications(String userId) async {
    return await _dataSource.getUserNotifications(userId);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _dataSource.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    await _dataSource.markAllAsRead(userId);
  }

  @override
  Future<void> createNotification(Notification notification) async {
    final notificationModel = NotificationModel(
      id: notification.id,
      userId: notification.userId,
      amount: notification.amount,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    );
    await _dataSource.createNotification(notificationModel);
  }

  @override
  Future<void> createGroupNotifications({
    required String groupId,
    required String title,
    required String message,
    required NotificationType type,
    double? amount,
  }) async {
    await _dataSource.createGroupNotifications(
      groupId: groupId,
      title: title,
      message: message,
      type: type,
      amount: amount,
    );
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _dataSource.deleteNotification(notificationId);
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    return await _dataSource.getUnreadCount(userId);
  }
}
