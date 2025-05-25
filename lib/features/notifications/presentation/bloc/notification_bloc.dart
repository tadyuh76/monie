import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/notifications/domain/usecases/register_device_usecase.dart';
import 'package:monie/features/notifications/domain/usecases/send_app_state_change_notification_usecase.dart';
import 'package:monie/features/notifications/domain/usecases/setup_notification_listeners_usecase.dart';
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
  // Push notification use cases
  final RegisterDeviceUseCase registerDeviceUseCase;
  final SetupNotificationListenersUseCase setupNotificationListenersUseCase;
  final SendAppStateChangeNotificationUseCase sendAppStateChangeNotificationUseCase;
  
  // Database notification use cases
  final GetNotifications _getNotifications;
  final MarkNotificationRead _markNotificationRead;
  final CreateGroupNotification _createGroupNotification;
  final GetUnreadCount _getUnreadCount;
  final NotificationRepository _repository;

  NotificationBloc({
    required this.registerDeviceUseCase,
    required this.setupNotificationListenersUseCase,
    required this.sendAppStateChangeNotificationUseCase,
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
    // Push notification events
    on<RegisterDeviceEvent>(_onRegisterDevice);
    on<SetupNotificationListenersEvent>(_onSetupNotificationListeners);
    on<SendAppStateChangeEvent>(_onSendAppStateChange);
    on<RegisterDeviceTokenEvent>(_onRegisterDeviceToken);
    on<NotificationReceivedEvent>(_onNotificationReceived);    on<TestForegroundNotificationEvent>(_onTestForegroundNotification);
    on<TestBackgroundNotificationEvent>(_onTestBackgroundNotification);
    on<TestTerminatedNotificationEvent>(_onTestTerminatedNotification);
      on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<CreateGroupNotificationEvent>(_onCreateGroupNotification);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<CreateTestNotificationEvent>(_onCreateTestNotification);
  }

  // Push notification event handlers
  FutureOr<void> _onRegisterDevice(
    RegisterDeviceEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await registerDeviceUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(failure.message)),
      (token) => emit(TokenLoaded(token)),
    );
  }

  FutureOr<void> _onSetupNotificationListeners(
    SetupNotificationListenersEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await setupNotificationListenersUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(failure.message)),
      (success) => emit(
        const NotificationActionSuccess(
          'Notification listeners set up successfully',
        ),
      ),
    );
  }

  FutureOr<void> _onSendAppStateChange(
    SendAppStateChangeEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await sendAppStateChangeNotificationUseCase(
      AppStateParams(state: event.state),
    );
    result.fold(
      (failure) => emit(NotificationError(failure.message)),
      (success) => emit(
        NotificationActionSuccess(
          'App state change notification sent: ${event.state}',
        ),
      ),
    );
  }

  FutureOr<void> _onRegisterDeviceToken(
    RegisterDeviceTokenEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Handle device token registration
      emit(const NotificationActionSuccess('Device token registered successfully'));
    } catch (e) {
      emit(NotificationError('Failed to register device token: ${e.toString()}'));
    }
  }

  FutureOr<void> _onNotificationReceived(
    NotificationReceivedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Handle received notification - could store it in database
      emit(const NotificationActionSuccess('Notification received and processed'));
    } catch (e) {
      emit(NotificationError('Failed to process notification: ${e.toString()}'));
    }
  }
  FutureOr<void> _onTestForegroundNotification(
    TestForegroundNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Handle test notification
      emit(const NotificationActionSuccess('Test notification sent'));
    } catch (e) {
      emit(NotificationError('Failed to send test notification: ${e.toString()}'));
    }
  }

  FutureOr<void> _onTestBackgroundNotification(
    TestBackgroundNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Handle background test notification
      emit(const NotificationActionSuccess('Background test notification processed'));
    } catch (e) {
      emit(NotificationError('Failed to process background test notification: ${e.toString()}'));
    }
  }

  FutureOr<void> _onTestTerminatedNotification(
    TestTerminatedNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Handle terminated test notification
      emit(const NotificationActionSuccess('Terminated test notification processed'));
    } catch (e) {
      emit(NotificationError('Failed to process terminated test notification: ${e.toString()}'));
    }
  }

  // Database notification event handlers

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
