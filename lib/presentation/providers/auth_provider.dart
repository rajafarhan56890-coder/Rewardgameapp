import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/notification_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final NotificationRepository _notificationRepository;

  AuthProvider({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    NotificationRepository? notificationRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository() {
    _init();
  }

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  bool isBusy = false;
  String? errorMessage;

  StreamSubscription<fb.User?>? _authSub;
  StreamSubscription<UserModel?>? _userSub;

  void _init() {
    _authSub = _authRepository.authStateChanges.listen((fbUser) async {
      if (fbUser == null) {
        status = AuthStatus.unauthenticated;
        currentUser = null;
        await _userSub?.cancel();
        notifyListeners();
        return;
      }
      status = AuthStatus.authenticated;
      _listenToUserProfile(fbUser.uid);
      _registerPushToken(fbUser.uid);
    });
  }

  void _listenToUserProfile(String uid) {
    _userSub?.cancel();
    _userSub = _userRepository.streamUser(uid).listen((user) {
      currentUser = user;
      notifyListeners();
    });
  }

  Future<void> _registerPushToken(String uid) async {
    final token = await _notificationRepository.initPushNotifications();
    if (token != null) {
      await _userRepository.updateFcmToken(uid, token);
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authRepository.register(
      username: username,
      email: email,
      password: password,
      referralCode: referralCode,
    );

    isBusy = false;
    result.when(
      success: (_) => errorMessage = null,
      failure: (msg) => errorMessage = msg,
    );
    notifyListeners();
    return result.isSuccess;
  }

  Future<bool> login({required String email, required String password}) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authRepository.login(email: email, password: password);

    isBusy = false;
    result.when(
      success: (_) => errorMessage = null,
      failure: (msg) => errorMessage = msg,
    );
    notifyListeners();
    return result.isSuccess;
  }

  Future<bool> sendPasswordReset(String email) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authRepository.sendPasswordResetEmail(email);

    isBusy = false;
    result.when(
      success: (_) => errorMessage = null,
      failure: (msg) => errorMessage = msg,
    );
    notifyListeners();
    return result.isSuccess;
  }

  Future<void> logout() async {
    await _authRepository.logout();
  }

  Future<bool> deleteAccount() async {
    isBusy = true;
    notifyListeners();
    final result = await _authRepository.deleteAccount();
    isBusy = false;
    if (result.isFailure) errorMessage = result.errorOrNull;
    notifyListeners();
    return result.isSuccess;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
