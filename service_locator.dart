import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../core/network/network_info.dart';
import '../core/services/secure_storage_service.dart';

import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/register_usecase.dart';
import '../features/auth/domain/usecases/session_usecases.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

import '../features/home/data/datasources/home_remote_datasource.dart';
import '../features/home/data/repositories/home_repository_impl.dart';
import '../features/home/domain/repositories/home_repository.dart';
import '../features/home/domain/usecases/home_usecases.dart';
import '../features/home/presentation/bloc/home_bloc.dart';

import '../shared/data/remote_config_service.dart';

final GetIt sl = GetIt.instance;

/// Registers every dependency exactly once at app startup. Call
/// `await initDependencies()` before runApp(). Using get_it (service
/// locator) keeps constructors simple while still following clean
/// architecture's dependency-inversion principle — every layer only
/// ever depends on abstractions passed in here.
Future<void> initDependencies() async {
  // ---- External packages ----
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // ---- Core ----
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  // ---- Auth feature ----
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      secureStorage: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));
  sl.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(sl()));
  sl.registerLazySingleton<ForgotPasswordUseCase>(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl()));
  sl.registerLazySingleton<CheckActiveSessionUseCase>(
    () => CheckActiveSessionUseCase(sl()),
  );

  // AuthBloc is registered as a factory: BlocProvider will create one
  // instance for the app's lifetime via the widget tree, but factory
  // registration avoids accidental cross-test/state leakage.
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      forgotPasswordUseCase: sl(),
      logoutUseCase: sl(),
      checkActiveSessionUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ---- Shared services ----
  sl.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService(sl()));

  // ---- Home feature ----
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(firestore: sl(), remoteConfigService: sl()),
  );

  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  sl.registerLazySingleton<PerformDailyCheckInUseCase>(
    () => PerformDailyCheckInUseCase(sl()),
  );
  sl.registerLazySingleton<WatchLatestTasksUseCase>(
    () => WatchLatestTasksUseCase(sl()),
  );
  sl.registerLazySingleton<WatchUnreadNotificationCountUseCase>(
    () => WatchUnreadNotificationCountUseCase(sl()),
  );

  sl.registerFactory<HomeBloc>(
    () => HomeBloc(
      performDailyCheckInUseCase: sl(),
      watchLatestTasksUseCase: sl(),
      watchUnreadNotificationCountUseCase: sl(),
    ),
  );
}
