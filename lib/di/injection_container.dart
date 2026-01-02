import 'package:get_it/get_it.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/groups/data/datasources/group_remote_datasource.dart';
import 'package:monie/features/groups/data/repositories/group_repository_impl.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';
import 'package:monie/features/groups/domain/usecases/add_group_expense.dart';
import 'package:monie/features/groups/domain/usecases/add_member.dart';
import 'package:monie/features/groups/domain/usecases/approve_group_transaction.dart';
import 'package:monie/features/groups/domain/usecases/calculate_debts.dart'
    as calc;
import 'package:monie/features/groups/domain/usecases/create_group.dart';
import 'package:monie/features/groups/domain/usecases/get_group_by_id.dart'
    as get_group;
import 'package:monie/features/groups/domain/usecases/get_group_members.dart'
    as get_members;
import 'package:monie/features/groups/domain/usecases/get_group_transactions.dart'
    as get_transactions;
import 'package:monie/features/groups/domain/usecases/get_groups.dart';
import 'package:monie/features/groups/domain/usecases/remove_member.dart';
import 'package:monie/features/groups/domain/usecases/settle_group.dart'
    as settle;
import 'package:monie/features/groups/domain/usecases/update_member_role.dart';
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';

// Notification imports
import 'package:monie/features/notifications/data/datasources/notification_datasource.dart';
import 'package:monie/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';
import 'package:monie/features/notifications/domain/usecases/create_budget_notification.dart';
import 'package:monie/features/notifications/domain/usecases/create_group_notification.dart';
import 'package:monie/features/notifications/domain/usecases/get_notifications.dart';
import 'package:monie/features/notifications/domain/usecases/get_unread_count.dart';
import 'package:monie/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';

// Daily Reminder imports
import 'package:monie/core/services/notification_service.dart';
import 'package:monie/features/daily_reminder/data/datasources/daily_reminder_local_datasource.dart';
import 'package:monie/features/daily_reminder/data/repositories/daily_reminder_repository_impl.dart';
import 'package:monie/features/daily_reminder/data/services/daily_reminder_alarm_service.dart';
import 'package:monie/features/daily_reminder/domain/repositories/daily_reminder_repository.dart';
import 'package:monie/features/daily_reminder/domain/usecases/add_reminder.dart';
import 'package:monie/features/daily_reminder/domain/usecases/delete_reminder.dart';
import 'package:monie/features/daily_reminder/domain/usecases/get_reminder.dart';
import 'package:monie/features/daily_reminder/domain/usecases/get_all_reminders.dart';
import 'package:monie/features/daily_reminder/domain/usecases/update_reminder.dart';
import 'package:monie/features/daily_reminder/presentation/bloc/daily_reminder_bloc.dart';

// Service locator instance
final sl = GetIt.instance;

void setup() {
  // External
  sl.registerLazySingleton(() => SupabaseClientManager.instance);
  sl.registerLazySingleton(() => SupabaseClientManager.instance.client);

  // Core Services
  sl.registerLazySingleton(() => NotificationService());

  // Features
  _setupAuthFeature();
  _setupTransactionsFeature();
  _setupBudgetsFeature();
  _setupSettingsFeature();
  _setupGroupsFeature();
  _setupNotificationsFeature();
  _setupDailyReminderFeature();
}

// Auth Feature
void _setupAuthFeature() {
  // ... existing auth setup ...
}

// Transactions Feature
void _setupTransactionsFeature() {
  // ... existing transactions setup ...
}

// Budgets Feature
void _setupBudgetsFeature() {
  // ... existing budgets setup ...
}

// Settings Feature
void _setupSettingsFeature() {
  // ... existing settings setup ...
}

// Groups Feature
void _setupGroupsFeature() {
  // Bloc
  sl.registerFactory(
    () => GroupBloc(
      getGroups: sl(),
      getGroupById: sl(),
      createGroup: sl(),
      addMember: sl(),
      calculateDebts: sl(),
      settleGroup: sl(),
      addGroupExpense: sl(),
      getGroupTransactions: sl(),
      approveGroupTransaction: sl(),
      getGroupMembers: sl(),
      removeMember: sl(),
      updateMemberRole: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetGroups(repository: sl()));
  sl.registerLazySingleton(() => get_group.GetGroupById(repository: sl()));
  sl.registerLazySingleton(() => CreateGroup(repository: sl()));
  sl.registerLazySingleton(() => AddMember(repository: sl()));
  sl.registerLazySingleton(() => calc.CalculateDebts(sl()));
  sl.registerLazySingleton(() => settle.SettleGroup(sl()));
  sl.registerLazySingleton(() => get_members.GetGroupMembers(sl()));
  sl.registerLazySingleton(
    () => get_transactions.GetGroupTransactions(repository: sl()),
  );
  sl.registerLazySingleton(() => ApproveGroupTransaction(repository: sl()));
  sl.registerLazySingleton(() => AddGroupExpense(repository: sl()));
  sl.registerLazySingleton(() => RemoveMember(repository: sl()));
  sl.registerLazySingleton(() => UpdateMemberRole(repository: sl()));

  // Repository
  sl.registerLazySingleton<GroupRepository>(
    () => GroupRepositoryImpl(dataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<GroupRemoteDataSource>(
    () => GroupRemoteDataSourceImpl(supabase: sl()),
  );
}

// Notifications Feature
void _setupNotificationsFeature() {
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
}

// Daily Reminder Feature
void _setupDailyReminderFeature() {
  // Bloc
  sl.registerFactory(
    () => DailyReminderBloc(
      getReminder: sl(),
      getAllReminders: sl(),
      addReminder: sl(),
      updateReminder: sl(),
      deleteReminder: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetReminder(repository: sl()));
  sl.registerLazySingleton(() => GetAllReminders(sl()));
  sl.registerLazySingleton(() => AddReminder(repository: sl()));
  sl.registerLazySingleton(() => UpdateReminder(repository: sl()));
  sl.registerLazySingleton(() => DeleteReminder(repository: sl()));

  // Repository
  sl.registerLazySingleton<DailyReminderRepository>(
    () => DailyReminderRepositoryImpl(
      localDataSource: sl(),
      alarmService: sl(),
    ),
  );

  // Services
  sl.registerLazySingleton(() {
    final service = DailyReminderAlarmService();
    service.initialize(); // Initialize timezone
    return service;
  });

  // Data sources
  sl.registerLazySingleton<DailyReminderLocalDataSource>(
    () => DailyReminderLocalDataSource(),
  );
}
