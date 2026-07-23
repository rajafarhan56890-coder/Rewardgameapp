import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/game_model.dart';
import 'wallet_repository.dart';

/// Mirrors GamesRepository but for the Cash Rewards section. Cash points
/// and coins are tracked as completely separate fields/collections per the
/// product requirement that the two currencies never mix.
class CashTasksRepository {
  final FirebaseFirestore _firestore;
  final WalletRepository _walletRepository;

  CashTasksRepository({FirebaseFirestore? firestore, WalletRepository? walletRepository})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _walletRepository = walletRepository ?? WalletRepository();

  Stream<List<CashTaskModel>> streamCashTasks() {
    return _firestore
        .collection(FirestoreCollections.cashTasks)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CashTaskModel.fromMap(d.data(), d.id)).toList());
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _completionId(String uid, CashTaskModel task) {
    if (task.cooldownType == 'once') return '${uid}_${task.id}';
    return '${uid}_${task.id}_${_dateKey(DateTime.now())}';
  }

  Stream<Set<String>> streamCompletedTaskIds(String uid) {
    final today = _dateKey(DateTime.now());
    return _firestore
        .collection(FirestoreCollections.cashTaskCompletions)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final ids = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final cooldown = data['cooldownType'] as String? ?? 'once';
        if (cooldown == 'once') {
          ids.add(data['taskId'] as String);
        } else if (data['dateKey'] == today) {
          ids.add(data['taskId'] as String);
        }
      }
      return ids;
    });
  }

  Stream<List<Map<String, dynamic>>> streamPendingCompletions(String uid) {
    return _firestore
        .collection(FirestoreCollections.cashTaskCompletions)
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  /// Completes a cash task. Instant-reward tasks credit immediately;
  /// tasks flagged `requiresReview` are recorded as pending for manual
  /// admin approval (useful for offer-wall / survey style tasks that need
  /// verification before payout).
  Future<Result<void>> completeTask({
    required String uid,
    required CashTaskModel task,
    bool requiresReview = false,
  }) async {
    try {
      final completionRef = _firestore
          .collection(FirestoreCollections.cashTaskCompletions)
          .doc(_completionId(uid, task));

      final existing = await completionRef.get();
      if (existing.exists) {
        return const Result.failure('You have already claimed this reward.');
      }

      await completionRef.set({
        'uid': uid,
        'taskId': task.id,
        'taskTitle': task.title,
        'rewardCashPoints': task.rewardCashPoints,
        'cooldownType': task.cooldownType,
        'dateKey': _dateKey(DateTime.now()),
        'status': requiresReview ? 'pending' : 'approved',
        'timestamp': Timestamp.now(),
      });

      if (!requiresReview) {
        final creditResult = await _walletRepository.creditCashPoints(
          uid: uid,
          amount: task.rewardCashPoints,
          title: task.title,
          description: 'Cash points earned for "${task.title}"',
        );
        if (creditResult.isFailure) {
          await completionRef.delete();
          return creditResult;
        }
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }
}
