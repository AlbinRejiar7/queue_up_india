import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/utils/app_preferences.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  static const Duration _otpSessionTtl = Duration(minutes: 10);
  static const String _otpExpiredMessage =
      'OTP session expired. Please request a new code.';

  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  String? _verificationId;
  int? _forceResendingToken;

  @override
  Future<void> sendOtp({required String phoneNumber}) async {
    _verificationId = null;
    await AppPreferences.clearOtpSession();
    final Completer<void> completer = Completer<void>();
    developer.log(
      'Firebase sendOtp start',
      name: 'FirebaseAuthRepository',
      error: _maskPhone(phoneNumber),
    );

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _forceResendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {
          // Ignore auto-verification sign-in failures.
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      verificationFailed: (FirebaseAuthException error) {
        developer.log(
          'Firebase sendOtp failed: ${error.code}',
          name: 'FirebaseAuthRepository',
        );
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        developer.log(
          'Firebase sendOtp codeSent',
          name: 'FirebaseAuthRepository',
        );
        _verificationId = verificationId;
        _forceResendingToken = forceResendingToken;
        AppPreferences.saveOtpSession(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
          sentAt: DateTime.now(),
          forceResendingToken: forceResendingToken,
        );
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    return completer.future;
  }

  @override
  Future<bool> isPhoneRegistered({required String phoneNumber}) async {
    final callable = _functions.httpsCallable('checkPhoneRegistered');
    try {
      developer.log(
        'checkPhoneRegistered called',
        name: 'FirebaseAuthRepository',
        error: _maskPhone(phoneNumber),
      );
      final result = await callable.call(<String, dynamic>{
        'phoneNumber': phoneNumber,
      });
      final data = result.data;
      if (data is Map && data['registered'] is bool) {
        developer.log(
          'checkPhoneRegistered result: ${data['registered']}',
          name: 'FirebaseAuthRepository',
        );
        return data['registered'] as bool;
      }
      return false;
    } on FirebaseFunctionsException catch (error) {
      developer.log(
        'checkPhoneRegistered error: ${error.code}',
        name: 'FirebaseAuthRepository',
      );
      if (error.code == 'not-found') {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<bool> isUsernameAvailable({required String username}) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) {
      return false;
    }
    final doc =
        await _db.collection('usernames').doc(normalized).get();
    return !doc.exists;
  }

  @override
  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? avatarUrl,
    String? displayName,
  }) async {
    String? verificationId = _verificationId;
    if (verificationId == null) {
      final session = await AppPreferences.loadOtpSession();
      if (session != null &&
          session.phoneNumber == phoneNumber &&
          DateTime.now().difference(session.sentAt) <= _otpSessionTtl) {
        verificationId = session.verificationId;
        _verificationId = session.verificationId;
        _forceResendingToken = session.forceResendingToken;
      } else {
        await AppPreferences.clearOtpSession();
      }
    }
    if (verificationId == null) {
      throw StateError(_otpExpiredMessage);
    }

    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );

    UserCredential result;
    try {
      result = await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'session-expired' || error.code == 'code-expired') {
        await AppPreferences.clearOtpSession();
      }
      rethrow;
    }
    final User? user = result.user;
    if (user == null) {
      throw StateError('Authentication failed. Please try again.');
    }
    await AppPreferences.clearOtpSession();
    _verificationId = null;
    _forceResendingToken = null;

    final String? trimmedName = displayName?.trim();
    String? storedName;
    String? storedAvatar;
    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      storedName = (data?['displayName'] as String?)?.trim();
      storedAvatar = (data?['avatarUrl'] as String?)?.trim();
    } catch (_) {}

    final resolvedName =
        trimmedName != null && trimmedName.isNotEmpty
            ? trimmedName
            : (storedName != null && storedName.isNotEmpty
                ? storedName
                : (user.displayName ?? 'QueuePlayer'));
    final resolvedAvatar =
        avatarUrl ??
        (storedAvatar != null && storedAvatar.isNotEmpty
            ? storedAvatar
            : user.photoURL);

    if ((user.displayName ?? '').trim() != resolvedName.trim()) {
      try {
        await user.updateDisplayName(resolvedName);
      } catch (_) {}
    }

    await user.reload();
    final User? refreshed = _auth.currentUser;
    await _upsertUserProfile(
      refreshed ?? user,
      displayName: resolvedName,
      avatarUrl: resolvedAvatar,
    );
    if (trimmedName != null && trimmedName.isNotEmpty) {
      await _claimUsername(trimmedName, user.uid);
    }
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('private')
        .doc('profile')
        .set(
          <String, dynamic>{
            'phoneNumber': phoneNumber,
            'phoneNumberDigits': _normalizePhoneDigits(phoneNumber),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

    return UserModel(
      id: refreshed?.uid ?? user.uid,
      displayName: resolvedName,
      avatarUrl: resolvedAvatar,
    );
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google sign-in cancelled.');
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final UserCredential result =
        await _auth.signInWithCredential(credential);
    final User? user = result.user;
    if (user == null) {
      throw StateError('Google sign-in failed.');
    }

    String? storedName;
    String? storedAvatar;
    try {
      final snapshot = await _db.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      storedName = (data?['displayName'] as String?)?.trim();
      storedAvatar = (data?['avatarUrl'] as String?)?.trim();
    } catch (_) {}

    final resolvedName =
        storedName != null && storedName.isNotEmpty
            ? storedName
            : (user.displayName ?? 'QueuePlayer');
    final resolvedAvatar =
        storedAvatar != null && storedAvatar.isNotEmpty
            ? storedAvatar
            : user.photoURL;

    if ((user.displayName ?? '').trim() != resolvedName.trim()) {
      try {
        await user.updateDisplayName(resolvedName);
      } catch (_) {}
    }

    await user.reload();

    await _upsertUserProfile(
      _auth.currentUser ?? user,
      displayName: resolvedName,
      avatarUrl: resolvedAvatar,
    );

    return UserModel(
      id: user.uid,
      displayName: resolvedName,
      avatarUrl: resolvedAvatar,
    );
  }

  @override
  Future<void> _upsertUserProfile(
    User user, {
    String? displayName,
    String? avatarUrl,
  }) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final String resolvedName =
        displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : (user.displayName ?? 'QueuePlayer');

    final data = <String, dynamic>{
      'displayName': resolvedName,
      'avatarUrl': avatarUrl ?? user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
  }

  Future<void> _claimUsername(String username, String uid) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) {
      throw StateError('Username is invalid.');
    }

    final docRef = _db.collection('usernames').doc(normalized);
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['uid'] != uid) {
          throw StateError('Username already taken');
        }
      }
      tx.set(
        docRef,
        <String, dynamic>{
          'uid': uid,
          'username': username.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  String _normalizeUsername(String username) {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return '';
    }
    final normalized =
        trimmed.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return normalized;
  }

  String _normalizePhoneDigits(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _maskPhone(String phoneNumber) {
    final digits = _normalizePhoneDigits(phoneNumber);
    if (digits.length <= 4) {
      return phoneNumber;
    }
    final tail = digits.substring(digits.length - 4);
    return '+••••$tail';
  }
}
