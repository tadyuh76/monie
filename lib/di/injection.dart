import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/core/network/supabase_client.dart';
import 'package:monie/features/account/data/datasources/account_remote_data_source.dart';
import 'package:monie/features/account/data/repositories/account_repository_impl.dart';
import 'package:monie/features/account/domain/repositories/account_repository.dart';
import 'package:monie/features/account/domain/usecases/add_account_usecase.dart'
    as add_account_usecase_alias;
import 'package:monie/features/account/domain/usecases/delete_account_usecase.dart'
    as account_delete_account_usecase;
import 'package:monie/features/account/domain/usecases/get_account_by_id_usecase.dart';
import 'package:monie/features/account/domain/usecases/get_accounts_usecase.dart';
import 'package:monie/features/account/domain/usecases/recalculate_account_balance_usecase.dart';
import 'package:monie/features/account/domain/usecases/update_account_balance_usecase.dart';
import 'package:monie/features/account/domain/usecases/update_account_usecase.dart'
    as account_update_account_usecase;
import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import 'package:monie/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:monie/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';
import 'package:monie/features/authentication/domain/usecases/check_email_exists.dart';
import 'package:monie/features/authentication/domain/usecases/get_current_user.dart';
import 'package:monie/features/authentication/domain/usecases/is_email_verified.dart';
import 'package:monie/features/authentication/domain/usecases/resend_verification_email.dart';
import 'package:monie/features/authentication/domain/usecases/reset_password.dart';
import 'package:monie/features/authentication/domain/usecases/sign_in.dart';
import 'package:monie/features/authentication/domain/usecases/sign_out.dart';
import 'package:monie/features/authentication/domain/usecases/sign_up.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/features/budgets/data/datasources/budget_remote_data_source.dart';
import 'package:monie/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';
import 'package:monie/features/budgets/domain/usecases/add_budget_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/get_active_budgets_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/update_budget_usecase.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/groups/data/datasources/group_remote_datasource.dart';
import 'package:monie/features/groups/data/repositories/group_repository_impl.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';
import 'package:monie/features/groups/domain/usecases/add_member.dart';
import 'package:monie/features/groups/domain/usecases/calculate_debts.dart'
    as calc;
import 'package:monie/features/groups/domain/usecases/create_group.dart';
import 'package:monie/features/groups/domain/usecases/get_group_by_id.dart'
    as get_group;
import 'package:monie/features/groups/domain/usecases/get_group_members.dart'
    as get_members;
import 'package:monie/features/groups/domain/usecases/get_groups.dart';
import 'package:monie/features/groups/domain/usecases/settle_group.dart'
    as settle;
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/notifications/data/datasources/notification_datasource.dart';
import 'package:monie/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:monie/features/notifications/domain/repositories/notification_repository.dart';
import 'package:monie/features/notifications/domain/usecases/create_budget_notification.dart';
import 'package:monie/features/notifications/domain/usecases/create_group_notification.dart';
import 'package:monie/features/notifications/domain/usecases/get_notifications.dart';
import 'package:monie/features/notifications/domain/usecases/get_unread_count.dart';
import 'package:monie/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:monie/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:monie/features/settings/data/repositories/settings_repository.dart';
import 'package:monie/features/settings/domain/repositories/settings_repository.dart';
import 'package:monie/features/settings/domain/usecases/change_password.dart';
import 'package:monie/features/settings/domain/usecases/get_app_settings.dart';
import 'package:monie/features/settings/domain/usecases/get_user_profile.dart';
import 'package:monie/features/settings/domain/usecases/save_app_settings.dart';
import 'package:monie/features/settings/domain/usecases/update_user_profile.dart';
import 'package:monie/features/settings/domain/usecases/upload_avatar.dart';
import 'package:monie/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:monie/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:monie/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:monie/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/create_category_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_categories_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transaction_by_id_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_account_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_budget_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_type_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/transactions/data/repositories/category_repository_impl.dart';
import '../features/transactions/domain/repositories/category_repository.dart';
import 'package:monie/features/groups/domain/usecases/add_group_expense.dart';
import 'package:monie/features/groups/domain/usecases/get_group_transactions.dart';
import 'package:monie/features/groups/domain/usecases/approve_group_transaction.dart';
import 'package:monie/features/groups/domain/usecases/remove_member.dart';
import 'package:monie/features/groups/domain/usecases/update_member_role.dart';

