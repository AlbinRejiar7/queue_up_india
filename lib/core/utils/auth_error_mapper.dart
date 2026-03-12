import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_strings.dart';

class AuthErrorMapper {
  static String message(
    Object error, {
    String fallback = AppStrings.authFailed,
  }) {
    if (error is FirebaseAuthException) {
      return _fromCode(error.code) ?? fallback;
    }

    if (error is TimeoutException) {
      return AppStrings.networkTimeout;
    }

    if (error is StateError) {
      final Object? raw = error.message;
      if (raw is String && raw.trim().isNotEmpty) {
        final String lowered = raw.toLowerCase();
        if (lowered.contains('google') && lowered.contains('cancel')) {
          return AppStrings.googleSignInCancelled;
        }
        if (lowered.contains('username') && lowered.contains('taken')) {
          return AppStrings.usernameTaken;
        }
        return raw;
      }
    }

    return fallback;
  }

  static String? _fromCode(String code) {
    switch (code) {
      case 'invalid-phone-number':
      case 'missing-phone-number':
        return AppStrings.invalidPhoneNumber;
      case 'invalid-verification-code':
        return AppStrings.invalidOtp;
      case 'invalid-verification-id':
      case 'session-expired':
      case 'code-expired':
        return AppStrings.otpExpired;
      case 'too-many-requests':
      case 'quota-exceeded':
        return AppStrings.authTooManyRequests;
      case 'network-request-failed':
        return AppStrings.networkError;
      case 'operation-not-allowed':
        return AppStrings.authProviderDisabled;
      case 'app-not-authorized':
        return AppStrings.deviceNotAuthorized;
      case 'credential-already-in-use':
        return AppStrings.credentialInUse;
      case 'account-exists-with-different-credential':
        return AppStrings.googleAccountExists;
      case 'invalid-credential':
        return AppStrings.invalidCredential;
      case 'user-disabled':
        return AppStrings.userDisabled;
      case 'user-not-found':
        return AppStrings.userNotFound;
      default:
        return null;
    }
  }
}
