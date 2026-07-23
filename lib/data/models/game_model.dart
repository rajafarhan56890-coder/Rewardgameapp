class GameModel {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final int rewardCoins;
  final bool isActive;
  final String cooldownType; // 'once', 'daily'

  const GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.rewardCoins,
    required this.isActive,
    required this.cooldownType,
  });

  factory GameModel.fromMap(Map<String, dynamic> map, String id) {
    return GameModel(
      id: id,
      title: (map['title'] as String?) ?? 'Game',
      description: (map['description'] as String?) ?? '',
      iconUrl: (map['iconUrl'] as String?) ?? '',
      rewardCoins: (map['rewardCoins'] as num?)?.toInt() ?? 0,
      isActive: (map['isActive'] as bool?) ?? true,
      cooldownType: (map['cooldownType'] as String?) ?? 'daily',
    );
  }
}

class CashTaskModel {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final double rewardCashPoints;
  final bool isActive;
  final String cooldownType; // 'once', 'daily'

  const CashTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.rewardCashPoints,
    required this.isActive,
    required this.cooldownType,
  });

  factory CashTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return CashTaskModel(
      id: id,
      title: (map['title'] as String?) ?? 'Task',
      description: (map['description'] as String?) ?? '',
      iconUrl: (map['iconUrl'] as String?) ?? '',
      rewardCashPoints: (map['rewardCashPoints'] as num?)?.toDouble() ?? 0,
      isActive: (map['isActive'] as bool?) ?? true,
      cooldownType: (map['cooldownType'] as String?) ?? 'once',
    );
  }
}
