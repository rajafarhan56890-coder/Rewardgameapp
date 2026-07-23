import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String _generateReferralCode(String username) {
    final rand = Random.secure();
    final suffix = List.generate(4, (_) => rand.nextInt(10)).join();
    final prefix = username.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final clean = prefix.isEmpty ? 'USER' : prefix;
    return '${clean.substring(0, clean.length > 5 ? 5 : clean.length)}$suffix';
  }

  Future<Result<UserModel>> register({
    required String username,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      await credential.user!.updateDisplayName(username.trim());

      String? referrerUid;
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        final query = await _firestore
            .collection(FirestoreCollections.users)
            .where('referralCode', isEqualTo: referralCode.trim().toUpperCase())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          referrerUid = query.docs.first.id;
        }
      }

      final newUser = UserModel(
        uid: uid,
        username: username.trim(),
        email: email.trim(),
        photoUrl: '',
        coins: referrerUid != null ? 50 : 0, // welcome bonus if referred
        cashPoints: 0,
        referralCode: _generateReferralCode(username),
        referredBy: referrerUid,
        createdAt: DateTime.now(),
      );

      final batch = _firestore.batch();
      final userRef = _firestore.collection(FirestoreCollections.users).doc(uid);
      batch.set(userRef, newUser.toMap());

      if (referrerUid != null) {
        final referralRef = _firestore.collection(FirestoreCollections.referrals).doc();
        batch.set(referralRef, {
          'referrerUid': referrerUid,
          'referredUid': uid,
          'referredUsername': username.trim(),
          'status': 'pending', // becomes 'rewarded' once referred user completes first task
          'createdAt': Timestamp.now(),
        });
      }

      await batch.commit();
      return Result.success(newUser);
    } on FirebaseAuthException catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }

  Future<Result<UserModel>> login({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(credential.user!.uid)
          .get();
      if (!doc.exists) {
        return const Result.failure('Account data not found. Please contact support.');
      }
      return Result.success(UserModel.fromMap(doc.data()!, doc.id));
    } on FirebaseAuthException catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }

  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<Result<void>> deleteAccount() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const Result.failure('No user is signed in.');
      await _firestore.collection(FirestoreCollections.users).doc(uid).delete();
      await _auth.currentUser?.delete();
      return const Result.success(null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const Result.failure(
            'Please log out and log back in before deleting your account.');
      }
      return Result.failure(friendlyErrorMessage(e));
    } catch (e) {
      return Result.failure(friendlyErrorMessage(e));
    }
  }
}
