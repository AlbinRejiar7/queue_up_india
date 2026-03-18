import '../../models/user_model.dart';

class OtpLogEvent {
  const OtpLogEvent({
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;
}

abstract class AuthRepository {
  Future<UserModel> signInWithGoogle();

  Stream<OtpLogEvent> get otpLogs;

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
