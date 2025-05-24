import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/notifications/domain/usecases/create_group_notification.dart';
import 'package:monie/features/notifications/domain/usecases/get_notifications.dart';
import 'package:monie/features/notifications/domain/usecases/get_unread_count.dart';
import 'package:monie/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_state.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart'
    as notification_entity;

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications _getNotifications;
  final MarkNotificationRead _markNotificationRead;
  final CreateGroupNotification _createGroupNotification;
  final GetUnreadCount _getUnreadCount;
  final NotificationRepository _repository;

  NotificationBloc({
    required GetNotifications getNotifications,
    required MarkNotificationRead markNotificationRead,
    required CreateGroupNotification createGroupNotification,
    required GetUnreadCount getUnreadCount,
    required NotificationRepository repository,
  }) : _getNotifications = getNotifications,
       _markNotificationRead = markNotificationRead,
       _createGroupNotification = createGroupNotification,
       _getUnreadCount = getUnreadCount,
       _repository = repository,
       super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<CreateGroupNotificationEvent>(_onCreateGroupNotification);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<CreateTestNotificationEvent>(_onCreateTestNotification);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());

      final notifications = await _getNotifications(event.userId);
      final unreadCount = await _getUnreadCount(event.userId);

      emit(
        NotificationsLoaded(
          notifications: notifications,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      emit(NotificationError('Failed to load notifications: ${e.toString()}'));
    }
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _markNotificationRead(event.notificationId);

      // Update current state if we have notifications loaded
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications =
            currentState.notifications.map((notification) {
              if (notification.id == event.notificationId) {
                return notification.copyWith(isRead: true);
              }
              return notification;
            }).toList();

        final newUnreadCount =
            updatedNotifications.where((n) => !n.isRead).length;

        emit(
          currentState.copyWith(
            notifications: updatedNotifications,
            unreadCount: newUnreadCount,
          ),
        );
      }
    } catch (e) {
      emit(
        NotificationError(
          'Failed to mark notification as read: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.markAllAsRead(event.userId);

      // Update current state if we have notifications loaded
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications =
            currentState.notifications
                .map((notification) => notification.copyWith(isRead: true))
                .toList();

        emit(
          currentState.copyWith(
            notifications: updatedNotifications,
            unreadCount: 0,
          ),
        );
      }

      // Don't emit NotificationActionSuccess here as it causes the flash issue
      // The state update above is sufficient
    } catch (e) {
      emit(
        NotificationError(
          'Failed to mark all notifications as read: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCreateGroupNotification(
    CreateGroupNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _createGroupNotification(
        groupId: event.groupId,
        title: event.title,
        message: event.message,
        type: event.type,
        amount: event.amount,
      );

      emit(
        const NotificationActionSuccess(
          'Group notification created successfully',
        ),
      );
    } catch (e) {
      emit(
        NotificationError(
          'Failed to create group notification: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _repository.deleteNotification(event.notificationId);

      // Update current state if we have notifications loaded
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications =
            currentState.notifications
                .where(
                  (notification) => notification.id != event.notificationId,
                )
                .toList();

        final newUnreadCount =
            updatedNotifications.where((n) => !n.isRead).length;

        emit(
          currentState.copyWith(
            notifications: updatedNotifications,
            unreadCount: newUnreadCount,
          ),
        );
      }

      // Don't emit NotificationActionSuccess here as it causes the flash issue
      // The state update above is sufficient
    } catch (e) {
      emit(NotificationError('Failed to delete notification: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final count = await _getUnreadCount(event.userId);
      emit(UnreadCountLoaded(count));
    } catch (e) {
      emit(NotificationError('Failed to load unread count: ${e.toString()}'));
    }
  }

  Future<void> _onCreateTestNotification(
    CreateTestNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Create a test notification
      final testNotification = notification_entity.Notification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: event.userId,
        type: notification_entity.NotificationType.general,
        title: 'Test Notification',
        message: 'This is a test notification to verify the system is working.',
        isRead: false,
        createdAt: DateTime.now(),
        amount: 100.0,
      );

      await _repository.createNotification(testNotification);

      emit(const NotificationActionSuccess('Test notification created!'));

      // Reload notifications to show the new one
      add(LoadNotifications(event.userId));
    } catch (e) {
      emit(
        NotificationError(
          'Failed to create test notification: ${e.toString()}',
        ),
      );
    }
  }
}
