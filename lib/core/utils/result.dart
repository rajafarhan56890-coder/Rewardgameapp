/// A lightweight Result type used across repositories so the UI layer
/// never has to deal with raw exceptions. Every repository method returns
/// a `Result<T>` instead of throwing, which keeps error handling explicit
/// and prevents unhandled-exception crashes in the presentation layer.
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(String message) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  String? get errorOrNull => this is Failure<T> ? (this as Failure<T>).message : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Failure<T>) return failure(self.message);
    throw StateError('Unreachable');
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}

/// Converts common Firebase/Firestore exceptions into user-friendly text.
String friendlyErrorMessage(Object error) {
  final raw = error.toString();
  if (raw.contains('network-request-failed') || raw.contains('SocketException')) {
    return 'No internet connection. Please check your network and try again.';
  }
  if (raw.contains('user-not-found')) return 'No account found with this email.';
  if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
    return 'Incorrect email or password.';
  }
  if (raw.contains('email-already-in-use')) return 'This email is already registered.';
  if (raw.contains('weak-password')) return 'Password is too weak.';
  if (raw.contains('invalid-email')) return 'Please enter a valid email address.';
  if (raw.contains('too-many-requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (raw.contains('permission-denied')) {
    return 'You do not have permission to perform this action.';
  }
  if (raw.contains('already-claimed') || raw.contains('already claimed')) {
    return 'You have already claimed this reward.';
  }
  if (raw.contains('insufficient-balance')) return 'Insufficient balance for this action.';
  return 'Something went wrong. Please try again.';
}
