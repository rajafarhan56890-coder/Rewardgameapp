import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/referral_repository.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralRepository _repository;

  ReferralProvider({ReferralRepository? repository})
      : _repository = repository ?? ReferralRepository();

  List<ReferralModel> referrals = [];
  bool isLoading = true;

  StreamSubscription<List<ReferralModel>>? _sub;
  String? _boundUid;

  void bind(String uid) {
    if (_boundUid == uid) return;
    _boundUid = uid;
    _sub?.cancel();
    _sub = _repository.streamReferrals(uid).listen((list) {
      referrals = list;
      isLoading = false;
      notifyListeners();
    });
  }

  int get rewardedCount => referrals.where((r) => r.status == 'rewarded').length;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
