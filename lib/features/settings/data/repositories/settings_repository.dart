import '../../models/language_model.dart';
import '../../models/profile_preferences_model.dart';

abstract class SettingsRepository {
  Future<List<LanguageModel>> fetchSupportedLanguages();

  Future<String?> fetchSelectedLanguageCode();

  Future<void> saveSelectedLanguageCode(String code);

  Future<bool> isFirstLaunch();

  Future<void> markFirstLaunchComplete();

  Future<ProfilePreferencesModel> fetchProfilePreferences();

  Future<bool> isUsernameAvailable({required String username});

  Future<void> saveProfilePreferences(ProfilePreferencesModel preferences);

  Future<void> requestAuthEmailUpdate({
    required String username,
    required String newEmail,
    required String currentPassword,
  });

  Future<void> updatePassword({
    required String username,
    required String newPassword,
    String? currentPassword,
  });

  Future<void> submitBugReport({required String details});

  Future<void> deleteAccount({required String displayName});
}
