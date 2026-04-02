import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn(),
       _db = firestore ?? FirebaseFirestore.instance;

  static const String _usernameAliasDomain = 'queueup.app';

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _db;

  @override
  Future<bool> isUsernameAvailable({required String username}) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) {
      return false;
    }
    final doc = await _db.collection('usernames').doc(normalized).get();
    return !doc.exists;
  }

  @override
  Future<UserModel> signInWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    final normalized = _normalizeUsername(username);
    if (normalized.length < 3) {
      throw StateError('Username is invalid.');
    }

    developer.log(
      'Username/password sign-in requested for $normalized',
      name: 'FirebaseAuthRepository',
    );
    final usernameRecord = await _loadUsernameRecord(normalized);
    final authEmail = _resolveUsernameAuthEmail(usernameRecord, normalized);

    final credential = await _auth.signInWithEmailAndPassword(
      email: authEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Authentication failed. Please try again.');
    }

    return _hydrateUserModel(
      user,
      fallbackDisplayName: username.trim(),
      authProvider: 'password',
      authEmailAlias: _aliasEmailForUsername(normalized),
      authEmail: authEmail,
      hasLinkedEmail: !_isAliasEmail(authEmail),
    );
  }

  @override
  Future<UserModel> registerWithUsernamePassword({
    required String username,
    required String password,
    String? avatarUrl,
    String? recoveryEmail,
  }) async {
    final trimmedUsername = username.trim();
    final normalized = _normalizeUsername(trimmedUsername);
    if (normalized.length < 3) {
      throw StateError('Username is invalid.');
    }

    final sanitizedRecoveryEmail = _sanitizeRecoveryEmail(recoveryEmail);
    final aliasEmail = _aliasEmailForUsername(normalized);
    final authEmail = sanitizedRecoveryEmail ?? aliasEmail;
    final hasLinkedEmail = !_isAliasEmail(authEmail);

    developer.log(
      'Username/password registration requested for $normalized',
      name: 'FirebaseAuthRepository',
    );

    final credential = await _auth.createUserWithEmailAndPassword(
      email: authEmail,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Unable to create your account right now.');
    }

    try {
      if ((user.displayName ?? '').trim() != trimmedUsername) {
        await user.updateDisplayName(trimmedUsername);
      }
      await user.reload();
      await _claimUsername(
        trimmedUsername,
        user.uid,
        aliasEmail: aliasEmail,
        authEmail: authEmail,
        hasEmail: hasLinkedEmail,
      );
      return _hydrateUserModel(
        _auth.currentUser ?? user,
        fallbackDisplayName: trimmedUsername,
        avatarUrl: avatarUrl,
        authProvider: 'password',
        authEmailAlias: aliasEmail,
        authEmail: authEmail,
        hasLinkedEmail: hasLinkedEmail,
        recoveryEmail: sanitizedRecoveryEmail,
      );
    } catch (error) {
      try {
        await (_auth.currentUser ?? user).delete();
      } catch (_) {}
      try {
        await _auth.signOut();
      } catch (_) {}
      rethrow;
    }
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

    final UserCredential result = await _auth.signInWithCredential(credential);
    final User? user = result.user;
    if (user == null) {
      throw StateError('Google sign-in failed.');
    }

    return _hydrateUserModel(
      user,
      fallbackDisplayName: user.displayName ?? 'QueuePlayer',
      avatarUrl: user.photoURL,
      authProvider: 'google',
    );
  }

  Future<UserModel> _hydrateUserModel(
    User user, {
    required String fallbackDisplayName,
    String? avatarUrl,
    String? authProvider,
    String? authEmailAlias,
    String? authEmail,
    bool? hasLinkedEmail,
    String? recoveryEmail,
  }) async {
    final syncedUser = await _syncAuthEmailState(
      user,
      fallbackDisplayName: fallbackDisplayName,
    );
    final snapshot = await _db.collection('users').doc(syncedUser.uid).get();
    final data = snapshot.data();
    final storedName = (data?['displayName'] as String?)?.trim();
    final storedAvatar = (data?['avatarUrl'] as String?)?.trim();

    final resolvedName = storedName != null && storedName.isNotEmpty
        ? storedName
        : ((syncedUser.displayName ?? '').trim().isNotEmpty
              ? syncedUser.displayName!.trim()
              : fallbackDisplayName);
    final resolvedAvatar = avatarUrl ?? storedAvatar ?? syncedUser.photoURL;

    if ((syncedUser.displayName ?? '').trim() != resolvedName.trim()) {
      try {
        await syncedUser.updateDisplayName(resolvedName);
      } catch (_) {}
    }

    await _upsertUserProfile(
      syncedUser,
      displayName: resolvedName,
      avatarUrl: resolvedAvatar,
      authProvider: authProvider,
      authEmailAlias: authEmailAlias,
      authEmail: authEmail,
      hasLinkedEmail: hasLinkedEmail,
      recoveryEmail: recoveryEmail,
    );

    return UserModel(
      id: syncedUser.uid,
      displayName: resolvedName,
      avatarUrl: resolvedAvatar,
    );
  }

  Future<void> _upsertUserProfile(
    User user, {
    required String displayName,
    String? avatarUrl,
    String? authProvider,
    String? authEmailAlias,
    String? authEmail,
    bool? hasLinkedEmail,
    String? recoveryEmail,
  }) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    final publicData = <String, dynamic>{
      'displayName': displayName,
      'avatarUrl': avatarUrl ?? user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (authEmail != null && authEmail.trim().isNotEmpty) {
      publicData['authEmail'] = authEmail.trim().toLowerCase();
    }
    if (hasLinkedEmail != null) {
      publicData['hasEmail'] = hasLinkedEmail;
    }

    if (!snapshot.exists) {
      publicData['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(publicData, SetOptions(merge: true));

    final privateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (authProvider != null && authProvider.trim().isNotEmpty) {
      privateData['authProvider'] = authProvider;
    }
    if (authEmailAlias != null && authEmailAlias.trim().isNotEmpty) {
      privateData['usernameAliasEmail'] = authEmailAlias;
    }
    if (authEmail != null && authEmail.trim().isNotEmpty) {
      privateData['authEmail'] = authEmail.trim().toLowerCase();
    }
    if (hasLinkedEmail != null) {
      privateData['hasEmail'] = hasLinkedEmail;
    }
    if (recoveryEmail != null) {
      privateData['recoveryEmail'] = recoveryEmail;
    }

    if (privateData.length > 1) {
      await docRef
          .collection('private')
          .doc('profile')
          .set(privateData, SetOptions(merge: true));
    }
  }

  Future<void> _claimUsername(
    String username,
    String uid, {
    String? aliasEmail,
    String? authEmail,
    bool? hasEmail,
  }) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) {
      throw StateError('Username is invalid.');
    }

    final docRef = _db.collection('usernames').doc(normalized);
    final trimmedAliasEmail = aliasEmail?.trim();
    final trimmedAuthEmail = authEmail?.trim().toLowerCase();
    await _db.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['uid'] != uid) {
          throw StateError('Username already taken');
        }
      }
      final payload = <String, dynamic>{
        'uid': uid,
        'username': username.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (trimmedAliasEmail != null && trimmedAliasEmail.isNotEmpty) {
        payload['authEmailAlias'] = trimmedAliasEmail;
      }
      if (trimmedAuthEmail != null && trimmedAuthEmail.isNotEmpty) {
        payload['authEmail'] = trimmedAuthEmail;
      }
      if (hasEmail != null) {
        payload['hasEmail'] = hasEmail;
      }
      tx.set(docRef, payload, SetOptions(merge: true));
    });
  }

  @override
  Future<bool> canSendPasswordReset({required String username}) async {
    final normalized = _normalizeUsername(username);
    if (normalized.length < 3) {
      return false;
    }

    final record = await _loadUsernameRecord(normalized);
    final authEmail = (record['authEmail'] as String?)?.trim().toLowerCase();
    final hasEmail = (record['hasEmail'] as bool?) ?? false;
    return hasEmail && authEmail != null && authEmail.isNotEmpty;
  }

  @override
  Future<void> sendPasswordReset({required String username}) async {
    final normalized = _normalizeUsername(username);
    if (normalized.length < 3) {
      throw StateError('Username is invalid.');
    }

    final record = await _loadUsernameRecord(normalized);
    final authEmail = (record['authEmail'] as String?)?.trim().toLowerCase();
    final hasEmail = (record['hasEmail'] as bool?) ?? false;
    if (!hasEmail || authEmail == null || authEmail.isEmpty) {
      throw StateError('No linked email.');
    }

    try {
      developer.log(
        'Sending password reset email for $normalized -> $authEmail',
        name: 'FirebaseAuthRepository',
      );
      await _auth.sendPasswordResetEmail(email: authEmail);
      developer.log(
        'Password reset email accepted by Firebase for $normalized -> $authEmail',
        name: 'FirebaseAuthRepository',
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      developer.log(
        'Password reset email failed for $normalized -> $authEmail: ${error.code} ${error.message}',
        name: 'FirebaseAuthRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected password reset failure for $normalized -> $authEmail: $error',
        name: 'FirebaseAuthRepository',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  String _normalizeUsername(String username) {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  Future<Map<String, dynamic>> _loadUsernameRecord(
    String normalizedUsername,
  ) async {
    final snapshot = await _db
        .collection('usernames')
        .doc(normalizedUsername)
        .get();
    final data = snapshot.data();
    final uid = data?['uid'] as String?;
    if (uid == null || uid.trim().isEmpty) {
      throw StateError('Account not found. Try again.');
    }
    return data!;
  }

  String _aliasEmailForUsername(String username) {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) {
      throw StateError('Username is invalid.');
    }
    return '$normalized@$_usernameAliasDomain';
  }

  String? _sanitizeRecoveryEmail(String? email) {
    final trimmed = email?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final isValid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
    if (!isValid) {
      throw StateError('Recovery email is invalid.');
    }
    return trimmed.toLowerCase();
  }

  String _resolveUsernameAuthEmail(
    Map<String, dynamic> usernameRecord,
    String normalizedUsername,
  ) {
    final authEmail = (usernameRecord['authEmail'] as String?)?.trim();
    if (authEmail != null && authEmail.isNotEmpty) {
      return authEmail.toLowerCase();
    }

    final aliasEmail = (usernameRecord['authEmailAlias'] as String?)?.trim();
    if (aliasEmail != null && aliasEmail.isNotEmpty) {
      return aliasEmail.toLowerCase();
    }

    return _aliasEmailForUsername(normalizedUsername);
  }

  bool _isAliasEmail(String? email) {
    final trimmed = email?.trim().toLowerCase() ?? '';
    return trimmed.endsWith('@$_usernameAliasDomain');
  }

  Future<User> _syncAuthEmailState(
    User user, {
    required String fallbackDisplayName,
  }) async {
    await user.reload();
    final refreshedUser = _auth.currentUser ?? user;
    final authEmail = refreshedUser.email?.trim().toLowerCase() ?? '';
    final isAliasEmail = _isAliasEmail(authEmail);
    final hasLinkedEmail = authEmail.isNotEmpty && !isAliasEmail;
    final userRef = _db.collection('users').doc(refreshedUser.uid);
    final privateRef = userRef.collection('private').doc('profile');
    final privateSnapshot = await privateRef.get();
    final privateData = privateSnapshot.data() ?? <String, dynamic>{};
    final pendingAuthEmail =
        (privateData['pendingAuthEmail'] as String?)?.trim().toLowerCase() ??
        '';
    final currentDisplayName = (refreshedUser.displayName ?? '').trim().isEmpty
        ? fallbackDisplayName
        : refreshedUser.displayName!.trim();

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'authEmail': authEmail,
      'hasEmail': hasLinkedEmail,
      'usernameAliasEmail': _aliasEmailForUsername(currentDisplayName),
    };

    if (hasLinkedEmail && pendingAuthEmail == authEmail) {
      updates['pendingAuthEmail'] = FieldValue.delete();
      updates['emailVerifiedAt'] = FieldValue.serverTimestamp();
    }

    if (privateSnapshot.exists || updates.length > 1) {
      await privateRef.set(updates, SetOptions(merge: true));
    }

    await userRef.set(<String, dynamic>{
      'authEmail': authEmail,
      'hasEmail': hasLinkedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final normalizedUsername = _normalizeUsername(currentDisplayName);
    if (normalizedUsername.isNotEmpty) {
      await _db
          .collection('usernames')
          .doc(normalizedUsername)
          .set(<String, dynamic>{
            'uid': refreshedUser.uid,
            'username': currentDisplayName,
            'authEmailAlias': _aliasEmailForUsername(normalizedUsername),
            'authEmail': authEmail,
            'hasEmail': hasLinkedEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    return refreshedUser;
  }
}
