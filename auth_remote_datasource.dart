import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({required this.firebaseAuth, required this.firestore});

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      firestore.collection(FirestorePaths.users);

  @override
  Stream<UserModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().asyncMap((fb.User? fbUser) async {
      if (fbUser == null) return null;
      try {
        final DocumentSnapshot<Map<String, dynamic>> doc =
            await _usersRef.doc(fbUser.uid).get();
        if (!doc.exists || doc.data() == null) return null;
        return UserModel.fromFirestore(doc.data()!, fbUser.uid);
      } catch (e) {
        AppLogger.e('authStateChanges: failed to load user doc', e);
        return null;
      }
    });
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    try {
      final fb.UserCredential credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fb.User? fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Login failed. Please try again.');
      }

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _usersRef.doc(fbUser.uid).get();

      if (!doc.exists || doc.data() == null) {
        throw const AuthException(
            'Account data not found. Please contact support.');
      }

      final UserModel user = UserModel.fromFirestore(doc.data()!, fbUser.uid);

      if (user.isBanned) {
        await firebaseAuth.signOut();
        throw const AccountBannedException();
      }

      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    fb.UserCredential? credential;
    try {
      // If a referral code was provided, validate it BEFORE creating the
      // account so we never leave an orphaned auth user if it's invalid.
      String? referrerUid;
      if (referralCode != null) {
        final QuerySnapshot<Map<String, dynamic>> referrerQuery = await _usersRef
            .where(UserFields.referralCode, isEqualTo: referralCode)
            .limit(1)
            .get();
        if (referrerQuery.docs.isEmpty) {
          throw const AuthException('Invalid referral code.');
        }
        referrerUid = referrerQuery.docs.first.id;
      }

      credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fb.User? fbUser = credential.user;
      if (fbUser == null) {
        throw const AuthException('Registration failed. Please try again.');
      }

      await fbUser.updateDisplayName(name);

      final String newReferralCode = _generateReferralCode(fbUser.uid);

      final UserModel newUser = UserModel(
        uid: fbUser.uid,
        name: name,
        email: email,
        photoUrl: null,
        coins: 0,
        cashPoints: 0,
        referralCode: newReferralCode,
        referredBy: referrerUid,
        isBanned: false,
        isAdmin: false,
        createdAt: DateTime.now(),
        lastCheckIn: null,
        checkInStreak: 0,
      );

      // Write user doc. Referral bonus crediting is handled server-side
      // (Cloud Function trigger on user creation) so it can't be spoofed
      // by a malicious client skipping this step.
      await _usersRef.doc(fbUser.uid).set(newUser.toFirestore());

      return newUser;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    } catch (e) {
      // Roll back the auth account if Firestore write failed, so the
      // user isn't left in a broken half-registered state.
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {
          // best effort cleanup
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e));
    }
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final fb.User? fbUser = firebaseAuth.currentUser;
    if (fbUser == null) {
      throw const AuthException('No active session.');
    }
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _usersRef.doc(fbUser.uid).get();
    if (!doc.exists || doc.data() == null) {
      throw const AuthException('Account data not found.');
    }
    final UserModel user = UserModel.fromFirestore(doc.data()!, fbUser.uid);
    if (user.isBanned) {
      await firebaseAuth.signOut();
      throw const AccountBannedException();
    }
    return user;
  }

  String _generateReferralCode(String uid) {
    const String chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final Random random = Random(uid.hashCode ^ DateTime.now().microsecondsSinceEpoch);
    return List.generate(7, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _mapFirebaseAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'This password is too weak.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        AppLogger.e('Unmapped FirebaseAuthException: ${e.code}');
        return 'Authentication failed. Please try again.';
    }
  }
}
