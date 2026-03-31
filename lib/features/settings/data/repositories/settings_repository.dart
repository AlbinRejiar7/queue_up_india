import '../../models/language_model.dart';
import '../../models/profile_preferences_model.dart';

abstract class SettingsRepository {
  Future<List<LanguageModel>> fetchSupportedLanguages();

  Future<String?> fetchSelectedLanguageCode();

  Future<void> saveSelectedLanguageCode(String code);

  Future<bool> isFirstLaunch();

  Future<void> markFirstLaunchComplete();

  Future<ProfilePreferencesModel> fetchProfilePreferences();

  Future<void> saveProfilePreferences(ProfilePreferencesModel preferences);

  Future<void> submitBugReport({required String details});

  Future<void> deleteAccount({required String displayName});
}
