import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/constants/app_constants.dart';
import '../models/config_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  NotificationRepository({FirebaseFirestore? firestore, FirebaseMessaging? messaging})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) => _firestore
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.notifications);

  Stream<List<NotificationModel>> streamNotifications(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => NotificationModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<int> streamUnreadCount(String uid) {
    return _collection(uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String uid, String notificationId) async {
    await _collection(uid).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid) async {
    final unread = await _collection(uid).where('isRead', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Requests notification permission and returns the FCM device token so
  /// it can be saved on the user document (used by a backend/Cloud
  /// Function to target push notifications at this device).
  Future<String?> initPushNotifications() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }
}
