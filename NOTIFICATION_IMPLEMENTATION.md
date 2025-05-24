# Notification System Implementation Guide

## Overview

This notification system provides a complete solution for managing notifications in your Flutter app with Supabase backend. It follows clean architecture principles and includes:

- Group transaction notifications
- Group settlement notifications
- Budget alert notifications
- Real-time notification badge with unread count
- Mark as read/unread functionality
- Delete notifications

## Database Schema

The notification system uses this table structure:

```sql
CREATE TABLE notifications (
   notification_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
   user_id uuid REFERENCES users(user_id) ON DELETE CASCADE NOT NULL,
   amount NUMERIC(15,2),
   type VARCHAR(30) NOT NULL,
   title VARCHAR(100) NOT NULL,
   message TEXT,
   is_read BOOLEAN DEFAULT FALSE,
   created_at timestamptz DEFAULT NOW()
);
```

## Features Implemented

### 1. Automatic Group Notifications

**Group Transaction Notifications:**

- When a member adds an expense to a group, all members get notified
- If the expense needs approval, only admins get notified
- When an expense is approved/rejected, all members get notified

**Group Settlement Notifications:**

- When an admin settles a group, all members get notified

### 2. Budget Alert Notifications

Budget notifications are triggered at:

- 50% of budget spent
- 80% of budget spent
- 100% of budget exceeded

### 3. Notification UI Components

**NotificationCard:** Displays individual notifications with:

- Icon based on notification type
- Title and message
- Amount (if applicable)
- Read/unread status indicator
- Relative time display
- Delete functionality

**NotificationBadge:** Shows notification icon with unread count badge

**NotificationsPage:** Full page view of all notifications with:

- Pull to refresh
- Mark all as read
- Empty state
- Error handling

## Usage Examples

### 1. Adding Notification Badge to AppBar

```dart
import 'package:monie/features/notifications/presentation/widgets/notification_badge.dart';

AppBar(
  title: Text('Your App'),
  actions: [
    NotificationBadge(userId: currentUserId),
  ],
)
```

### 2. Creating Custom Notifications

```dart
// Create a group notification
context.read<NotificationBloc>().add(
  CreateGroupNotificationEvent(
    groupId: 'group-id',
    title: 'New Expense Added',
    message: 'John added \$25.00 for lunch',
    type: NotificationType.groupTransaction,
    amount: 25.00,
  ),
);

// Create a budget notification
final createBudgetNotification = sl<CreateBudgetNotification>();
await createBudgetNotification(
  userId: 'user-id',
  budgetName: 'Monthly Groceries',
  amount: 500.0,
  spentAmount: 400.0,
  percentage: 80.0, // 80% spent
);
```

### 3. Loading and Managing Notifications

```dart
// Load notifications for a user
context.read<NotificationBloc>().add(LoadNotifications(userId));

// Mark notification as read
context.read<NotificationBloc>().add(MarkNotificationAsRead(notificationId));

// Mark all notifications as read
context.read<NotificationBloc>().add(MarkAllNotificationsAsRead(userId));

// Delete a notification
context.read<NotificationBloc>().add(DeleteNotificationEvent(notificationId));

// Load unread count only
context.read<NotificationBloc>().add(LoadUnreadCount(userId));
```

### 4. Listening to Notification State

```dart
BlocBuilder<NotificationBloc, NotificationState>(
  builder: (context, state) {
    if (state is NotificationLoading) {
      return CircularProgressIndicator();
    } else if (state is NotificationsLoaded) {
      return ListView.builder(
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          return NotificationCard(
            notification: state.notifications[index],
            onTap: () => _handleNotificationTap(state.notifications[index]),
            onDelete: () => _deleteNotification(state.notifications[index].id),
          );
        },
      );
    } else if (state is NotificationError) {
      return Text('Error: ${state.message}');
    }
    return SizedBox.shrink();
  },
)
```

## Integration Points

### 1. Group Transactions

The notification system is already integrated into the group transaction flow:

- `addGroupExpense()` - Creates notifications for all group members
- `approveGroupTransaction()` - Notifies all members of approval/rejection
- `settleGroup()` - Notifies all members when group is settled

### 2. Budget Monitoring

To integrate budget notifications, add this to your transaction creation logic:

```dart
// After creating a transaction, check if it affects any budgets
final createBudgetNotification = sl<CreateBudgetNotification>();

// Get user's budgets and check spending
for (final budget in userBudgets) {
  final spentAmount = calculateSpentAmount(budget);
  final percentage = (spentAmount / budget.amount) * 100;

  if (percentage >= 50) { // Only notify at 50%, 80%, and 100%
    await createBudgetNotification(
      userId: userId,
      budgetName: budget.name,
      amount: budget.amount,
      spentAmount: spentAmount,
      percentage: percentage,
    );
  }
}
```

### 3. Real-time Updates

For real-time notifications, you can set up Supabase real-time subscriptions:

```dart
// In your main app or notification service
final subscription = supabase
    .from('notifications')
    .stream(primaryKey: ['notification_id'])
    .eq('user_id', currentUserId)
    .listen((data) {
      // Refresh notification count when new notifications arrive
      context.read<NotificationBloc>().add(LoadUnreadCount(currentUserId));
    });
```

## Notification Types

The system supports these notification types:

- `groupTransaction` - For group expense activities
- `groupSettlement` - For group settlement activities
- `budgetAlert` - For budget threshold alerts
- `general` - For general notifications

## Localization

Notification strings are localized in:

- `assets/lang/en.json`
- `assets/lang/vi.json`

Add new notification strings following the pattern:

```json
{
  "notifications_title": "Notifications",
  "notifications_mark_all_read": "Mark all as read",
  "notifications_empty_title": "No notifications",
  "notifications_empty_subtitle": "You're all caught up! New notifications will appear here."
}
```

## Dependencies Added

The notification system is registered in `lib/di/injection_container.dart`:

```dart
// Use cases
sl.registerLazySingleton(() => GetNotifications(sl()));
sl.registerLazySingleton(() => MarkNotificationRead(sl()));
sl.registerLazySingleton(() => CreateGroupNotification(sl()));
sl.registerLazySingleton(() => CreateBudgetNotification(sl()));
sl.registerLazySingleton(() => GetUnreadCount(sl()));

// Repository
sl.registerLazySingleton<NotificationRepository>(
  () => NotificationRepositoryImpl(sl()),
);

// Data sources
sl.registerLazySingleton<NotificationDataSource>(
  () => NotificationDataSourceImpl(sl()),
);

// Bloc
sl.registerFactory(
  () => NotificationBloc(
    getNotifications: sl(),
    markNotificationRead: sl(),
    createGroupNotification: sl(),
    getUnreadCount: sl(),
    repository: sl(),
  ),
);
```

## Testing

To test the notification system:

1. **Create a group and add expenses** - Check that all members receive notifications
2. **Approve/reject group expenses** - Verify approval notifications are sent
3. **Settle a group** - Confirm settlement notifications are delivered
4. **Exceed budget thresholds** - Test budget alert notifications
5. **Mark notifications as read** - Verify unread count updates
6. **Delete notifications** - Confirm notifications are removed

## Future Enhancements

Potential improvements:

- Push notifications using Firebase Cloud Messaging
- Email notifications for important events
- Notification preferences/settings
- Notification categories and filtering
- Bulk notification actions
- Notification history and analytics

This notification system provides a solid foundation that can be extended based on your app's specific needs.
