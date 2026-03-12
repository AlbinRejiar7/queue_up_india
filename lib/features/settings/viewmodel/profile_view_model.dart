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

  Future<void> savePreferences(ProfilePreferencesModel preferences) {
    return _settingsRepository.saveProfilePreferences(preferences);
  }
}
