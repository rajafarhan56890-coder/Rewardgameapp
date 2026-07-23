import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/transaction_model.dart';

class WalletRepository {
  final FirebaseFirestore _firestore;

  WalletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _txCollection(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.transactions);

  /// Streams the most recent transactions (both coins and cash points),
  /// newest first. Used on the Home dashboard ("recent earning history")
  /// and the full Wallet history screen.
  Stream<List<TransactionModel>> streamTransactions(String uid, {int limit = 50}) {
    return _txCollection(uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TransactionModel.fromMap(d.data(), d.id)).toList());
  }

  /// Atomically credits coins to a user's balance and writes a matching
  /// transaction record. Wrapped in a Firestore transaction so the balance
  /// update and the history entry either both succeed or both fail —
  /// preventing a "ghost" balance increase with no audit trail.
  Future<Result<void>> creditCoins({
    required String uid,
    required int amount,
    required String title,
    required String description,
  }) async {
    if (amount <= 0) return const Result.failure('Invalid reward amount.');
    try {
      final userRef = _firestore.collection(FirestoreCollections.users).doc(uid);
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(userRef);
        if (!snap.exists) throw Exception('user-not-found');
        final currentCoins = (snap.data()?['coins'] as num?)?.toInt() ?? 0;
        txn.update(userRef, {'coins': currentCoins + amount});
        final txRef = _txCollection(uid).doc();
        txn.set(txRef, TransactionModel(
          id: txRef.id,
          currency: TxCurrency.coins,
          direction: TxDirection.credit,
          amount: amount.toDouble(),
          title: title,
          description: description,
          timestamp: DateTime.now(),
        ).toMap());
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }

  Future<Result<void>> creditCashPoints({
    required String uid,
    required double amount,
    required String title,
    required String description,
  }) async {
    if (amount <= 0) return const Result.failure('Invalid reward amount.');
    try {
      final userRef = _firestore.collection(FirestoreCollections.users).doc(uid);
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(userRef);
        if (!snap.exists) throw Exception('user-not-found');
        final current = (snap.data()?['cashPoints'] as num?)?.toDouble() ?? 0;
        txn.update(userRef, {'cashPoints': current + amount});
        final txRef = _txCollection(uid).doc();
        txn.set(txRef, TransactionModel(
          id: txRef.id,
          currency: TxCurrency.cashPoints,
          direction: TxDirection.credit,
          amount: amount,
          title: title,
          description: description,
          timestamp: DateTime.now(),
        ).toMap());
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }

  /// Deducts cash points (used when a withdrawal request is submitted).
  /// Verifies sufficient balance server-side inside the transaction so a
  /// race condition (two withdrawals submitted at once) can't overdraw
  /// the balance.
  Future<Result<void>> debitCashPoints({
    required String uid,
    required double amount,
    required String title,
    required String description,
  }) async {
    if (amount <= 0) return const Result.failure('Invalid amount.');
    try {
      final userRef = _firestore.collection(FirestoreCollections.users).doc(uid);
      await _firestore.runTransaction((txn) async {
        final snap = await txn.get(userRef);
        if (!snap.exists) throw Exception('user-not-found');
        final current = (snap.data()?['cashPoints'] as num?)?.toDouble() ?? 0;
        if (current < amount) throw Exception('insufficient-balance');
        txn.update(userRef, {'cashPoints': current - amount});
        final txRef = _txCollection(uid).doc();
        txn.set(txRef, TransactionModel(
          id: txRef.id,
          currency: TxCurrency.cashPoints,
          direction: TxDirection.debit,
          amount: amount,
          title: title,
          description: description,
          timestamp: DateTime.now(),
        ).toMap());
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }
}
