import '../../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithGoogle();

  Future<UserModel> signInAsGuest();

  Future<void> sendOtp({required String phoneNumber});

  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? avatarUrl,
    String? displayName,
  });
}
