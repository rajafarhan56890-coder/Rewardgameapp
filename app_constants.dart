class AppConstants {
  AppConstants._();

  static const String appName = 'PinJoy Rewards';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 40;

  // Session
  static const Duration sessionCheckInterval = Duration(minutes: 5);

  // Default fallback config values (used only if remote config document
  // fails to load — real values always come from Firestore app_config).
  static const double defaultCashToPkrRate = 0.25; // 200 pts = Rs.50
  static const int defaultDailyCheckInBaseReward = 5;
  static const int defaultReferralReward = 50;
  static const double defaultMinWithdrawalPkr = 100;

  // Pagination
  static const int defaultPageSize = 20;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMedium = Duration(milliseconds: 400);
  static const Duration animSlow = Duration(milliseconds: 700);
}

enum WithdrawalMethod { jazzcash, easypaisa, bank }

enum WithdrawalStatus { pending, approved, rejected }

enum TaskStatus { available, inProgress, completed, claimed }

enum TransactionType { coinEarn, cashEarn, checkIn, referral, withdrawal, adminAdjustment }
