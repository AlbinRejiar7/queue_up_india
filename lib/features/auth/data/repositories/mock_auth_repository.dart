import 'dart:async';

import '../../models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Stream<OtpLogEvent> get otpLogs =>
      const Stream<OtpLogEvent>.empty();

  @override
  Future<void> sendOtp({required String phoneNumber}) async {
    // TODO: Implement FirebaseAuth here
    await Future<void>.delayed(const Duration(milliseconds: 650));
  }

  @override
  Future<bool> isPhoneRegistered({required String phoneNumber}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return true;
  }

  @override
  Future<bool> isUsernameAvailable({required String username}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return true;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    // TODO: Implement FirebaseAuth here
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const UserModel(
      id: 'google_001',
      displayName: 'ShadowPlayer',
      avatarUrl: null,
    );
  }

  @override
  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? avatarUrl,
    String? displayName,
  }) async {
    // TODO: Implement FirebaseAuth here
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return UserModel(
      id: 'phone_001',
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : 'QueuePlayer',
      avatarUrl: avatarUrl,
    );
  }
}
