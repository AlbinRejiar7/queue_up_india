import '../../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithGoogle();

  Future<void> sendOtp({required String phoneNumber});

  Future<bool> isPhoneRegistered({required String phoneNumber});

  Future<bool> isUsernameAvailable({required String username});

  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? avatarUrl,
    String? displayName,
  });
}
