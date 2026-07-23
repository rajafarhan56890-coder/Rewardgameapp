import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/config_model.dart';
import 'wallet_repository.dart';

class DailyRewardRepository {
  final FirebaseFirestore _firestore;
  final WalletRepository _walletRepository;

  DailyRewardRepository({FirebaseFirestore? firestore, WalletRepository? walletRepository})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _walletRepository = walletRepository ?? WalletRepository();

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(FirestoreCollections.dailyRewards).doc(uid);

  Stream<DailyRewardModel> streamDailyReward(String uid) {
    return _doc(uid).snapshots().map((d) => DailyRewardModel.fromMap(d.data()));
  }

  bool _isYesterday(DateTime last, DateTime now) {
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return last.year == yesterday.year && last.month == yesterday.month && last.day == yesterday.day;
  }

  /// Claims today's check-in reward. Uses a Firestore transaction to read
  /// the last-claim date and atomically write the new one, which is what
  /// actually prevents a double-claim (e.g. two rapid taps) — the second
  /// transaction re-reads the just-updated date and aborts.
  Future<Result<int>> claimDailyReward(String uid) async {
    try {
      final config = await _firestore
          .collection(FirestoreCollections.config)
          .doc(FirestoreCollections.appConfigDoc)
          .get();
      final appConfig =
          config.exists ? AppConfigModel.fromMap(config.data()!) : AppConfigModel.fallback();

      late int rewardAmount;
      late int newStreak;

      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(_doc(uid));
        final now = DateTime.now();
        final data = snap.data();
        final lastClaim = (data?['lastClaimDate'] as Timestamp?)?.toDate();
        final currentStreak = (data?['streak'] as num?)?.toInt() ?? 0;

        if (lastClaim != null &&
            lastClaim.year == now.year &&
            lastClaim.month == now.month &&
            lastClaim.day == now.day) {
          throw Exception('already-claimed');
        }

        newStreak = (lastClaim != null && _isYesterday(lastClaim, now))
            ? currentStreak + 1
            : 1; // streak resets if a day was missed
        final dayInCycle = ((newStreak - 1) % 7) + 1;
        rewardAmount = appConfig.dailyBaseCoins * dayInCycle;

        txn.set(_doc(uid), {
          'lastClaimDate': Timestamp.fromDate(now),
          'streak': newStreak,
        }, SetOptions(merge: true));
      });

      final creditResult = await _walletRepository.creditCoins(
        uid: uid,
        amount: rewardAmount,
        title: 'Daily Check-in',
        description: 'Day $newStreak streak reward',
      );
      if (creditResult.isFailure) return Result.failure(creditResult.errorOrNull!);

      return Result.success(rewardAmount);
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }
}
