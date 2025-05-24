import 'package:flutter/material.dart';
import 'package:monie/core/themes/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationBellWidget extends StatelessWidget {
  final String userId;
  // For now, we mock unread count
  final int unreadCount;

  const NotificationBellWidget({
    super.key,
    required this.userId,
    this.unreadCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
            size: 28,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
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
      onPressed: () => _showNotificationsDialog(context),
      tooltip: 'Notifications',
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _NotificationsDialog(),
    );
  }
}

class _NotificationsDialog extends StatelessWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Mock notifications with date
    final now = DateTime.now();
    final notifications = [
      {
        'title': 'Budget Limit Approaching',
        'message': 'You have spent 90% of your Food budget.',
        'type': 'budget_limit',
        'date': now,
        'is_read': false,
      },
      {
        'title': 'Group Transaction',
        'message': 'A group expense was added: Movie Night.',
        'type': 'group_transaction',
        'date': now.subtract(const Duration(hours: 2)),
        'is_read': false,
      },
      {
        'title': 'Group Settlement',
        'message': 'You settled up with Alice in Friends Group.',
        'type': 'group_settlement',
        'date': now.subtract(const Duration(days: 1)),
        'is_read': true,
      },
      {
        'title': 'Daily Reminder',
        'message': 'Don\'t forget to add your transactions today!',
        'type': 'reminder',
        'date': now.subtract(const Duration(days: 2)),
        'is_read': true,
      },
    ];
    // Group notifications by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final n in notifications) {
      final date = n['date'] as DateTime;
      String section;
      if (DateUtils.isSameDay(date, now)) {
        section = 'Today';
      } else if (DateUtils.isSameDay(
        date,
        now.subtract(const Duration(days: 1)),
      )) {
        section = 'Yesterday';
      } else {
        section = DateFormat('MMM d, yyyy').format(date);
      }
      grouped.putIfAbsent(section, () => []).add(n);
    }
    // Sort sections: Today, Yesterday, then earlier (descending)
    final sectionOrder = ['Today', 'Yesterday'];
    final sortedSections = [
      ...sectionOrder.where((s) => grouped.containsKey(s)),
      ...grouped.keys.where((s) => !sectionOrder.contains(s)).toList()
        ..sort((a, b) => b.compareTo(a)),
    ];
    return Dialog(
      backgroundColor: isDarkMode ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child:
                    notifications.isEmpty
                        ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              'No notifications',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.white54
                                        : Colors.black45,
                              ),
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 0,
                          ),
                          itemCount: sortedSections.length,
                          itemBuilder: (context, sectionIdx) {
                            final section = sortedSections[sectionIdx];
                            final items = grouped[section]!;
                            // Sort newest first in each section
                            items.sort(
                              (a, b) => (b['date'] as DateTime).compareTo(
                                a['date'] as DateTime,
                              ),
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    16,
                                    24,
                                    8,
                                  ),
                                  child: Text(
                                    section,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                    ),
                                  ),
                                ),
                                ...items.map(
                                  (n) => _NotificationTile(
                                    title: n['title'] as String,
                                    message: n['message'] as String?,
                                    type: n['type'] as String,
                                    isRead: n['is_read'] as bool,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String? message;
  final String type;
  final bool isRead;

  const _NotificationTile({
    required this.title,
    this.message,
    required this.type,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color iconColor;
    IconData iconData;
    switch (type) {
      case 'budget_limit':
        iconColor = Colors.orangeAccent;
        iconData = Icons.warning_amber_rounded;
        break;
      case 'group_transaction':
        iconColor = AppColors.primary;
        iconData = Icons.groups_2_rounded;
        break;
      case 'group_settlement':
        iconColor = Colors.blueAccent;
        iconData = Icons.handshake_rounded;
        break;
      case 'reminder':
        iconColor = AppColors.secondary;
        iconData = Icons.notifications_active_rounded;
        break;
      default:
        iconColor = isDarkMode ? Colors.white70 : Colors.black54;
        iconData = Icons.notifications_none_rounded;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
