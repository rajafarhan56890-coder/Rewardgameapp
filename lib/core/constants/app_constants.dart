/// Centralized constants for Firestore collection/document paths and
/// static configuration keys. Keeping these in one place avoids typo bugs
/// when referencing collections across repositories.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String transactions = 'transactions'; // sub-collection under users/{uid}/transactions
  static const String games = 'games';
  static const String gameCompletions = 'game_completions';
  static const String cashTasks = 'cash_tasks';
  static const String cashTaskCompletions = 'cash_task_completions';
  static const String withdrawals = 'withdrawals';
  static const String referrals = 'referrals';
  static const String dailyRewards = 'daily_rewards'; // doc per user
  static const String notifications = 'notifications'; // sub-collection under users/{uid}/notifications
  static const String config = 'config';
  static const String appConfigDoc = 'app_config';
}

class AppConstants {
  AppConstants._();

  static const String appName = 'CoinVault Rewards';

  // Fallback values used only if remote config document is unreachable.
  // The real values always come from Firestore: config/app_config
  static const double fallbackCashPointsPerUnit = 200; // 200 cash points
  static const double fallbackCashUnitValuePkr = 50; // = 50 PKR
  static const double fallbackMinWithdrawalPkr = 100;
  static const int fallbackDailyBaseCoins = 10;
  static const int fallbackReferralBonusCoins = 100;

  static const List<String> withdrawalMethods = [
    'JazzCash',
    'Easypaisa',
    'Bank Transfer',
  ];

  static const Duration splashDelay = Duration(milliseconds: 1400);
}

enum CurrencyType { coins, cashPoints }

enum TransactionDirection { credit, debit }

enum WithdrawalStatus { pending, approved, rejected }

extension WithdrawalStatusX on WithdrawalStatus {
  String get label {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }

  static WithdrawalStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return WithdrawalStatus.approved;
      case 'rejected':
        return WithdrawalStatus.rejected;
      default:
        return WithdrawalStatus.pending;
    }
  }

  String get raw {
    switch (this) {
      case WithdrawalStatus.pending:
        return 'pending';
      case WithdrawalStatus.approved:
        return 'approved';
      case WithdrawalStatus.rejected:
        return 'rejected';
    }
  }
}
