import 'package:cloud_firestore/cloud_firestore.dart';

enum TxCurrency { coins, cashPoints }

enum TxDirection { credit, debit }

class TransactionModel {
  final String id;
  final TxCurrency currency;
  final TxDirection direction;
  final double amount;
  final String title;
  final String description;
  final DateTime timestamp;

  const TransactionModel({
    required this.id,
    required this.currency,
    required this.direction,
    required this.amount,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      currency: (map['currency'] as String?) == 'cashPoints'
          ? TxCurrency.cashPoints
          : TxCurrency.coins,
      direction:
          (map['direction'] as String?) == 'debit' ? TxDirection.debit : TxDirection.credit,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currency': currency == TxCurrency.cashPoints ? 'cashPoints' : 'coins',
      'direction': direction == TxDirection.debit ? 'debit' : 'credit',
      'amount': amount,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
