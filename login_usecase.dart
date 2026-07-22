import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Encapsulates the "user logs in" business rule: validate inputs first
/// (fail fast, no network call wasted on garbage input), then delegate
/// to the repository.
class LoginUseCase {
  final AuthRepository repository;
  const LoginUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    final String? emailError = Validators.email(params.email);
    if (emailError != null) return Left(ValidationFailure(emailError));

    if (params.password.isEmpty) {
      return const Left(ValidationFailure('Password is required'));
    }

    return repository.login(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );
  }
}
