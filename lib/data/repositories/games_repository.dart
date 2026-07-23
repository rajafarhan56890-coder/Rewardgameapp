import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/game_model.dart';
import 'wallet_repository.dart';

class GamesRepository {
  final FirebaseFirestore _firestore;
  final WalletRepository _walletRepository;

  GamesRepository({FirebaseFirestore? firestore, WalletRepository? walletRepository})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _walletRepository = walletRepository ?? WalletRepository();

  Stream<List<GameModel>> streamGames() {
    return _firestore
        .collection(FirestoreCollections.games)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => GameModel.fromMap(d.data(), d.id)).toList());
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Deterministic completion-doc ID: for 'daily' cooldown games this is
  /// `{uid}_{gameId}_{yyyy-MM-dd}`, for 'once' games it's `{uid}_{gameId}`.
  /// Because Firestore rejects creating a document that already exists
  /// (enforced both client-side via `.set(..., merge:false)` semantics and
  /// server-side via Firestore rules `allow create: if !exists(...)`),
  /// this is what actually prevents duplicate reward claims — not just a
  /// client-side check that a malicious user could bypass.
  String _completionId(String uid, GameModel game) {
    if (game.cooldownType == 'once') return '${uid}_${game.id}';
    return '${uid}_${game.id}_${_dateKey(DateTime.now())}';
  }

  Stream<Set<String>> streamCompletedGameIdsToday(String uid) {
    final today = _dateKey(DateTime.now());
    return _firestore
        .collection(FirestoreCollections.gameCompletions)
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final ids = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final cooldown = data['cooldownType'] as String? ?? 'daily';
        if (cooldown == 'once') {
          ids.add(data['gameId'] as String);
        } else if (data['dateKey'] == today) {
          ids.add(data['gameId'] as String);
        }
      }
      return ids;
    });
  }

  /// Records the completion + credits coins. Uses the deterministic
  /// document ID with a create-only write so a duplicate call (double tap,
  /// replayed request) fails instead of granting a second reward.
  Future<Result<void>> completeGame({required String uid, required GameModel game}) async {
    try {
      final completionRef = _firestore
          .collection(FirestoreCollections.gameCompletions)
          .doc(_completionId(uid, game));

      final existing = await completionRef.get();
      if (existing.exists) {
        return const Result.failure('You have already claimed this reward.');
      }

      await completionRef.set({
        'uid': uid,
        'gameId': game.id,
        'gameTitle': game.title,
        'rewardCoins': game.rewardCoins,
        'cooldownType': game.cooldownType,
        'dateKey': _dateKey(DateTime.now()),
        'timestamp': Timestamp.now(),
      });

      final creditResult = await _walletRepository.creditCoins(
        uid: uid,
        amount: game.rewardCoins,
        title: game.title,
        description: 'Reward for completing "${game.title}"',
      );

      if (creditResult.isFailure) {
        // Roll back the completion record so the user can retry.
        await completionRef.delete();
        return creditResult;
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }
}
