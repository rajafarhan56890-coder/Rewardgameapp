import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class WithdrawalModel {
  final String id;
  final String uid;
  final String method; // JazzCash / Easypaisa / Bank Transfer
  final String accountName;
  final String accountNumber;
  final String? bankName;
  final double cashPointsDeducted;
  final double amountPkr;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final String? adminNote;

  const WithdrawalModel({
    required this.id,
    required this.uid,
    required this.method,
    required this.accountName,
    required this.accountNumber,
    required this.cashPointsDeducted,
    required this.amountPkr,
    required this.status,
    required this.createdAt,
    this.bankName,
    this.adminNote,
  });

  factory WithdrawalModel.fromMap(Map<String, dynamic> map, String id) {
    return WithdrawalModel(
      id: id,
      uid: (map['uid'] as String?) ?? '',
      method: (map['method'] as String?) ?? '',
      accountName: (map['accountName'] as String?) ?? '',
      accountNumber: (map['accountNumber'] as String?) ?? '',
      bankName: map['bankName'] as String?,
      cashPointsDeducted: (map['cashPointsDeducted'] as num?)?.toDouble() ?? 0,
      amountPkr: (map['amountPkr'] as num?)?.toDouble() ?? 0,
      status: WithdrawalStatusX.fromString((map['status'] as String?) ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminNote: map['adminNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'method': method,
      'accountName': accountName,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'cashPointsDeducted': cashPointsDeducted,
      'amountPkr': amountPkr,
      'status': status.raw,
      'createdAt': Timestamp.fromDate(createdAt),
      'adminNote': adminNote,
    };
  }
}
