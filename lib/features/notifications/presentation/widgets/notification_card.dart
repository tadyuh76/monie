import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:monie/features/notifications/domain/entities/notification.dart'
    as notification_entity;

class NotificationCard extends StatelessWidget {
  final notification_entity.Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.isRead ? 1 : 3,
      color: isDarkMode ? AppColors.surface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getNotificationColor(
                    notification.type,
                  ).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    // Always add consistent spacing after title
                    const SizedBox(height: 6),

                    // Message section with consistent spacing
                    if (notification.message != null)
                      Text(
                        notification.message!,
                        style: textTheme.bodyMedium?.copyWith(
                          color:
                              isDarkMode
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Amount section with consistent spacing
                    if (notification.amount != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(
                            notification.type,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '\$${notification.amount!.toStringAsFixed(2)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: _getNotificationColor(notification.type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    // Always add consistent spacing before bottom row
                    const SizedBox(height: 12),

                    // Bottom row with date and delete button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(notification.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color:
                                isDarkMode
                                    ? Colors.white54
                                    : Colors.grey.shade500,
                          ),
                        ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: onDelete,
                            color: Colors.red.shade400,
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(notification_entity.NotificationType type) {
    switch (type) {
      case notification_entity.NotificationType.groupTransaction:
        return Icons.group;
      case notification_entity.NotificationType.groupSettlement:
        return Icons.account_balance;
      case notification_entity.NotificationType.budgetAlert:
        return Icons.warning;
      case notification_entity.NotificationType.general:
        return Icons.info;
    }
  }

  Color _getNotificationColor(notification_entity.NotificationType type) {
    switch (type) {
      case notification_entity.NotificationType.groupTransaction:
        return Colors.blue;
      case notification_entity.NotificationType.groupSettlement:
        return Colors.green;
      case notification_entity.NotificationType.budgetAlert:
        return Colors.orange;
      case notification_entity.NotificationType.general:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
