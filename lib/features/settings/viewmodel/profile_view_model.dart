import '../data/repositories/settings_repository.dart';
import '../models/language_model.dart';
import '../models/profile_preferences_model.dart';

class ProfileViewModel {
  ProfileViewModel({required SettingsRepository settingsRepository})
    : _settingsRepository = settingsRepository;

  final SettingsRepository _settingsRepository;

  Future<List<LanguageModel>> loadLanguages() {
    return _settingsRepository.fetchSupportedLanguages();
  }

  Future<ProfilePreferencesModel> loadPreferences() {
    return _settingsRepository.fetchProfilePreferences();
  }

  Future<bool> isUsernameAvailable(String username) {
    return _settingsRepository.isUsernameAvailable(username: username);
  }

  Future<void> savePreferences(ProfilePreferencesModel preferences) {
    return _settingsRepository.saveProfilePreferences(preferences);
  }

  Future<void> requestAuthEmailUpdate({
    required String username,
    required String newEmail,
    required String currentPassword,
  }) {
    return _settingsRepository.requestAuthEmailUpdate(
      username: username,
      newEmail: newEmail,
      currentPassword: currentPassword,
    );
  }

  Future<void> updatePassword({
    required String username,
    required String newPassword,
    String? currentPassword,
  }) {
    return _settingsRepository.updatePassword(
      username: username,
      newPassword: newPassword,
      currentPassword: currentPassword,
    );
  }

  Future<void> submitBugReport({required String details}) {
    return _settingsRepository.submitBugReport(details: details);
  }

  Future<void> deleteAccount({required String displayName}) {
    return _settingsRepository.deleteAccount(displayName: displayName);
  }
}
