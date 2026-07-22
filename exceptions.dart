/// Exceptions are thrown at the data-source layer (Firebase calls) and
/// caught by repositories, which translate them into Failure objects.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred.']);
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection.']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local cache error.']);
}

class AccountBannedException implements Exception {
  final String message;
  const AccountBannedException([this.message = 'This account has been suspended.']);
}
