import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppPreferences {
  static const String _loggedInKey = 'is_logged_in';
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _customQuickMessagesKey = 'custom_quick_messages';
  static const String _selectedGameIdKey = 'selected_game_id';
  static const String _selectedLanguageKey = 'selected_language';
  static const String _selectedRankPrefix = 'selected_rank_';
  static const String _pullToRefreshHintPrefix = 'pull_to_refresh_hint_seen_';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
  }

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  static Future<void> markFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  static Future<List<String>> loadCustomQuickMessages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customQuickMessagesKey) ?? <String>[];
  }

  static Future<void> saveCustomQuickMessages(List<String> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customQuickMessagesKey, messages);
  }

  static Future<String?> loadSelectedGameId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedGameIdKey);
  }

  static Future<void> saveSelectedGameId(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedGameIdKey, gameId);
  }

  static Future<String?> loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageKey);
  }

  static Future<void> saveSelectedLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLanguageKey, language);
  }

  static Future<void> clearSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLanguageKey);
  }

  static Future<String?> loadSelectedRank(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_selectedRankPrefix$gameId');
  }

  static Future<void> saveSelectedRank({
    required String gameId,
    required String rank,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_selectedRankPrefix$gameId', rank);
  }

  static Future<void> clearSelectedRank(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_selectedRankPrefix$gameId');
  }

  static Future<bool> hasSeenPullToRefreshHint(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_pullToRefreshHintPrefix$screenKey') ?? false;
  }

  static Future<void> markPullToRefreshHintSeen(String screenKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_pullToRefreshHintPrefix$screenKey', true);
  }
}
