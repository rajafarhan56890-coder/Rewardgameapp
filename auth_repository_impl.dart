import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorage;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.networkInfo,
  });

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final UserModel user = await remoteDataSource.login(email: email, password: password);
      await secureStorage.saveSession(uid: user.uid, email: user.email);
      return Right(user);
    } on AccountBannedException catch (e) {
      return Left(AccountBannedFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('login unexpected error', e);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final UserModel user = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
        referralCode: referralCode,
      );
      await secureStorage.saveSession(uid: user.uid, email: user.email);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('register unexpected error', e);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({required String email}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('sendPasswordResetEmail unexpected error', e);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await secureStorage.clearSession();
      return const Right(null);
    } catch (e) {
      AppLogger.e('logout unexpected error', e);
      return const Left(ServerFailure('Failed to log out. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final UserModel user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AccountBannedException catch (e) {
      return Left(AccountBannedFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      AppLogger.e('getCurrentUser unexpected error', e);
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> hasActiveSession() async {
    try {
      final bool marked = await secureStorage.isSessionMarkedActive();
      return Right(marked);
    } catch (e) {
      AppLogger.e('hasActiveSession unexpected error', e);
      return const Right(false);
    }
  }
}
