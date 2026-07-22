import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;
  const LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() => repository.logout();
}

class GetCurrentUserUseCase {
  final AuthRepository repository;
  const GetCurrentUserUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call() => repository.getCurrentUser();
}

/// Used at app startup to decide whether to route to the Home screen
/// (auto-login) or the Login screen.
class CheckActiveSessionUseCase {
  final AuthRepository repository;
  const CheckActiveSessionUseCase(this.repository);

  Future<Either<Failure, bool>> call() => repository.hasActiveSession();
}
