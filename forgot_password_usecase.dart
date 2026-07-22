import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;
  const ForgotPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) async {
    final String? emailError = Validators.email(email);
    if (emailError != null) return Left(ValidationFailure(emailError));

    return repository.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }
}
