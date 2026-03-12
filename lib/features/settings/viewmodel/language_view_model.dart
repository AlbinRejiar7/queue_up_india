import '../data/repositories/settings_repository.dart';
import '../models/language_model.dart';

class LanguageViewModel {
  LanguageViewModel({required SettingsRepository settingsRepository})
    : _settingsRepository = settingsRepository;

  final SettingsRepository _settingsRepository;

  Future<List<LanguageModel>> loadLanguages() {
    return _settingsRepository.fetchSupportedLanguages();
  }

  Future<String?> loadSelectedLanguageCode() {
    return _settingsRepository.fetchSelectedLanguageCode();
  }

  Future<bool> isFirstLaunch() {
    return _settingsRepository.isFirstLaunch();
  }

  Future<void> persistLanguageSelection(String code) async {
    await _settingsRepository.saveSelectedLanguageCode(code);
    await _settingsRepository.markFirstLaunchComplete();
  }
}
