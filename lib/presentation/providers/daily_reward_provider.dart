import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/config_model.dart';
import '../../data/repositories/daily_reward_repository.dart';

class DailyRewardProvider extends ChangeNotifier {
  final DailyRewardRepository _repository;

  DailyRewardProvider({DailyRewardRepository? repository})
      : _repository = repository ?? DailyRewardRepository();

  DailyRewardModel reward = const DailyRewardModel();
  bool isClaiming = false;
  String? errorMessage;
  int? lastClaimedAmount;

  StreamSubscription<DailyRewardModel>? _sub;
  String? _boundUid;

  void bind(String uid) {
    if (_boundUid == uid) return;
    _boundUid = uid;
    _sub?.cancel();
    _sub = _repository.streamDailyReward(uid).listen((r) {
      reward = r;
      notifyListeners();
    });
  }

  Future<bool> claim(String uid) async {
    if (reward.claimedToday || isClaiming) return false;
    isClaiming = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.claimDailyReward(uid);

    isClaiming = false;
    result.when(
      success: (amount) => lastClaimedAmount = amount,
      failure: (msg) => errorMessage = msg,
    );
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
