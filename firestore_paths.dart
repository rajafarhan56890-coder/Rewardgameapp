/// Centralized Firestore collection & document field names.
/// Keeping these in one place prevents typo-based bugs across the app
/// and keeps the schema self-documenting.
class FirestorePaths {
  FirestorePaths._();

  // Collections
  static const String users = 'users';
  static const String games = 'games';
  static const String cashTasks = 'cash_tasks';
  static const String transactions = 'transactions';
  static const String withdrawals = 'withdrawals';
  static const String referrals = 'referrals';
  static const String notifications = 'notifications';
  static const String appConfig = 'app_config';
  static const String checkIns = 'check_ins';
  static const String taskCompletions = 'task_completions';

  // app_config singleton document
  static const String configDoc = 'global';

  // Sub-collections (under users/{uid}/...)
  static const String userNotifications = 'user_notifications';
}

/// User document field names.
class UserFields {
  UserFields._();

  static const String uid = 'uid';
  static const String name = 'name';
  static const String email = 'email';
  static const String photoUrl = 'photoUrl';
  static const String coins = 'coins';
  static const String cashPoints = 'cashPoints';
  static const String referralCode = 'referralCode';
  static const String referredBy = 'referredBy';
  static const String isBanned = 'isBanned';
  static const String createdAt = 'createdAt';
  static const String lastCheckIn = 'lastCheckIn';
  static const String checkInStreak = 'checkInStreak';
  static const String fcmToken = 'fcmToken';
  static const String isAdmin = 'isAdmin';
}
