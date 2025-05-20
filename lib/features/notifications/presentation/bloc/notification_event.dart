import 'package:equatable/equatable.dart';
import 'package:monie/features/notifications/data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class RegisterDeviceEvent extends NotificationEvent {}

class SetupNotificationListenersEvent extends NotificationEvent {}

class GetNotificationsEvent extends NotificationEvent {}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsReadEvent({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsReadEvent extends NotificationEvent {}

class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;

  const DeleteNotificationEvent({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

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