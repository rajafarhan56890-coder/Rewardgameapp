import 'package:equatable/equatable.dart';

/// Failures are returned from the domain/data layer to the presentation
/// layer via Either<Failure, T> (dartz). They carry a user-safe message.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Please try again.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You do not have permission to do this.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'The requested item was not found.']);
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure([super.message = 'Insufficient balance.']);
}

class AccountBannedFailure extends Failure {
  const AccountBannedFailure([super.message = 'This account has been suspended.']);
}
