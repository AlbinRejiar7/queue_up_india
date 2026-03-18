import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppPreferences {
  static const String _loggedInKey = 'is_logged_in';
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _customQuickMessagesKey = 'custom_quick_messages';
  static const String _otpVerificationIdKey = 'otp_verification_id';
  static const String _otpResendTokenKey = 'otp_resend_token';
  static const String _otpSentAtKey = 'otp_sent_at_ms';
  static const String _otpPhoneKey = 'otp_phone_number';
  static const String _otpPendingDisplayNameKey =
      'otp_pending_display_name';
  static const String _otpPendingAvatarKey = 'otp_pending_avatar';
  static const String _otpPendingIsRegistrationKey =
      'otp_pending_is_registration';

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
    final sentAtMs = sentAt.millisecondsSinceEpoch;
    await prefs.setString(_otpVerificationIdKey, verificationId);
    await prefs.setString(_otpPhoneKey, phoneNumber);
    await prefs.setInt(_otpSentAtKey, sentAtMs);
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

  static Future<void> saveOtpPendingProfile({
    String? displayName,
    String? avatarUrl,
    required bool isRegistration,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (displayName != null && displayName.trim().isNotEmpty) {
      await prefs.setString(_otpPendingDisplayNameKey, displayName.trim());
    } else {
      await prefs.remove(_otpPendingDisplayNameKey);
    }
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      await prefs.setString(_otpPendingAvatarKey, avatarUrl.trim());
    } else {
      await prefs.remove(_otpPendingAvatarKey);
    }
    await prefs.setBool(_otpPendingIsRegistrationKey, isRegistration);
  }

  static Future<OtpPendingProfile?> loadOtpPendingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final isRegistration =
        prefs.getBool(_otpPendingIsRegistrationKey) ?? false;
    final displayName = prefs.getString(_otpPendingDisplayNameKey);
    final avatarUrl = prefs.getString(_otpPendingAvatarKey);
    if (displayName == null && avatarUrl == null && !isRegistration) {
      return null;
    }
    return OtpPendingProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
      isRegistration: isRegistration,
    );
  }

  static Future<void> clearOtpPendingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_otpPendingDisplayNameKey);
    await prefs.remove(_otpPendingAvatarKey);
    await prefs.remove(_otpPendingIsRegistrationKey);
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

class OtpPendingProfile {
  const OtpPendingProfile({
    required this.displayName,
    required this.avatarUrl,
    required this.isRegistration,
  });

  final String? displayName;
  final String? avatarUrl;
  final bool isRegistration;
}
