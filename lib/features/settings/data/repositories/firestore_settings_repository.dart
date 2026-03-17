import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_images.dart';
import '../../models/language_model.dart';
import '../../models/profile_preferences_model.dart';
import 'settings_repository.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
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
      await _db.collection('users').doc(user.uid).set(
        <String, dynamic>{
          'preferredLanguageId': code,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
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

    final snapshot = await _db.collection('users').doc(user.uid).get();
    final data = snapshot.data() ?? <String, dynamic>{};
    final queueName =
        (data['displayName'] as String?) ?? user.displayName ?? 'QueuePlayer';
    final preferredLanguageCode =
        (data['preferredLanguageId'] as String?) ??
        await fetchSelectedLanguageCode() ??
        'en';
    final avatarUrl =
        (data['avatarUrl'] as String?) ?? AppImages.avatarHost;

    return ProfilePreferencesModel(
      queueName: queueName,
      preferredLanguageCode: preferredLanguageCode,
      avatarUrl: avatarUrl,
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

    await _db.collection('users').doc(user.uid).set(
      <String, dynamic>{
        'displayName': preferences.queueName,
        'preferredLanguageId': preferences.preferredLanguageCode,
        'avatarUrl': preferences.avatarUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final trimmedName = preferences.queueName.trim();
    if (trimmedName.isNotEmpty &&
        (user.displayName ?? '').trim() != trimmedName) {
      try {
        await user.updateDisplayName(trimmedName);
        await user.reload();
      } catch (_) {}
    }
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

  ProfilePreferencesModel _fallbackProfile() {
    return const ProfilePreferencesModel(
      queueName: 'QueuePlayer',
      preferredLanguageCode: 'en',
      avatarUrl: AppImages.avatarHost,
    );
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
