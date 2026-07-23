import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';
import '../models/config_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);

  Stream<UserModel?> streamUser(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<AppConfigModel> streamAppConfig() {
    return _firestore
        .collection(FirestoreCollections.config)
        .doc(FirestoreCollections.appConfigDoc)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return AppConfigModel.fallback();
      return AppConfigModel.fromMap(doc.data()!);
    });
  }

  Future<AppConfigModel> getAppConfig() async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.config)
          .doc(FirestoreCollections.appConfigDoc)
          .get();
      if (!doc.exists || doc.data() == null) return AppConfigModel.fallback();
      return AppConfigModel.fromMap(doc.data()!);
    } catch (_) {
      return AppConfigModel.fallback();
    }
  }

  Future<Result<void>> updateUsername(String uid, String username) async {
    try {
      await _userDoc(uid).update({'username': username.trim()});
      return const Result.success(null);
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }

  Future<Result<String>> uploadProfilePicture(String uid, File file) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$uid.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _userDoc(uid).update({'photoUrl': url});
      return Result.success(url);
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }

  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _userDoc(uid).update({'fcmToken': token});
    } catch (_) {
      // Non-critical, ignore failures silently (e.g. offline).
    }
  }
}
