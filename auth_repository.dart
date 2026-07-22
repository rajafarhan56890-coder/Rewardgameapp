import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract implemented by the data layer. The domain/presentation
/// layers depend only on this abstraction, never on FirebaseAuth
/// directly, so the backend could be swapped without touching UI code.
abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  });

  Future<Either<Failure, void>> sendPasswordResetEmail({required String email});

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, bool>> hasActiveSession();
}
