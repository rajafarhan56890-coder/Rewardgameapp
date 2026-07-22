import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/user_entity.dart';

/// Data-layer model. Adds fromFirestore/toFirestore on top of the pure
/// domain entity — this is the only place Firestore's DocumentSnapshot
/// type is allowed to appear for user data.
class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.photoUrl,
    required super.coins,
    required super.cashPoints,
    required super.referralCode,
    super.referredBy,
    required super.isBanned,
    required super.isAdmin,
    required super.createdAt,
    super.lastCheckIn,
    required super.checkInStreak,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: (data[UserFields.name] as String?) ?? '',
      email: (data[UserFields.email] as String?) ?? '',
      photoUrl: data[UserFields.photoUrl] as String?,
      coins: (data[UserFields.coins] as num?)?.toInt() ?? 0,
      cashPoints: (data[UserFields.cashPoints] as num?)?.toDouble() ?? 0.0,
      referralCode: (data[UserFields.referralCode] as String?) ?? '',
      referredBy: data[UserFields.referredBy] as String?,
      isBanned: (data[UserFields.isBanned] as bool?) ?? false,
      isAdmin: (data[UserFields.isAdmin] as bool?) ?? false,
      createdAt: (data[UserFields.createdAt] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastCheckIn: (data[UserFields.lastCheckIn] as Timestamp?)?.toDate(),
      checkInStreak: (data[UserFields.checkInStreak] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      UserFields.uid: uid,
      UserFields.name: name,
      UserFields.email: email,
      UserFields.photoUrl: photoUrl,
      UserFields.coins: coins,
      UserFields.cashPoints: cashPoints,
      UserFields.referralCode: referralCode,
      UserFields.referredBy: referredBy,
      UserFields.isBanned: isBanned,
      UserFields.isAdmin: isAdmin,
      UserFields.createdAt: Timestamp.fromDate(createdAt),
      UserFields.lastCheckIn: lastCheckIn != null ? Timestamp.fromDate(lastCheckIn!) : null,
      UserFields.checkInStreak: checkInStreak,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      photoUrl: entity.photoUrl,
      coins: entity.coins,
      cashPoints: entity.cashPoints,
      referralCode: entity.referralCode,
      referredBy: entity.referredBy,
      isBanned: entity.isBanned,
      isAdmin: entity.isAdmin,
      createdAt: entity.createdAt,
      lastCheckIn: entity.lastCheckIn,
      checkInStreak: entity.checkInStreak,
    );
  }
}
