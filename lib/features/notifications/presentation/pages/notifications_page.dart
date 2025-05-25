import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monie/core/localization/app_localizations.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart'
    as notification_entity;
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_event.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_state.dart';
import 'package:monie/features/notifications/presentation/widgets/notification_card.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotifications(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.background : Colors.grey[50],
      appBar: AppBar(
        title: Text(context.tr('notifications_title')),
        backgroundColor: isDarkMode ? AppColors.surface : Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.mark_email_read),
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      MarkAllNotificationsAsRead(widget.userId),
                    );
                  },
                  tooltip: context.tr('notifications_mark_all_read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is NotificationActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return _buildEmptyState(context, isDarkMode);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationBloc>().add(
                  LoadNotifications(widget.userId),
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return NotificationCard(
                    notification: notification,
                    onTap: () => _onNotificationTap(notification),
                    onDelete: () => _onDeleteNotification(notification.id),
                  );
                },
              ),
            );
          } else if (state is NotificationError) {
            return _buildErrorState(context, state.message, isDarkMode);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('notifications_empty_title'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('notifications_empty_subtitle'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
    bool isDarkMode,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            context.tr('common_error'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<NotificationBloc>().add(
                LoadNotifications(widget.userId),
              );
            },
            child: Text(context.tr('common_retry')),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(notification_entity.Notification notification) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationAsRead(notification.id),
      );
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case notification_entity.NotificationType.groupTransaction:
        // Navigate to group details or transaction details
        break;
      case notification_entity.NotificationType.groupSettlement:
        // Navigate to group settlement details
        break;
      case notification_entity.NotificationType.budgetAlert:
        // Navigate to budget details
        break;
      case notification_entity.NotificationType.general:
        // Handle general notifications
        break;
    }
  }

  void _onDeleteNotification(String notificationId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('notifications_delete_title')),
            content: Text(context.tr('notifications_delete_message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('common_cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<NotificationBloc>().add(
                    DeleteNotificationEvent(notificationId),
                  );
                },
                child: Text(
                  context.tr('common_delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
