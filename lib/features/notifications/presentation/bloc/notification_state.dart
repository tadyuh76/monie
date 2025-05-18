import 'package:equatable/equatable.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<Notification> notifications;
  
  const NotificationsLoaded({required this.notifications});
  
  @override
  List<Object?> get props => [notifications];
}

class TokenLoaded extends NotificationState {
  final String token;
  
  const TokenLoaded({required this.token});
  
  @override
  List<Object?> get props => [token];
}

class NotificationActionSuccess extends NotificationState {
  final String message;
  
  const NotificationActionSuccess({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class NotificationError extends NotificationState {
  final String message;
  
  const NotificationError({required this.message});
  
  @override
  List<Object?> get props => [message];
} 