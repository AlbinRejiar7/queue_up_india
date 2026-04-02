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
      final Object raw = error.message;
      if (raw is String && raw.trim().isNotEmpty) {
        final String lowered = raw.toLowerCase();
        if (lowered.contains('google') && lowered.contains('cancel')) {
          return AppStrings.googleSignInCancelled;
        }
        if (lowered.contains('username') && lowered.contains('taken')) {
          return AppStrings.usernameTaken;
        }
        if (lowered.contains('no linked email')) {
          return AppStrings.forgotPasswordDisabled;
        }
        if (lowered.contains('recovery email') && lowered.contains('invalid')) {
          return AppStrings.invalidRecoveryEmail;
        }
        if (lowered.contains('linked email') && lowered.contains('invalid')) {
          return AppStrings.linkedEmailInvalid;
        }
        if (lowered.contains('already set')) {
          return AppStrings.linkedEmailAlreadySet;
        }
        return raw;
      }
    }

    return fallback;
  }

  static String? _fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AppStrings.invalidRecoveryEmail;
      case 'email-already-in-use':
        return AppStrings.usernameTaken;
      case 'wrong-password':
      case 'invalid-login-credentials':
        return AppStrings.loginFailed;
      case 'weak-password':
        return AppStrings.passwordTooShort;
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
      case 'requires-recent-login':
      case 'user-mismatch':
        return AppStrings.requiresRecentLogin;
      case 'user-disabled':
        return AppStrings.userDisabled;
      case 'user-not-found':
        return AppStrings.userNotFound;
      default:
        return null;
    }
  }
}
