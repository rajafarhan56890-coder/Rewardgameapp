import 'package:equatable/equatable.dart';

/// Pure domain entity representing an authenticated user. Contains no
/// Firebase types so the domain/presentation layers stay decoupled from
/// the backend implementation (required for clean architecture).
class UserEntity extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final int coins;
  final double cashPoints;
  final String referralCode;
  final String? referredBy;
  final bool isBanned;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? lastCheckIn;
  final int checkInStreak;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.coins,
    required this.cashPoints,
    required this.referralCode,
    this.referredBy,
    required this.isBanned,
    required this.isAdmin,
    required this.createdAt,
    this.lastCheckIn,
    required this.checkInStreak,
  });

  /// True if the user has not checked in yet today (local device date).
  bool get canCheckInToday {
    if (lastCheckIn == null) return true;
    final DateTime now = DateTime.now();
    final DateTime last = lastCheckIn!;
    return !(now.year == last.year && now.month == last.month && now.day == last.day);
  }

  UserEntity copyWith({
    String? name,
    String? photoUrl,
    int? coins,
    double? cashPoints,
    bool? isBanned,
    DateTime? lastCheckIn,
    int? checkInStreak,
  }) {
    return UserEntity(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      coins: coins ?? this.coins,
      cashPoints: cashPoints ?? this.cashPoints,
      referralCode: referralCode,
      referredBy: referredBy,
      isBanned: isBanned ?? this.isBanned,
      isAdmin: isAdmin,
      createdAt: createdAt,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      checkInStreak: checkInStreak ?? this.checkInStreak,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        photoUrl,
        coins,
        cashPoints,
        referralCode,
        referredBy,
        isBanned,
        isAdmin,
        createdAt,
        lastCheckIn,
        checkInStreak,
      ];
}
