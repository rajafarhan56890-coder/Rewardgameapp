import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/withdrawal_model.dart';
import '../../data/models/config_model.dart';
import '../../data/repositories/withdrawal_repository.dart';

class WithdrawalProvider extends ChangeNotifier {
  final WithdrawalRepository _repository;

  WithdrawalProvider({WithdrawalRepository? repository})
      : _repository = repository ?? WithdrawalRepository();

  List<WithdrawalModel> withdrawals = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  StreamSubscription<List<WithdrawalModel>>? _sub;
  String? _boundUid;

  void bind(String uid) {
    if (_boundUid == uid) return;
    _boundUid = uid;
    isLoading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _repository.streamWithdrawals(uid).listen((list) {
      withdrawals = list;
      isLoading = false;
      notifyListeners();
    });
  }

  List<WithdrawalModel> get pending =>
      withdrawals.where((w) => w.status == WithdrawalStatus.pending).toList();
  List<WithdrawalModel> get approved =>
      withdrawals.where((w) => w.status == WithdrawalStatus.approved).toList();
  List<WithdrawalModel> get rejected =>
      withdrawals.where((w) => w.status == WithdrawalStatus.rejected).toList();

  Future<bool> submit({
    required String uid,
    required String method,
    required String accountName,
    required String accountNumber,
    String? bankName,
    required double cashPoints,
    required AppConfigModel config,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.submitWithdrawal(
      uid: uid,
      method: method,
      accountName: accountName,
      accountNumber: accountNumber,
      bankName: bankName,
      cashPoints: cashPoints,
      config: config,
    );

    isSubmitting = false;
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
    _sub?.cancel();
    super.dispose();
  }
}
