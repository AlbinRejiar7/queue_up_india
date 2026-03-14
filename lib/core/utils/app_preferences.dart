import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppPreferences {
  static const String _loggedInKey = 'is_logged_in';
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _customQuickMessagesKey = 'custom_quick_messages';

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
}
