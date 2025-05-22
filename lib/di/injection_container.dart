import 'package:get_it/get_it.dart';
import 'package:monie/features/groups/data/datasources/group_remote_datasource.dart';
import 'package:monie/features/groups/data/repositories/group_repository_impl.dart';
import 'package:monie/features/groups/domain/repositories/group_repository.dart';
import 'package:monie/features/groups/domain/usecases/add_member.dart';
import 'package:monie/features/groups/domain/usecases/calculate_debts.dart'
    as calc;
import 'package:monie/features/groups/domain/usecases/create_group.dart';
import 'package:monie/features/groups/domain/usecases/get_group_by_id.dart'
    as get_group;
import 'package:monie/features/groups/domain/usecases/get_groups.dart';
import 'package:monie/features/groups/domain/usecases/settle_group.dart'
    as settle;
import 'package:monie/features/groups/presentation/bloc/group_bloc.dart';

// Service locator instance
final sl = GetIt.instance;

void setup() {
  // External
  // ... existing external dependencies ...

  // Features
  _setupAuthFeature();
  _setupTransactionsFeature();
  _setupBudgetsFeature();
  _setupSettingsFeature();
  _setupGroupsFeature();
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
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetGroups(repository: sl()));
  sl.registerLazySingleton(() => get_group.GetGroupById(repository: sl()));
  sl.registerLazySingleton(() => CreateGroup(repository: sl()));
  sl.registerLazySingleton(() => AddMember(repository: sl()));
  sl.registerLazySingleton(() => calc.CalculateDebts(repository: sl()));
  sl.registerLazySingleton(() => settle.SettleGroup(repository: sl()));

  // Repository
  sl.registerLazySingleton<GroupRepository>(
    () => GroupRepositoryImpl(dataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<GroupRemoteDataSource>(
    () => GroupRemoteDataSourceImpl(supabase: sl()),
  );
}

void setupDependencies() {
  // ... existing code ...

  _setupGroupsFeature();

  // ... existing code ...
}
