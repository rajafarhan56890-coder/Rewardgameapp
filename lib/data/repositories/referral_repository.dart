import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class ReferralModel {
  final String id;
  final String referredUsername;
  final String status;
  final DateTime createdAt;

  const ReferralModel({
    required this.id,
    required this.referredUsername,
    required this.status,
    required this.createdAt,
  });

  factory ReferralModel.fromMap(Map<String, dynamic> map, String id) {
    return ReferralModel(
      id: id,
      referredUsername: (map['referredUsername'] as String?) ?? 'Friend',
      status: (map['status'] as String?) ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ReferralRepository {
  final FirebaseFirestore _firestore;

  ReferralRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ReferralModel>> streamReferrals(String uid) {
    return _firestore
        .collection(FirestoreCollections.referrals)
        .where('referrerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ReferralModel.fromMap(d.data(), d.id)).toList());
  }
}