final sl = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
Future<void> configureDependencies() async {
  // This will be filled in by the injectable build_runner when we run code generation
  // We'll need to run build_runner after setting up our repositories and usecases
  // await init(getIt);

  // External
  sl.registerSingleton<SupabaseClientManager>(SupabaseClientManager.instance);

  // Authentication
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Authentication use cases
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => ResendVerificationEmail(sl()));
  sl.registerLazySingleton(() => IsEmailVerified(sl()));
  sl.registerLazySingleton(() => ResetPassword(sl()));
  sl.registerLazySingleton(() => CheckEmailExists(sl()));

  // Data sources
  sl.registerLazySingleton<AccountRemoteDataSource>(
    () => AccountRemoteDataSourceImpl(supabaseClientManager: sl()),
  );

  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(supabaseClientManager: sl()),
  );

  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(supabaseClientManager: sl()),
  );

  // Repository implementations
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepositoryImpl(sl<SupabaseClientManager>()),
  );

  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(sl<SupabaseClientManager>()),
  );

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl<SupabaseClientManager>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAccountsUseCase(sl()));
  sl.registerLazySingleton(
    () => GetAccountByIdUseCase(accountRepository: sl()),
  );
  sl.registerLazySingleton(
    () => add_account_usecase_alias.AddAccountUseCase(sl()),
  );
  sl.registerLazySingleton(
    () => account_update_account_usecase.UpdateAccountUseCase(
      sl<AccountRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => account_delete_account_usecase.DeleteAccountUseCase(
      sl<AccountRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => RecalculateAccountBalanceUseCase(sl<AccountRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateAccountBalanceUseCase(sl<AccountRepository>()),
  );

  sl.registerLazySingleton(() => GetTransactionsUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsByTypeUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsByDateRangeUseCase(sl()));
  sl.registerLazySingleton(() => AddTransactionUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTransactionUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetBudgetsUseCase(sl()));
  sl.registerLazySingleton(() => GetActiveBudgetsUseCase(sl()));
  sl.registerLazySingleton(() => AddBudgetUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBudgetUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBudgetUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => CreateCategoryUseCase(sl()));

  sl.registerLazySingleton(
    () => GetTransactionsByAccountUseCase(sl<TransactionRepository>()),
  );
  sl.registerLazySingleton(
    () => GetTransactionsByBudgetUseCase(sl<TransactionRepository>()),
  );

  // Notifications Feature
  sl.registerLazySingleton<NotificationDataSource>(
    () => NotificationDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );

  // Notification use cases
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkNotificationRead(sl()));
  sl.registerLazySingleton(() => CreateGroupNotification(sl()));
  sl.registerLazySingleton(() => CreateBudgetNotification(sl()));
  sl.registerLazySingleton(() => GetUnreadCount(sl()));

  // BLoCs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      getCurrentUser: sl(),
      signIn: sl(),
      signUp: sl(),
      signOut: sl(),
      resetPassword: sl(),
      resendVerificationEmail: sl(),
      isEmailVerified: sl(),
      checkEmailExists: sl(),
    ),
  );

  sl.registerFactory<HomeBloc>(
    () => HomeBloc(getAccountsUseCase: sl(), getTransactionsUseCase: sl()),
  );

  sl.registerFactory<AccountBloc>(
    () => AccountBloc(
      getAccounts: sl(),
      getAccountById: sl(),
      addAccount: sl(),
      updateAccount: sl(),
      deleteAccount: sl(),
      recalculateAccountBalance: sl(),
      updateAccountBalance: sl(),
    ),
  );

  sl.registerFactory<TransactionsBloc>(
    () => TransactionsBloc(
      getTransactionsUseCase: sl(),
      getTransactionsByTypeUseCase: sl(),
      getTransactionsByDateRangeUseCase: sl(),
      addTransactionUseCase: sl(),
      updateTransactionUseCase: sl(),
      deleteTransactionUseCase: sl(),
    ),
  );

  sl.registerFactory<TransactionBloc>(
    () => TransactionBloc(
      getTransactions: sl<GetTransactionsUseCase>(),
      getTransactionById: sl<GetTransactionByIdUseCase>(),
      createTransaction: sl<AddTransactionUseCase>(),
      updateTransaction: sl<UpdateTransactionUseCase>(),
      deleteTransaction: sl<DeleteTransactionUseCase>(),
      getTransactionsByAccount: sl<GetTransactionsByAccountUseCase>(),
      getTransactionsByBudget: sl<GetTransactionsByBudgetUseCase>(),
      createBudgetNotification: sl<CreateBudgetNotification>(),
      budgetRepository: sl<BudgetRepository>(),
    ),
  );

  sl.registerFactory<BudgetsBloc>(
    () => BudgetsBloc(
      getBudgetsUseCase: sl(),
      getActiveBudgetsUseCase: sl(),
      addBudgetUseCase: sl(),
      updateBudgetUseCase: sl(),
      deleteBudgetUseCase: sl(),
    ),
  );

  sl.registerFactory<CategoriesBloc>(
    () =>
        CategoriesBloc(getCategoriesUseCase: sl(), createCategoryUseCase: sl()),
  );

  sl.registerFactory<NotificationBloc>(
    () => NotificationBloc(
      getNotifications: sl(),
      markNotificationRead: sl(),
      createGroupNotification: sl(),
      getUnreadCount: sl(),
      repository: sl(),
    ),
  );

  // Groups Feature
  sl.registerLazySingleton<GroupRemoteDataSource>(
    () =>
        GroupRemoteDataSourceImpl(supabase: sl<SupabaseClientManager>().client),
  );

  sl.registerLazySingleton<GroupRepository>(
    () => GroupRepositoryImpl(dataSource: sl()),
  );

  // Group usecases
  sl.registerLazySingleton(() => GetGroups(repository: sl()));
  sl.registerLazySingleton(() => get_group.GetGroupById(repository: sl()));
  sl.registerLazySingleton(() => CreateGroup(repository: sl()));
  sl.registerLazySingleton(() => AddMember(repository: sl()));
  sl.registerLazySingleton(() => calc.CalculateDebts(repository: sl()));
  sl.registerLazySingleton(() => settle.SettleGroup(repository: sl()));
  sl.registerLazySingleton(() => AddGroupExpense(repository: sl()));
  sl.registerLazySingleton(() => GetGroupTransactions(repository: sl()));
  sl.registerLazySingleton(() => ApproveGroupTransaction(repository: sl()));
  sl.registerLazySingleton(() => get_members.GetGroupMembers(repository: sl()));
  sl.registerLazySingleton(() => RemoveMember(repository: sl()));
  sl.registerLazySingleton(() => UpdateMemberRole(repository: sl()));

  // Group Bloc
  sl.registerFactory<GroupBloc>(
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

  // Settings
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      supabaseClient: sl(),
      preferences: sharedPreferences,
    ),
  );

  // Register settings use cases
  sl.registerLazySingleton(() => GetAppSettings(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => SaveAppSettings(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => GetUserProfile(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => UpdateUserProfile(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => ChangePassword(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => UploadAvatar(sl<SettingsRepository>()));

  sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      getAppSettings: sl(),
      saveAppSettings: sl(),
      getUserProfile: sl(),
      updateUserProfile: sl(),
      changePassword: sl(),
      uploadAvatar: sl(),
    ),
  );
}
