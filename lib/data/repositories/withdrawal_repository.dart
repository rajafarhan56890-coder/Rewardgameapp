import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/withdrawal_model.dart';
import '../models/config_model.dart';
import 'wallet_repository.dart';

class WithdrawalRepository {
  final FirebaseFirestore _firestore;
  final WalletRepository _walletRepository;

  WithdrawalRepository({FirebaseFirestore? firestore, WalletRepository? walletRepository})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _walletRepository = walletRepository ?? WalletRepository();

  Stream<List<WithdrawalModel>> streamWithdrawals(String uid) {
    return _firestore
        .collection(FirestoreCollections.withdrawals)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WithdrawalModel.fromMap(d.data(), d.id)).toList());
  }

  /// Submits a withdrawal request: deducts the cash points immediately
  /// (so the user cannot request the same balance twice) and creates a
  /// withdrawal doc with status "pending" for admin review/payout.
  Future<Result<void>> submitWithdrawal({
    required String uid,
    required String method,
    required String accountName,
    required String accountNumber,
    String? bankName,
    required double cashPoints,
    required AppConfigModel config,
  }) async {
    if (cashPoints <= 0) return const Result.failure('Enter a valid amount.');
    final amountPkr = config.cashPointsToPkr(cashPoints);
    if (amountPkr < config.minWithdrawalPkr) {
      return Result.failure(
          'Minimum withdrawal is Rs. ${config.minWithdrawalPkr.toStringAsFixed(0)}.');
    }

    final debitResult = await _walletRepository.debitCashPoints(
      uid: uid,
      amount: cashPoints,
      title: 'Withdrawal Request',
      description: '$method withdrawal of Rs. ${amountPkr.toStringAsFixed(0)}',
    );
    if (debitResult.isFailure) return debitResult;

    try {
      final withdrawal = WithdrawalModel(
        id: '',
        uid: uid,
        method: method,
        accountName: accountName.trim(),
        accountNumber: accountNumber.trim(),
        bankName: bankName?.trim(),
        cashPointsDeducted: cashPoints,
        amountPkr: amountPkr,
        status: WithdrawalStatus.pending,
        createdAt: DateTime.now(),
      );
      await _firestore.collection(FirestoreCollections.withdrawals).add(withdrawal.toMap());
      return const Result.success(null);
    } catch (e) {
      // Refund the deducted cash points since the withdrawal record failed to save.
      await _walletRepository.creditCashPoints(
        uid: uid,
        amount: cashPoints,
        title: 'Withdrawal Refund',
        description: 'Refund due to failed withdrawal submission',
      );
      return Result.failure(friendlyErrorMessage(e));
    }
  }
}
