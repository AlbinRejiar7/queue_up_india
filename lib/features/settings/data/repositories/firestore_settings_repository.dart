import 'dart:developer' as developer;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/utils/username_availability_cache.dart';
import '../../../../firebase_options.dart';
import '../../models/language_model.dart';
import '../../models/profile_preferences_model.dart';
import 'settings_repository.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  static const String _selectedLanguageKey = 'selected_language_code';
  static const String _firstLaunchKey = 'is_first_launch';

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<List<LanguageModel>> fetchSupportedLanguages() async {
    final snapshot = await _db
        .collection('languages')
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) {
      return _fallbackLanguages;
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final englishLabel = (data['name'] as String?) ?? doc.id;
      final nativeLabel = (data['nativeName'] as String?) ?? englishLabel;
      return LanguageModel(
        code: doc.id,
        nativeLabel: nativeLabel,
        englishLabel: englishLabel,
        subtitle: englishLabel,
      );
    }).toList();
  }

  @override
  Future<String?> fetchSelectedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageKey);
  }

  @override
  Future<void> saveSelectedLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, code);

    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set(<String, dynamic>{
        'preferredLanguageId': code,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  @override
  Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  @override
  Future<ProfilePreferencesModel> fetchProfilePreferences() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _fallbackProfile();
    }

    final refreshedUser = await _syncVerifiedAuthEmail(user);

    final snapshot = await _db.collection('users').doc(refreshedUser.uid).get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final privateSnapshot = await snapshot.reference
        .collection('private')
        .doc('profile')
        .get();
    final privateData = privateSnapshot.data() ?? <String, dynamic>{};
    final queueName =
        (data['displayName'] as String?) ?? user.displayName ?? 'QueuePlayer';
    final preferredLanguageCode =
        (data['preferredLanguageId'] as String?) ??
        await fetchSelectedLanguageCode() ??
        'en';
    final avatarUrl = (data['avatarUrl'] as String?) ?? AppImages.avatarHost;
    final recoveryEmail = (privateData['recoveryEmail'] as String?) ?? '';
    final authEmail =
        (privateData['authEmail'] as String?)?.trim() ??
        (data['authEmail'] as String?)?.trim() ??
        (refreshedUser.email ?? '').trim();
    final pendingAuthEmail =
        (privateData['pendingAuthEmail'] as String?)?.trim() ?? '';
    final hasLinkedEmail =
        (privateData['hasEmail'] as bool?) ??
        (data['hasEmail'] as bool?) ??
        (!_isAliasEmail(authEmail) && authEmail.isNotEmpty);

    return ProfilePreferencesModel(
      queueName: queueName,
      preferredLanguageCode: preferredLanguageCode,
      avatarUrl: avatarUrl,
      recoveryEmail: recoveryEmail,
      authEmail: authEmail,
      pendingAuthEmail: pendingAuthEmail,
      hasLinkedEmail: hasLinkedEmail,
    );
  }

  @override
  Future<bool> isUsernameAvailable({required String username}) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) {
      return false;
    }

    return UsernameAvailabilityCache.getOrLoad(
      normalizedUsername: normalized,
      loader: () async {
        final snapshot = await _db
            .collection('usernames')
            .doc(normalized)
            .get();
        return !snapshot.exists;
      },
    );
  }

  @override
  Future<void> saveProfilePreferences(
    ProfilePreferencesModel preferences,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final trimmedName = preferences.queueName.trim();
    final normalizedName = _normalizeUsername(trimmedName);
    if (normalizedName.length < 3) {
      throw StateError('Username is invalid.');
    }

    final userRef = _db.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final currentDisplayName =
        (data['displayName'] as String?)?.trim() ??
        user.displayName?.trim() ??
        '';
    final currentNormalized = _normalizeUsername(currentDisplayName);
    final currentAuthEmail = await _resolveCurrentAuthEmail(
      user,
      normalizedUsername: normalizedName,
    );
    final authEmailAlias = await _resolvePasswordAliasEmail(
      user,
      normalizedName,
    );
    final hasLinkedEmail = !_isAliasEmail(currentAuthEmail);
    final usernames = _db.collection('usernames');
    final newUsernameRef = usernames.doc(normalizedName);
    final currentUsernameRef =
        currentNormalized.isNotEmpty && currentNormalized != normalizedName
        ? usernames.doc(currentNormalized)
        : null;

    await _db.runTransaction((tx) async {
      final newUsernameSnapshot = await tx.get(newUsernameRef);
      final currentUsernameSnapshot = currentUsernameRef == null
          ? null
          : await tx.get(currentUsernameRef);
      if (newUsernameSnapshot.exists) {
        final usernameData = newUsernameSnapshot.data();
        if (usernameData != null && usernameData['uid'] != user.uid) {
          throw StateError('Username already taken');
        }
      }

      tx.set(newUsernameRef, <String, dynamic>{
        'uid': user.uid,
        'username': trimmedName,
        if (authEmailAlias.isNotEmpty) 'authEmailAlias': authEmailAlias,
        'authEmail': currentAuthEmail,
        'hasEmail': hasLinkedEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (currentUsernameRef != null && currentUsernameSnapshot != null) {
        final currentUsernameData = currentUsernameSnapshot.data();
        if (currentUsernameSnapshot.exists &&
            currentUsernameData != null &&
            currentUsernameData['uid'] == user.uid) {
          tx.delete(currentUsernameRef);
        }
      }
    });
    UsernameAvailabilityCache.prime(
      normalizedUsername: normalizedName,
      isAvailable: false,
    );
    if (currentNormalized.isNotEmpty && currentNormalized != normalizedName) {
      UsernameAvailabilityCache.prime(
        normalizedUsername: currentNormalized,
        isAvailable: true,
      );
    }

    await userRef.set(<String, dynamic>{
      'displayName': preferences.queueName,
      'preferredLanguageId': preferences.preferredLanguageCode,
      'avatarUrl': preferences.avatarUrl,
      'authEmail': currentAuthEmail,
      'hasEmail': hasLinkedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final trimmedRecoveryEmail = preferences.recoveryEmail.trim();
    await userRef.collection('private').doc('profile').set(<String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'authEmail': currentAuthEmail,
      'hasEmail': hasLinkedEmail,
      if (authEmailAlias.isNotEmpty) 'usernameAliasEmail': authEmailAlias,
      'recoveryEmail': trimmedRecoveryEmail.isEmpty
          ? FieldValue.delete()
          : trimmedRecoveryEmail.toLowerCase(),
    }, SetOptions(merge: true));

    if (trimmedName.isNotEmpty &&
        (user.displayName ?? '').trim() != trimmedName) {
      try {
        await user.updateDisplayName(trimmedName);
        await user.reload();
      } catch (_) {}
    }
  }

  @override
  Future<void> requestAuthEmailUpdate({
    required String username,
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }

    final trimmedPassword = currentPassword.trim();
    if (trimmedPassword.isEmpty) {
      throw StateError('Current password is required.');
    }

    final trimmedEmail = newEmail.trim().toLowerCase();
    if (!_isValidEmail(trimmedEmail)) {
      throw StateError('Linked email is invalid.');
    }

    final currentAuthEmail = await _resolveCurrentAuthEmail(
      user,
      normalizedUsername: _normalizeUsername(username),
    );
    if (trimmedEmail == currentAuthEmail.toLowerCase()) {
      throw StateError('Linked email already set.');
    }

    developer.log(
      'Email verification requested for ${user.uid}: ${_maskEmail(trimmedEmail)}',
      name: 'ProfileEmailUpdate',
    );
    final authLanguageCode = await _resolveAuthLanguageCode(user.uid);
    await _auth.setLanguageCode(authLanguageCode);
    final actionCodeSettings = _buildEmailActionSettings();
    _debugEmailUpdate(
      'Auth context for ${user.uid}: '
      'project=${_auth.app.options.projectId}, '
      'tenant=${_auth.tenantId ?? '<default>'}, '
      'language=${authLanguageCode ?? '<device-default>'}, '
      'current=${_maskEmail(currentAuthEmail)}, '
      'target=${_maskEmail(trimmedEmail)}, '
      'providers=${user.providerData.map((provider) => provider.providerId).join(',')}, '
      'emailVerified=${user.emailVerified}, '
      'actionCodeSettings=${actionCodeSettings.asMap()}',
    );

    try {
      final credential = EmailAuthProvider.credential(
        email: currentAuthEmail,
        password: trimmedPassword,
      );

      developer.log(
        'Reauthenticating ${user.uid} with ${_maskEmail(currentAuthEmail)}',
        name: 'ProfileEmailUpdate',
      );
      await user.reauthenticateWithCredential(credential);
      developer.log(
        'Reauthentication succeeded for ${user.uid}',
        name: 'ProfileEmailUpdate',
      );

      await user.verifyBeforeUpdateEmail(trimmedEmail, actionCodeSettings);
      developer.log(
        'verifyBeforeUpdateEmail succeeded for ${user.uid}; verification mail sent to ${_maskEmail(trimmedEmail)}',
        name: 'ProfileEmailUpdate',
      );
      _debugEmailUpdate(
        'Verification email accepted by Firebase for ${user.uid}: '
        'target=${_maskEmail(trimmedEmail)}, '
        'language=${authLanguageCode ?? '<device-default>'}, '
        'template=email-address-change(default), '
        'continueUrl=${actionCodeSettings.url}',
      );

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('private')
          .doc('profile')
          .set(<String, dynamic>{
            'pendingAuthEmail': trimmedEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      developer.log(
        'Pending auth email saved for ${user.uid}: ${_maskEmail(trimmedEmail)}',
        name: 'ProfileEmailUpdate',
      );
      _debugEmailUpdate(
        'Pending email state persisted for ${user.uid}: '
        'pending=${_maskEmail(trimmedEmail)}',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Email verification request failed for ${user.uid}: $error',
        name: 'ProfileEmailUpdate',
        error: error,
        stackTrace: stackTrace,
      );
      _debugEmailUpdate(
        'Verification email request failed for ${user.uid}: '
        'error=$error, '
        'language=${authLanguageCode ?? '<device-default>'}, '
        'tenant=${_auth.tenantId ?? '<default>'}',
      );
      rethrow;
    }
  }

  @override
  Future<void> updatePassword({
    required String username,
    required String newPassword,
    String? currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }

    final trimmedPassword = newPassword.trim();
    if (trimmedPassword.length < 6) {
      throw StateError('Password is too short.');
    }

    final normalizedUsername = _normalizeUsername(username);
    if (normalizedUsername.length < 3) {
      throw StateError('Username is invalid.');
    }

    final authEmail = await _resolveCurrentAuthEmail(
      user,
      normalizedUsername: normalizedUsername,
    );
    final aliasEmail = await _resolvePasswordAliasEmail(
      user,
      normalizedUsername,
    );
    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );

    if (hasPasswordProvider) {
      final trimmedCurrentPassword = currentPassword?.trim() ?? '';
      if (trimmedCurrentPassword.isEmpty) {
        throw StateError('Current password is required.');
      }
      final credential = EmailAuthProvider.credential(
        email: authEmail,
        password: trimmedCurrentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(trimmedPassword);
    } else {
      final credential = EmailAuthProvider.credential(
        email: authEmail,
        password: trimmedPassword,
      );
      await user.linkWithCredential(credential);
    }

    await _db
        .collection('usernames')
        .doc(normalizedUsername)
        .set(<String, dynamic>{
          'uid': user.uid,
          'username': username.trim(),
          'authEmailAlias': aliasEmail,
          'authEmail': authEmail,
          'hasEmail': !_isAliasEmail(authEmail),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('private')
        .doc('profile')
        .set(<String, dynamic>{
          'usernameAliasEmail': aliasEmail,
          'authEmail': authEmail,
          'hasEmail': !_isAliasEmail(authEmail),
          'authProvider': 'password',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> submitBugReport({required String details}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user');
    }

    final trimmedDetails = details.trim();
    if (trimmedDetails.isEmpty) {
      throw ArgumentError('Bug report details are required');
    }

    final userSnapshot = await _db.collection('users').doc(user.uid).get();
    final userData = userSnapshot.data() ?? <String, dynamic>{};
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = await _buildDeviceInfo();

    await _db.collection('bug_reports').add(<String, dynamic>{
      'reporterId': user.uid,
      'reporterEmail': user.email,
      'reporterName':
          (userData['displayName'] as String?) ?? user.displayName ?? '',
      'details': trimmedDetails,
      'status': 'open',
      'source': 'profile_screen',
      'createdAt': FieldValue.serverTimestamp(),
      'app': <String, dynamic>{
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      },
      'device': deviceInfo,
    });
  }

  @override
  Future<void> deleteAccount({required String displayName}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final uid = user.uid;
    final userRef = _db.collection('users').doc(uid);

    await _deleteSubcollection(userRef, 'private');
    await _deleteSubcollection(userRef, 'rooms');
    await _deleteSubcollection(userRef, 'fcmTokens');
    await _deleteSubcollection(userRef, 'notifications');

    await userRef.delete();
    await _db.collection('availability').doc(uid).delete();

    final normalized = _normalizeUsername(displayName);
    if (normalized.isNotEmpty) {
      try {
        await _db.collection('usernames').doc(normalized).delete();
        UsernameAvailabilityCache.prime(
          normalizedUsername: normalized,
          isAvailable: true,
        );
      } catch (_) {}
    }

    await user.delete();
  }

  Future<void> _deleteSubcollection(
    DocumentReference<Map<String, dynamic>> parent,
    String name,
  ) async {
    final snapshot = await parent.collection(name).get();
    if (snapshot.docs.isEmpty) {
      return;
    }
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _normalizeUsername(String username) {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  Future<String> _resolveCurrentAuthEmail(
    User user, {
    required String normalizedUsername,
  }) async {
    final currentEmail = user.email?.trim();
    if (currentEmail != null && currentEmail.isNotEmpty) {
      return currentEmail.toLowerCase();
    }

    final privateSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('private')
        .doc('profile')
        .get();
    final privateData = privateSnapshot.data();
    final privateAuthEmail = (privateData?['authEmail'] as String?)?.trim();
    if (privateAuthEmail != null && privateAuthEmail.isNotEmpty) {
      return privateAuthEmail.toLowerCase();
    }

    final usernameSnapshot = await _db
        .collection('usernames')
        .doc(normalizedUsername)
        .get();
    final usernameData = usernameSnapshot.data();
    final usernameAuthEmail = (usernameData?['authEmail'] as String?)?.trim();
    if (usernameAuthEmail != null && usernameAuthEmail.isNotEmpty) {
      return usernameAuthEmail.toLowerCase();
    }

    return '$normalizedUsername@queueup.app';
  }

  Future<String> _resolvePasswordAliasEmail(
    User user,
    String normalizedUsername,
  ) async {
    final currentEmail = user.email?.trim();
    if (currentEmail != null &&
        currentEmail.toLowerCase().endsWith('@queueup.app')) {
      return currentEmail;
    }

    final privateSnapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('private')
        .doc('profile')
        .get();
    final privateData = privateSnapshot.data();
    final privateAlias = (privateData?['usernameAliasEmail'] as String?)
        ?.trim();
    if (privateAlias != null &&
        privateAlias.toLowerCase().endsWith('@queueup.app')) {
      return privateAlias;
    }

    final usernameSnapshot = await _db
        .collection('usernames')
        .doc(normalizedUsername)
        .get();
    final usernameData = usernameSnapshot.data();
    final usernameAlias = (usernameData?['authEmailAlias'] as String?)?.trim();
    if (usernameAlias != null &&
        usernameAlias.toLowerCase().endsWith('@queueup.app')) {
      return usernameAlias;
    }

    return '$normalizedUsername@queueup.app';
  }

  Future<User> _syncVerifiedAuthEmail(User user) async {
    await user.reload();
    final refreshedUser = _auth.currentUser ?? user;
    final authEmail = refreshedUser.email?.trim().toLowerCase() ?? '';
    final hasLinkedEmail = authEmail.isNotEmpty && !_isAliasEmail(authEmail);
    final userRef = _db.collection('users').doc(refreshedUser.uid);
    final privateRef = userRef.collection('private').doc('profile');
    final privateSnapshot = await privateRef.get();
    final privateData = privateSnapshot.data() ?? <String, dynamic>{};
    final pendingAuthEmail =
        (privateData['pendingAuthEmail'] as String?)?.trim().toLowerCase() ??
        '';
    final resolvedUsername = _normalizeUsername(
      (refreshedUser.displayName ?? '').trim(),
    );

    if (pendingAuthEmail.isNotEmpty) {
      if (pendingAuthEmail == authEmail && hasLinkedEmail) {
        developer.log(
          'Verified email detected for ${refreshedUser.uid}: ${_maskEmail(authEmail)}. Syncing Firestore.',
          name: 'ProfileEmailUpdate',
        );
        _debugEmailUpdate(
          'Verified email now active for ${refreshedUser.uid}: '
          'authEmail=${_maskEmail(authEmail)}, emailVerified=${refreshedUser.emailVerified}',
        );
      } else {
        developer.log(
          'Pending email still awaiting verification for ${refreshedUser.uid}: ${_maskEmail(pendingAuthEmail)}; current=${_maskEmail(authEmail)} verified=${refreshedUser.emailVerified}',
          name: 'ProfileEmailUpdate',
        );
        _debugEmailUpdate(
          'Still waiting on verification for ${refreshedUser.uid}: '
          'pending=${_maskEmail(pendingAuthEmail)}, '
          'current=${_maskEmail(authEmail)}, '
          'emailVerified=${refreshedUser.emailVerified}, '
          'language=${_auth.languageCode ?? '<device-default>'}',
        );
      }
    }

    await privateRef.set(<String, dynamic>{
      'authEmail': authEmail,
      'hasEmail': hasLinkedEmail,
      if (pendingAuthEmail.isNotEmpty && pendingAuthEmail == authEmail)
        'pendingAuthEmail': FieldValue.delete(),
      if (hasLinkedEmail && pendingAuthEmail == authEmail)
        'emailVerifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userRef.set(<String, dynamic>{
      'authEmail': authEmail,
      'hasEmail': hasLinkedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (resolvedUsername.isNotEmpty) {
      await _db
          .collection('usernames')
          .doc(resolvedUsername)
          .set(<String, dynamic>{
            'uid': refreshedUser.uid,
            'username': refreshedUser.displayName ?? resolvedUsername,
            'authEmailAlias': await _resolvePasswordAliasEmail(
              refreshedUser,
              resolvedUsername,
            ),
            'authEmail': authEmail,
            'hasEmail': hasLinkedEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }

    if (pendingAuthEmail.isNotEmpty &&
        pendingAuthEmail == authEmail &&
        hasLinkedEmail) {
      developer.log(
        'Verified email synced to Firestore for ${refreshedUser.uid}: ${_maskEmail(authEmail)}',
        name: 'ProfileEmailUpdate',
      );
      _debugEmailUpdate(
        'Firestore sync complete for ${refreshedUser.uid}: '
        'authEmail=${_maskEmail(authEmail)}, hasEmail=$hasLinkedEmail',
      );
    }

    return refreshedUser;
  }

  bool _isAliasEmail(String email) {
    return email.trim().toLowerCase().endsWith('@queueup.app');
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<String?> _resolveAuthLanguageCode(String uid) async {
    String? preferredLanguageCode;
    try {
      final userSnapshot = await _db.collection('users').doc(uid).get();
      preferredLanguageCode =
          (userSnapshot.data()?['preferredLanguageId'] as String?)
              ?.trim()
              .toLowerCase();
    } catch (_) {}

    preferredLanguageCode ??= (await fetchSelectedLanguageCode())
        ?.trim()
        .toLowerCase();

    final normalized = _normalizeAuthLanguageCode(preferredLanguageCode);
    _debugEmailUpdate(
      'Resolved Firebase Auth email language for $uid: '
      'requested=${preferredLanguageCode ?? '<none>'}, '
      'applied=${normalized ?? '<device-default>'}',
    );
    return normalized;
  }

  String? _normalizeAuthLanguageCode(String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }

    const supportedCodes = <String>{
      'en',
      'hi',
      'bn',
      'gu',
      'kn',
      'ml',
      'mr',
      'pa',
      'ta',
      'te',
      'ur',
    };

    if (supportedCodes.contains(code)) {
      return code;
    }
    return 'en';
  }

  ActionCodeSettings _buildEmailActionSettings() {
    return ActionCodeSettings(
      url: 'https://${_auth.app.options.projectId}.firebaseapp.com/',
      handleCodeInApp: false,
      androidPackageName: 'com.queueup.india',
      androidInstallApp: false,
      iOSBundleId: _safeIosBundleId(),
    );
  }

  String? _safeIosBundleId() {
    try {
      return DefaultFirebaseOptions.ios.iosBundleId;
    } catch (_) {
      return null;
    }
  }

  String _maskEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return '<empty>';
    }
    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return trimmed;
    }
    final local = parts.first;
    final domain = parts.last;
    final visibleLocal = local.length <= 1
        ? '*'
        : local.length == 2
        ? '${local[0]}*'
        : '${local.substring(0, 2)}***';
    return '$visibleLocal@$domain';
  }

  void _debugEmailUpdate(String message) {
    debugPrint('[ProfileEmailUpdate] $message');
  }

  ProfilePreferencesModel _fallbackProfile() {
    return const ProfilePreferencesModel(
      queueName: 'QueuePlayer',
      preferredLanguageCode: 'en',
      avatarUrl: AppImages.avatarHost,
      recoveryEmail: '',
      authEmail: '',
      pendingAuthEmail: '',
      hasLinkedEmail: false,
    );
  }

  Future<Map<String, dynamic>> _buildDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      final info = await deviceInfo.webBrowserInfo;
      return <String, dynamic>{
        'platform': 'web',
        'browserName': info.browserName.name,
        'platformName': info.platform ?? '',
        'userAgent': info.userAgent ?? '',
        'vendor': info.vendor ?? '',
      };
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final info = await deviceInfo.androidInfo;
        return <String, dynamic>{
          'platform': 'android',
          'brand': info.brand,
          'manufacturer': info.manufacturer,
          'model': info.model,
          'device': info.device,
          'product': info.product,
          'androidVersion': info.version.release,
          'sdkInt': info.version.sdkInt,
        };
      case TargetPlatform.iOS:
        final info = await deviceInfo.iosInfo;
        return <String, dynamic>{
          'platform': 'ios',
          'name': info.name,
          'model': info.model,
          'systemName': info.systemName,
          'systemVersion': info.systemVersion,
          'localizedModel': info.localizedModel,
          'identifierForVendor': info.identifierForVendor ?? '',
        };
      default:
        return <String, dynamic>{'platform': defaultTargetPlatform.name};
    }
  }

  static const List<LanguageModel> _fallbackLanguages = <LanguageModel>[
    LanguageModel(
      code: 'en',
      nativeLabel: 'English',
      englishLabel: 'English',
      subtitle: 'Global',
    ),
    LanguageModel(
      code: 'hi',
      nativeLabel: 'हिन्दी',
      englishLabel: 'Hindi',
      subtitle: 'Hindi',
    ),
    LanguageModel(
      code: 'bn',
      nativeLabel: 'বাংলা',
      englishLabel: 'Bengali',
      subtitle: 'Bengali',
    ),
    LanguageModel(
      code: 'mr',
      nativeLabel: 'मराठी',
      englishLabel: 'Marathi',
      subtitle: 'Marathi',
    ),
    LanguageModel(
      code: 'te',
      nativeLabel: 'తెలుగు',
      englishLabel: 'Telugu',
      subtitle: 'Telugu',
    ),
    LanguageModel(
      code: 'ta',
      nativeLabel: 'தமிழ்',
      englishLabel: 'Tamil',
      subtitle: 'Tamil',
    ),
    LanguageModel(
      code: 'gu',
      nativeLabel: 'ગુજરાતી',
      englishLabel: 'Gujarati',
      subtitle: 'Gujarati',
    ),
    LanguageModel(
      code: 'ur',
      nativeLabel: 'اردو',
      englishLabel: 'Urdu',
      subtitle: 'Urdu',
    ),
    LanguageModel(
      code: 'kn',
      nativeLabel: 'ಕನ್ನಡ',
      englishLabel: 'Kannada',
      subtitle: 'Kannada',
    ),
    LanguageModel(
      code: 'or',
      nativeLabel: 'ଓଡ଼ିଆ',
      englishLabel: 'Odia',
      subtitle: 'Odia',
    ),
    LanguageModel(
      code: 'ml',
      nativeLabel: 'മലയാളം',
      englishLabel: 'Malayalam',
      subtitle: 'Malayalam',
    ),
    LanguageModel(
      code: 'pa',
      nativeLabel: 'ਪੰਜਾਬੀ',
      englishLabel: 'Punjabi',
      subtitle: 'Punjabi',
    ),
    LanguageModel(
      code: 'as',
      nativeLabel: 'অসমীয়া',
      englishLabel: 'Assamese',
      subtitle: 'Assamese',
    ),
    LanguageModel(
      code: 'mai',
      nativeLabel: 'मैथिली',
      englishLabel: 'Maithili',
      subtitle: 'Maithili',
    ),
    LanguageModel(
      code: 'sa',
      nativeLabel: 'संस्कृतम्',
      englishLabel: 'Sanskrit',
      subtitle: 'Sanskrit',
    ),
    LanguageModel(
      code: 'gom',
      nativeLabel: 'कोंकणी',
      englishLabel: 'Konkani',
      subtitle: 'Konkani',
    ),
    LanguageModel(
      code: 'ks',
      nativeLabel: 'Kashmiri',
      englishLabel: 'Kashmiri',
      subtitle: 'Kashmiri',
    ),
    LanguageModel(
      code: 'ne',
      nativeLabel: 'नेपाली',
      englishLabel: 'Nepali',
      subtitle: 'Nepali',
    ),
    LanguageModel(
      code: 'sd',
      nativeLabel: 'Sindhi',
      englishLabel: 'Sindhi',
      subtitle: 'Sindhi',
    ),
    LanguageModel(
      code: 'doi',
      nativeLabel: 'डोगरी',
      englishLabel: 'Dogri',
      subtitle: 'Dogri',
    ),
    LanguageModel(
      code: 'mni',
      nativeLabel: 'Manipuri',
      englishLabel: 'Manipuri',
      subtitle: 'Manipuri',
    ),
    LanguageModel(
      code: 'brx',
      nativeLabel: 'Bodo',
      englishLabel: 'Bodo',
      subtitle: 'Bodo',
    ),
    LanguageModel(
      code: 'sat',
      nativeLabel: 'Santali',
      englishLabel: 'Santali',
      subtitle: 'Santali',
    ),
  ];
}
