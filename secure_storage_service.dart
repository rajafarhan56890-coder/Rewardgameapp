import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage (Android Keystore / iOS Keychain backed)
/// so that anything sensitive (auth session flags, cached uid) never
/// touches plain SharedPreferences.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const String _keyUid = 'session_uid';
  static const String _keyIsLoggedIn = 'session_is_logged_in';
  static const String _keyLastLoginEmail = 'session_last_email';

  Future<void> saveSession({required String uid, required String email}) async {
    await _storage.write(key: _keyUid, value: uid);
    await _storage.write(key: _keyIsLoggedIn, value: 'true');
    await _storage.write(key: _keyLastLoginEmail, value: email);
  }

  Future<String?> getSavedUid() => _storage.read(key: _keyUid);

  Future<bool> isSessionMarkedActive() async {
    final String? value = await _storage.read(key: _keyIsLoggedIn);
    return value == 'true';
  }

  Future<String?> getLastLoginEmail() => _storage.read(key: _keyLastLoginEmail);

  Future<void> clearSession() async {
    await _storage.delete(key: _keyUid);
    await _storage.delete(key: _keyIsLoggedIn);
    // Intentionally keep _keyLastLoginEmail so the login form can
    // pre-fill the email field for convenience after logout.
  }
}
