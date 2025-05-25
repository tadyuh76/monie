import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';

abstract class NotificationDataSource {
  Future<List<NotificationModel>> getUserNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> createNotification(NotificationModel notification);
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

class NotificationDataSourceImpl implements NotificationDataSource {
  final SupabaseClientManager _supabaseClient;

  NotificationDataSourceImpl(this._supabaseClient);

  @override
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _supabaseClient.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseClient.client
          .from('notifications')
          .update({'is_read': true})
          .eq('notification_id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabaseClient.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> createNotification(NotificationModel notification) async {
    try {
      final notificationData = notification.toJson();
      // Remove notification_id for insert
      notificationData.remove('notification_id');

      await _supabaseClient.client
          .from('notifications')
          .insert(notificationData);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  @override
  Future<void> createGroupNotifications({
    required String groupId,
    required String title,
    required String message,
    required NotificationType type,
    double? amount,
  }) async {
    try {
      // Get all group members
      final membersResponse = await _supabaseClient.client
          .from('group_members')
          .select('user_id')
          .eq('group_id', groupId);

      final List<String> memberIds =
          (membersResponse as List)
              .map((member) => member['user_id'] as String)
              .toList();

      // Create notifications for all members
      final notifications =
          memberIds
              .map(
                (userId) => {
                  'user_id': userId,
                  'amount': amount,
                  'type': type.value,
                  'title': title,
                  'message': message,
                  'is_read': false,
                  'created_at': DateTime.now().toIso8601String(),
                },
              )
              .toList();

      if (notifications.isNotEmpty) {
        await _supabaseClient.client
            .from('notifications')
            .insert(notifications);
      }
    } catch (e) {
      throw Exception('Failed to create group notifications: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabaseClient.client
          .from('notifications')
          .delete()
          .eq('notification_id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabaseClient.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }
}
