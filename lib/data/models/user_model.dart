import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String photoUrl;
  final int coins;
  final double cashPoints;
  final String referralCode;
  final String? referredBy;
  final int referralCount;
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.coins,
    required this.cashPoints,
    required this.referralCode,
    required this.createdAt,
    this.referredBy,
    this.referralCount = 0,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: (map['username'] as String?)?.trim() ?? 'User',
      email: (map['email'] as String?) ?? '',
      photoUrl: (map['photoUrl'] as String?) ?? '',
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      cashPoints: (map['cashPoints'] as num?)?.toDouble() ?? 0,
      referralCode: (map['referralCode'] as String?) ?? '',
      referredBy: map['referredBy'] as String?,
      referralCount: (map['referralCount'] as num?)?.toInt() ?? 0,
      fcmToken: map['fcmToken'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'coins': coins,
      'cashPoints': cashPoints,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'referralCount': referralCount,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? username,
    String? photoUrl,
    int? coins,
    double? cashPoints,
    int? referralCount,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      username: username ?? this.username,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      coins: coins ?? this.coins,
      cashPoints: cashPoints ?? this.cashPoints,
      referralCode: referralCode,
      referredBy: referredBy,
      referralCount: referralCount ?? this.referralCount,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
