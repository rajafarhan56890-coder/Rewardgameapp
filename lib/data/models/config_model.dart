import 'package:cloud_firestore/cloud_firestore.dart';

/// Remote-configurable values loaded from Firestore config/app_config.
/// This lets the conversion rate / minimum withdrawal / referral bonus be
/// changed live without shipping a new app build.
class AppConfigModel {
  final double cashPointsPerUnit; // e.g. 200
  final double cashUnitValuePkr; // e.g. 50 (=200 cash points -> 50 PKR)
  final double minWithdrawalPkr;
  final int dailyBaseCoins;
  final int referralBonusCoins;
  final bool maintenanceMode;

  const AppConfigModel({
    required this.cashPointsPerUnit,
    required this.cashUnitValuePkr,
    required this.minWithdrawalPkr,
    required this.dailyBaseCoins,
    required this.referralBonusCoins,
    required this.maintenanceMode,
  });

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      cashPointsPerUnit: (map['cashPointsPerUnit'] as num?)?.toDouble() ?? 200,
      cashUnitValuePkr: (map['cashUnitValuePkr'] as num?)?.toDouble() ?? 50,
      minWithdrawalPkr: (map['minWithdrawalPkr'] as num?)?.toDouble() ?? 100,
      dailyBaseCoins: (map['dailyBaseCoins'] as num?)?.toInt() ?? 10,
      referralBonusCoins: (map['referralBonusCoins'] as num?)?.toInt() ?? 100,
      maintenanceMode: (map['maintenanceMode'] as bool?) ?? false,
    );
  }

  /// Converts a cash-points balance into its PKR equivalent using the
  /// live conversion rate, e.g. 200 cashPoints = 50 PKR.
  double cashPointsToPkr(double cashPoints) {
    if (cashPointsPerUnit <= 0) return 0;
    return (cashPoints / cashPointsPerUnit) * cashUnitValuePkr;
  }

  double pkrToCashPoints(double pkr) {
    if (cashUnitValuePkr <= 0) return 0;
    return (pkr / cashUnitValuePkr) * cashPointsPerUnit;
  }

  static AppConfigModel fallback() => const AppConfigModel(
        cashPointsPerUnit: 200,
        cashUnitValuePkr: 50,
        minWithdrawalPkr: 100,
        dailyBaseCoins: 10,
        referralBonusCoins: 100,
        maintenanceMode: false,
      );
}

class DailyRewardModel {
  final DateTime? lastClaimDate;
  final int streak;

  const DailyRewardModel({this.lastClaimDate, this.streak = 0});

  factory DailyRewardModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DailyRewardModel();
    return DailyRewardModel(
      lastClaimDate: (map['lastClaimDate'] as Timestamp?)?.toDate(),
      streak: (map['streak'] as num?)?.toInt() ?? 0,
    );
  }

  bool get claimedToday {
    if (lastClaimDate == null) return false;
    final now = DateTime.now();
    return lastClaimDate!.year == now.year &&
        lastClaimDate!.month == now.month &&
        lastClaimDate!.day == now.day;
  }

  int get currentDayInCycle => (streak % 7) + 1;
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // reward, system, withdrawal, referral
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'system',
      isRead: (map['isRead'] as bool?) ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
