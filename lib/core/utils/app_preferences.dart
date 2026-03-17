import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppPreferences {
  static const String _loggedInKey = 'is_logged_in';
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _customQuickMessagesKey = 'custom_quick_messages';
  static const String _otpVerificationIdKey = 'otp_verification_id';
  static const String _otpResendTokenKey = 'otp_resend_token';
  static const String _otpSentAtKey = 'otp_sent_at_ms';
  static const String _otpPhoneKey = 'otp_phone_number';

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

  static Future<void> saveOtpSession({
    required String verificationId,
    required String phoneNumber,
    required DateTime sentAt,
    int? forceResendingToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_otpVerificationIdKey, verificationId);
    await prefs.setString(_otpPhoneKey, phoneNumber);
    await prefs.setInt(_otpSentAtKey, sentAt.millisecondsSinceEpoch);
    if (forceResendingToken != null) {
      await prefs.setInt(_otpResendTokenKey, forceResendingToken);
    } else {
      await prefs.remove(_otpResendTokenKey);
    }
  }

  static Future<OtpSession?> loadOtpSession() async {
    final prefs = await SharedPreferences.getInstance();
    final verificationId = prefs.getString(_otpVerificationIdKey);
    final phoneNumber = prefs.getString(_otpPhoneKey);
    final sentAtMs = prefs.getInt(_otpSentAtKey);
    if (verificationId == null || phoneNumber == null || sentAtMs == null) {
      return null;
    }
    final resendToken = prefs.getInt(_otpResendTokenKey);
    return OtpSession(
      verificationId: verificationId,
      phoneNumber: phoneNumber,
      sentAt: DateTime.fromMillisecondsSinceEpoch(sentAtMs),
      forceResendingToken: resendToken,
    );
  }

  static Future<void> clearOtpSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_otpVerificationIdKey);
    await prefs.remove(_otpResendTokenKey);
    await prefs.remove(_otpSentAtKey);
    await prefs.remove(_otpPhoneKey);
  }
}

class OtpSession {
  const OtpSession({
    required this.verificationId,
    required this.phoneNumber,
    required this.sentAt,
    this.forceResendingToken,
  });

  final String verificationId;
  final String phoneNumber;
  final DateTime sentAt;
  final int? forceResendingToken;
}
