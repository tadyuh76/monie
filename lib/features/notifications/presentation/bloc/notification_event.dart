import 'package:equatable/equatable.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

// Push notification events
class RegisterDeviceEvent extends NotificationEvent {}

class SetupNotificationListenersEvent extends NotificationEvent {}

class SendAppStateChangeEvent extends NotificationEvent {
  final String state;

  const SendAppStateChangeEvent({required this.state});

  @override
  List<Object?> get props => [state];
}

class RegisterDeviceTokenEvent extends NotificationEvent {
  final String userId;
  final String token;

  const RegisterDeviceTokenEvent({
    required this.userId,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, token];
}

class NotificationReceivedEvent extends NotificationEvent {
  final NotificationModel notification;

  const NotificationReceivedEvent(this.notification);

  @override
  List<Object?> get props => [notification];
}

class TestForegroundNotificationEvent extends NotificationEvent {
  final String userId;

  const TestForegroundNotificationEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class TestBackgroundNotificationEvent extends NotificationEvent {
  final String userId;

  const TestBackgroundNotificationEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class TestTerminatedNotificationEvent extends NotificationEvent {
  final String userId;

  const TestTerminatedNotificationEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Database notification events
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
