import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final String? referralCode;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    required this.confirmPassword,
    this.referralCode,
  });

  @override
  List<Object?> get props => [name, email, password, confirmPassword, referralCode];
}

class RegisterUseCase {
  final AuthRepository repository;
  const RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    final String? nameError = Validators.name(params.name);
    if (nameError != null) return Left(ValidationFailure(nameError));

    final String? emailError = Validators.email(params.email);
    if (emailError != null) return Left(ValidationFailure(emailError));

    final String? passwordError = Validators.password(params.password);
    if (passwordError != null) return Left(ValidationFailure(passwordError));

    final String? confirmError =
        Validators.confirmPassword(params.confirmPassword, params.password);
    if (confirmError != null) return Left(ValidationFailure(confirmError));

    final String? trimmedReferral = params.referralCode?.trim();

    return repository.register(
      name: params.name.trim(),
      email: params.email.trim().toLowerCase(),
      password: params.password,
      referralCode: (trimmedReferral == null || trimmedReferral.isEmpty)
          ? null
          : trimmedReferral.toUpperCase(),
    );
  }
}
