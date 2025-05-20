import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:monie/core/network/supabase_client.dart';
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
import 'package:monie/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:monie/features/budgets/domain/repositories/budget_repository.dart';
import 'package:monie/features/budgets/domain/usecases/get_budgets_usecase.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/home/data/repositories/account_repository_impl.dart';
import 'package:monie/features/home/domain/repositories/account_repository.dart';
import 'package:monie/features/home/domain/usecases/get_accounts_usecase.dart';
import 'package:monie/features/home/domain/usecases/update_account_usecase.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/transactions/data/datasources/category_remote_data_source.dart';
import 'package:monie/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:monie/features/transactions/data/repositories/category_repository_impl.dart';
import 'package:monie/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:monie/features/transactions/domain/repositories/category_repository.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:monie/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/create_category_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/get_active_budgets_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/add_budget_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/update_budget_usecase.dart';
import 'package:monie/features/budgets/domain/usecases/delete_budget_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_categories_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transaction_by_id_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_by_type_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:monie/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:monie/features/transactions/presentation/bloc/categories_bloc.dart';
import 'package:monie/features/settings/data/repositories/settings_repository.dart';
import 'package:monie/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';

import 'package:monie/features/account/presentation/bloc/account_bloc.dart';
import '../features/home/domain/usecases/add_account_usecase.dart';
import '../features/home/domain/usecases/delete_account_usecase.dart';

final getIt = GetIt.instance;

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
  getIt.registerSingleton<SupabaseClientManager>(
    SupabaseClientManager.instance,
  );

  // Authentication
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt()),
  );

  // Authentication use cases
  getIt.registerLazySingleton(() => GetCurrentUser(getIt()));
  getIt.registerLazySingleton(() => SignUp(getIt()));
  getIt.registerLazySingleton(() => SignIn(getIt()));
  getIt.registerLazySingleton(() => SignOut(getIt()));
  getIt.registerLazySingleton(() => ResendVerificationEmail(getIt()));
  getIt.registerLazySingleton(() => IsEmailVerified(getIt()));
  getIt.registerLazySingleton(() => ResetPassword(getIt()));
  getIt.registerLazySingleton(() => CheckEmailExists(getIt()));

  // Repository implementations
  getIt.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl());
  getIt.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(supabaseClientManager: getIt()),
  );
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(
      supabaseClient: SupabaseClientManager.instance,
    ),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(getIt<SupabaseClientManager>()),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetAccountsUseCase(getIt()));
  getIt.registerLazySingleton(() => AddAccountUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateAccountUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteAccountUseCase(getIt()));

  getIt.registerLazySingleton(() => GetTransactionsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTransactionByIdUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTransactionsByTypeUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTransactionsByDateRangeUseCase(getIt()));
  getIt.registerLazySingleton(() => AddTransactionUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateTransactionUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteTransactionUseCase(getIt()));
  getIt.registerLazySingleton(() => GetBudgetsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetActiveBudgetsUseCase(getIt()));
  getIt.registerLazySingleton(() => AddBudgetUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateBudgetUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteBudgetUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCategoriesUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateCategoryUseCase(getIt()));

  // BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      getCurrentUser: getIt(),
      signIn: getIt(),
      signUp: getIt(),
      signOut: getIt(),
      resetPassword: getIt(),
      resendVerificationEmail: getIt(),
      isEmailVerified: getIt(),
      checkEmailExists: getIt(),
    ),
  );

  getIt.registerFactory<HomeBloc>(
    () =>
        HomeBloc(getAccountsUseCase: getIt(), getTransactionsUseCase: getIt()),
  );

  getIt.registerFactory<AccountBloc>(
    () => AccountBloc(
      getAccountsUseCase: getIt(),
      addAccountUseCase: getIt(),
      updateAccountUseCase: getIt(),
      deleteAccountUseCase: getIt(),
    ),
  );

  getIt.registerFactory<TransactionsBloc>(
    () => TransactionsBloc(
      getTransactionsUseCase: getIt(),
      getTransactionsByTypeUseCase: getIt(),
      getTransactionsByDateRangeUseCase: getIt(),
      addTransactionUseCase: getIt(),
      updateTransactionUseCase: getIt(),
      deleteTransactionUseCase: getIt(),
    ),
  );

  getIt.registerFactory<BudgetsBloc>(
    () => BudgetsBloc(
      getBudgetsUseCase: getIt(),
      getActiveBudgetsUseCase: getIt(),
      addBudgetUseCase: getIt(),
      updateBudgetUseCase: getIt(),
      deleteBudgetUseCase: getIt(),
    ),
  );

  getIt.registerFactory<CategoriesBloc>(
    () => CategoriesBloc(
      getCategoriesUseCase: getIt(),
      createCategoryUseCase: getIt(),
    ),
  );

  // Settings
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(
      supabaseClient: getIt(),
      preferences: sharedPreferences,
    ),
  );

  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(repository: getIt(), authBloc: getIt<AuthBloc>()),
  );
}
