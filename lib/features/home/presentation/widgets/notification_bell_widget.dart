import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_state.dart';
import 'package:monie/features/notifications/presentation/widgets/notifications_modal.dart';

class NotificationBellWidget extends StatefulWidget {
  final String userId;

  const NotificationBellWidget({super.key, required this.userId});

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  @override
  void initState() {
    super.initState();
    // Load unread count when widget is created
    context.read<NotificationBloc>().add(LoadUnreadCount(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;

        if (state is NotificationsLoaded) {
          unreadCount = state.unreadCount;
        } else if (state is UnreadCountLoaded) {
          unreadCount = state.count;
        }

        return GestureDetector(
          onLongPress: () => _createTestNotification(context),
          child: IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 28,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showNotificationsModal(context),
            tooltip: 'Notifications',
          ),
        );
      },
    );
  }

  void _showNotificationsModal(BuildContext context) {
    NotificationsModal.show(context, widget.userId);
  }

  void _createTestNotification(BuildContext context) {
    // Create a test notification for debugging
    context.read<NotificationBloc>().add(
      CreateTestNotificationEvent(widget.userId),
    );
  }
}
