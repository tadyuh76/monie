import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:monie/core/usecases/usecase.dart';
import 'package:monie/features/notifications/domain/usecases/register_device_usecase.dart';
import 'package:monie/features/notifications/domain/usecases/send_app_state_change_notification_usecase.dart';
import 'package:monie/features/notifications/domain/usecases/setup_notification_listeners_usecase.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final RegisterDeviceUseCase registerDeviceUseCase;
  final SetupNotificationListenersUseCase setupNotificationListenersUseCase;
  final SendAppStateChangeNotificationUseCase sendAppStateChangeNotificationUseCase;

  NotificationBloc({
    required this.registerDeviceUseCase,
    required this.setupNotificationListenersUseCase,
    required this.sendAppStateChangeNotificationUseCase,
  }) : super(NotificationInitial()) {
    on<RegisterDeviceEvent>(_onRegisterDevice);
    on<SetupNotificationListenersEvent>(_onSetupNotificationListeners);
    on<SendAppStateChangeEvent>(_onSendAppStateChange);
  }

  FutureOr<void> _onRegisterDevice(
    RegisterDeviceEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await registerDeviceUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (token) => emit(TokenLoaded(token: token)),
    );
  }

  FutureOr<void> _onSetupNotificationListeners(
    SetupNotificationListenersEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    final result = await setupNotificationListenersUseCase(NoParams());
    result.fold(
      (failure) => emit(NotificationError(message: failure.message)),
      (success) => emit(
        const NotificationActionSuccess(
          message: 'Notification listeners set up successfully',
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
      (failure) => emit(NotificationError(message: failure.message)),
      (success) => emit(
        NotificationActionSuccess(
          message: 'App state change notification sent: ${event.state}',
        ),
      ),
    );
  }
} 