import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:monie/core/network/network_info.dart';
import 'package:monie/core/supabase/supabase_auth_service.dart';
import 'package:monie/core/theme/cubit/theme_cubit.dart';
import 'package:monie/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:monie/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:monie/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:monie/features/authentication/domain/repositories/auth_repository.dart';
import 'package:monie/features/authentication/domain/usecases/check_email_verified.dart';
import 'package:monie/features/authentication/domain/usecases/get_signed_in_user.dart';
import 'package:monie/features/authentication/domain/usecases/sign_in.dart';
import 'package:monie/features/authentication/domain/usecases/sign_out.dart';
import 'package:monie/features/authentication/domain/usecases/sign_up.dart';
import 'package:monie/features/authentication/domain/usecases/update_email.dart';
import 'package:monie/features/authentication/domain/usecases/verify_email.dart';
import 'package:monie/features/authentication/domain/usecases/reset_password.dart';
import 'package:monie/features/authentication/domain/usecases/confirm_password_reset.dart';
import 'package:monie/features/authentication/domain/usecases/check_recovery_token.dart';
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/hive/adapters/user_adapter.dart';
import 'package:monie/hive/boxes/boxes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> init() async {
  debugPrint('Initializing dependency injection...');

  try {
    // Register Hive adapters first
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserAdapter());
    }

    // External - Register these first since other components depend on them
    await _registerExternalDependencies();

    // Core
    _registerCoreDependencies();

    // Features
    await _initAuthFeature();
    await _initDashboardFeature();
    await _initTransactionsFeature();

    debugPrint('Dependency injection initialized successfully!');
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize dependency injection: $e');
    debugPrint('Stack trace: $stackTrace');

    // Try to register minimal requirements for the app to at least show an error screen
    _registerFallbackDependencies();
  }
}

Future<void> _registerExternalDependencies() async {
  debugPrint('Registering external dependencies...');

  // Only register Hive boxes if not already registered
  if (!sl.isRegistered<Box<dynamic>>(instanceName: 'userBox')) {
    sl.registerLazySingleton<Box<dynamic>>(
      () => HiveBoxes.userBox,
      instanceName: 'userBox',
    );
  }

  if (!sl.isRegistered<Box<dynamic>>(instanceName: 'settingsBox')) {
    sl.registerLazySingleton<Box<dynamic>>(
      () => HiveBoxes.settingsBox,
      instanceName: 'settingsBox',
    );
  }

  // Supabase services
  sl.registerLazySingleton(() => SupabaseAuthService());
}

void _registerCoreDependencies() {
  if (!sl.isRegistered<NetworkInfo>()) {
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  }

  if (!sl.isRegistered<InternetConnectionChecker>()) {
    sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());
  }

  if (!sl.isRegistered<ThemeCubit>()) {
    sl.registerLazySingleton(
      () => ThemeCubit(sl<Box<dynamic>>(instanceName: 'settingsBox')),
    );
  }
}

Future<void> _initAuthFeature() async {
  debugPrint('Initializing auth feature...');

  // Use Cases - Register these first to simplify debugging if they fail
  _registerAuthUseCases();

  // Data Sources
  _registerAuthDataSources();

  // Repository
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    );
  }

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      signIn: sl(),
      signUp: sl(),
      signOut: sl(),
      getSignedInUser: sl(),
      checkEmailVerified: sl(),
      verifyEmail: sl(),
      updateEmail: sl(),
      resetPassword: sl(),
      confirmPasswordReset: sl(),
      checkRecoveryToken: sl(),
    ),
  );

  debugPrint('Auth feature initialized successfully!');
}

void _registerAuthUseCases() {
  debugPrint('Registering auth use cases...');

  if (!sl.isRegistered<SignIn>()) sl.registerLazySingleton(() => SignIn(sl()));
  if (!sl.isRegistered<SignUp>()) sl.registerLazySingleton(() => SignUp(sl()));
  if (!sl.isRegistered<SignOut>()) {
    sl.registerLazySingleton(() => SignOut(sl()));
  }
  if (!sl.isRegistered<GetSignedInUser>()) {
    sl.registerLazySingleton(() => GetSignedInUser(sl()));
  }
  if (!sl.isRegistered<CheckEmailVerified>()) {
    sl.registerLazySingleton(() => CheckEmailVerified(sl()));
  }
  if (!sl.isRegistered<VerifyEmail>()) {
    sl.registerLazySingleton(() => VerifyEmail(sl()));
  }
  if (!sl.isRegistered<UpdateEmail>()) {
    sl.registerLazySingleton(() => UpdateEmail(sl()));
  }
  if (!sl.isRegistered<ResetPassword>()) {
    sl.registerLazySingleton(() => ResetPassword(sl()));
  }
  if (!sl.isRegistered<ConfirmPasswordReset>()) {
    sl.registerLazySingleton(() => ConfirmPasswordReset(sl()));
  }
  if (!sl.isRegistered<CheckRecoveryToken>()) {
    sl.registerLazySingleton(() => CheckRecoveryToken(sl()));
  }
}

void _registerAuthDataSources() {
  debugPrint('Registering auth data sources...');

  // Always register local data source using the Box<dynamic>
  if (!sl.isRegistered<AuthLocalDataSource>()) {
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        userBox: sl<Box<dynamic>>(instanceName: 'userBox'),
      ),
    );
  }

  // Register remote data source using Supabase
  if (!sl.isRegistered<AuthRemoteDataSource>()) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        authService: sl(),
        supabaseClient: Supabase.instance.client,
      ),
    );
    debugPrint('Registered Supabase remote data source');
  }
}

Future<void> _initDashboardFeature() async {
  debugPrint('Dashboard feature initialization skipped - to be implemented');
  // To be implemented
}

Future<void> _initTransactionsFeature() async {
  debugPrint('Transactions feature initialization skipped - to be implemented');
  // To be implemented
}

void _registerFallbackDependencies() {
  debugPrint('Registering fallback dependencies...');
  try {
    // Hive boxes if not registered
    if (!sl.isRegistered<Box<dynamic>>(instanceName: 'userBox')) {
      sl.registerLazySingleton<Box<dynamic>>(
        () => HiveBoxes.userBox,
        instanceName: 'userBox',
      );
    }

    if (!sl.isRegistered<Box<dynamic>>(instanceName: 'settingsBox')) {
      sl.registerLazySingleton<Box<dynamic>>(
        () => HiveBoxes.settingsBox,
        instanceName: 'settingsBox',
      );
    }

    // NetworkInfo if not registered
    if (!sl.isRegistered<NetworkInfo>()) {
      sl.registerLazySingleton<NetworkInfo>(
        () => NetworkInfoImpl(InternetConnectionChecker.createInstance()),
      );
    }

    // Theme cubit if not registered
    if (!sl.isRegistered<ThemeCubit>()) {
      sl.registerLazySingleton(
        () => ThemeCubit(sl<Box<dynamic>>(instanceName: 'settingsBox')),
      );
    }

    debugPrint('Fallback dependencies registered');
  } catch (e) {
    debugPrint('Failed to register fallback dependencies: $e');
  }
}
