import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:monie/features/home/data/repositories/account_repository_impl.dart';
import 'package:monie/features/home/domain/repositories/account_repository.dart';
import 'package:monie/features/home/domain/usecases/get_accounts_usecase.dart';
import 'package:monie/features/home/presentation/bloc/home_bloc.dart';
import 'package:monie/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:monie/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:monie/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:monie/features/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:monie/features/budgets/presentation/bloc/budgets_bloc.dart';
import 'package:monie/features/budgets/domain/usecases/get_budgets_usecase.dart';

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

  // Repository implementations
  getIt.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl());
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(),
  );

  // Use cases
  getIt.registerLazySingleton(() => GetAccountsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTransactionsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetBudgetsUseCase(getIt()));

  // BLoCs
  getIt.registerFactory(
    () =>
        HomeBloc(getAccountsUseCase: getIt(), getTransactionsUseCase: getIt()),
  );

  getIt.registerFactory(
    () => TransactionsBloc(getTransactionsUseCase: getIt()),
  );

  getIt.registerFactory(() => BudgetsBloc(getBudgetsUseCase: getIt()));
}
