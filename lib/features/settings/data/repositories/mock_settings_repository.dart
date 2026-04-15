import '../../models/language_model.dart';
import '../../models/profile_preferences_model.dart';
import '../../../../core/constants/app_images.dart';
import 'settings_repository.dart';

class MockSettingsRepository implements SettingsRepository {
  bool _isFirstLaunch = true;
  String? _selectedCode;
  ProfilePreferencesModel _preferences = const ProfilePreferencesModel(
    queueName: 'ShadowPlayer',
    preferredLanguageCode: 'en',
    avatarUrl: AppImages.avatarHost,
    authEmail: '',
    pendingAuthEmail: '',
    hasLinkedEmail: false,
  );

  static const List<LanguageModel> _languages = <LanguageModel>[
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

  @override
  Future<List<LanguageModel>> fetchSupportedLanguages() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _languages;
  }

  @override
  Future<String?> fetchSelectedLanguageCode() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _selectedCode;
  }

  @override
  Future<bool> isFirstLaunch() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _isFirstLaunch;
  }

  @override
  Future<void> markFirstLaunchComplete() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _isFirstLaunch = false;
  }

  @override
  Future<void> saveSelectedLanguageCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _selectedCode = code;
  }

  @override
  Future<ProfilePreferencesModel> fetchProfilePreferences() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return _preferences;
  }

  @override
  Future<bool> isUsernameAvailable({required String username}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final normalized = _normalizeUsername(username);
    final currentNormalized = _normalizeUsername(_preferences.queueName);
    return normalized.isNotEmpty && normalized != currentNormalized;
  }

  @override
  Future<void> saveProfilePreferences(
    ProfilePreferencesModel preferences,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (_preferences.queueName != preferences.queueName) {
      _preferences = preferences.copyWith(
        lastUsernameChangedAt: DateTime.now(),
      );
    } else {
      _preferences = preferences;
    }
  }

  @override
  Future<void> requestAuthEmailUpdate({
    required String username,
    required String newEmail,
    required String currentPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (currentPassword.trim().isEmpty) {
      throw StateError('Current password is required.');
    }
    _preferences = _preferences.copyWith(
      pendingAuthEmail: newEmail.trim().toLowerCase(),
    );
  }

  @override
  Future<void> updatePassword({
    required String username,
    required String newPassword,
    String? currentPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }

  @override
  Future<void> submitBugReport({required String details}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
  }

  @override
  Future<void> deleteAccount({required String displayName}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _preferences = const ProfilePreferencesModel(
      queueName: '',
      preferredLanguageCode: '',
      avatarUrl: AppImages.avatarHost,
      authEmail: '',
      pendingAuthEmail: '',
      hasLinkedEmail: false,
    );
  }

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }
}
