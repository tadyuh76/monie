import 'package:equatable/equatable.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String userId;

  const LoadNotifications(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  final String userId;

  const MarkAllNotificationsAsRead(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateGroupNotificationEvent extends NotificationEvent {
  final String groupId;
  final String title;
  final String message;
  final NotificationType type;
  final double? amount;

  const CreateGroupNotificationEvent({
    required this.groupId,
    required this.title,
    required this.message,
    required this.type,
    this.amount,
  });

  @override
  List<Object?> get props => [groupId, title, message, type, amount];
}

class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;

  const DeleteNotificationEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class LoadUnreadCount extends NotificationEvent {
  final String userId;

  const LoadUnreadCount(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateTestNotificationEvent extends NotificationEvent {
  final String userId;

  const CreateTestNotificationEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
