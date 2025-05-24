import 'dart:convert';

import 'package:monie/core/errors/exceptions.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class NotificationLocalDataSource {
  /// Gets the cached list of notifications
  Future<List<NotificationModel>> getCachedNotifications();

  /// Cache a list of notifications
  Future<void> cacheNotifications(List<NotificationModel> notifications);

  /// Add a new notification to the cache
  Future<void> addNotification(NotificationModel notification);

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead();

  /// Delete a notification from the cache
  Future<void> deleteNotification(String notificationId);
}

const cachedNotificationsKey = 'CACHED_NOTIFICATIONS';

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final SharedPreferences sharedPreferences;

  NotificationLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<NotificationModel>> getCachedNotifications() async {
    final jsonString = sharedPreferences.getString(cachedNotificationsKey);
    if (jsonString == null) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to parse cached notifications');
    }
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    final jsonList = notifications.map((note) => note.toJson()).toList();    await sharedPreferences.setString(
      cachedNotificationsKey,
      json.encode(jsonList),
    );
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    final notifications = await getCachedNotifications();
    notifications.add(notification);
    await cacheNotifications(notifications);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final notifications = await getCachedNotifications();
    final updatedNotifications = notifications.map((notification) {
      if (notification.id == notificationId) {
        return NotificationModel(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          timestamp: notification.timestamp,
          isRead: true,
          data: notification.data,
        );
      }
      return notification;
    }).toList();
    
    await cacheNotifications(updatedNotifications);
  }

  @override
  Future<void> markAllAsRead() async {
    final notifications = await getCachedNotifications();
    final updatedNotifications = notifications.map((notification) {
      return NotificationModel(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        timestamp: notification.timestamp,
        isRead: true,
        data: notification.data,
      );
    }).toList();
    
    await cacheNotifications(updatedNotifications);
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    final notifications = await getCachedNotifications();
    final updatedNotifications = notifications
        .where((notification) => notification.id != notificationId)
        .toList();
    
    await cacheNotifications(updatedNotifications);
  }
} 