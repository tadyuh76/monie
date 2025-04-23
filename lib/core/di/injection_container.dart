import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:monie/core/network/network_info.dart';
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
import 'package:monie/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:monie/firebase/services/firebase_auth_service.dart';
import 'package:monie/hive/boxes/boxes.dart';

final GetIt sl = GetIt.instance;

// Check if Firebase is available by testing if we can access Firebase Auth
bool get _isFirebaseAvailable {
  try {
    FirebaseAuth.instance;
    return true;
  } catch (e) {
    debugPrint('Firebase is not available: $e');
    return false;
  }
}

Future<void> init() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());

  // Features
  await _initAuthFeature();
  await _initDashboardFeature();
  await _initTransactionsFeature();

  // External
  await _initExternalDependencies();
}

Future<void> _initAuthFeature() async {
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
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignIn(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => GetSignedInUser(sl()));
  sl.registerLazySingleton(() => CheckEmailVerified(sl()));
  sl.registerLazySingleton(() => VerifyEmail(sl()));
  sl.registerLazySingleton(() => UpdateEmail(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  if (_isFirebaseAvailable) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
    );
  } else {}

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(userBox: sl()),
  );
}

Future<void> _initDashboardFeature() async {
  // To be implemented
}

Future<void> _initTransactionsFeature() async {
  // To be implemented
}

Future<void> _initExternalDependencies() async {
  if (_isFirebaseAvailable) {
    // Firebase services
    sl.registerLazySingleton(() => FirebaseAuth.instance);
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
    sl.registerLazySingleton(() => FirebaseAuthService(firebaseAuth: sl()));
  }

  // Hive boxes
  sl.registerLazySingleton(() => HiveBoxes.userBox);
}
