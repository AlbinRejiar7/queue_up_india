import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart';

class RegistrationViewModel {
  RegistrationViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  Future<void> sendOtp(String phoneNumber) {
    return _authRepository.sendOtp(phoneNumber: phoneNumber);
  }

  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? avatarUrl,
    String? displayName,
  }) {
    return _authRepository.verifyOtp(
      phoneNumber: phoneNumber,
      otp: otp,
      avatarUrl: avatarUrl,
      displayName: displayName,
    );
  }

  Future<UserModel> continueWithGoogle({String? avatarUrl}) async {
    final user = await _authRepository.signInWithGoogle();
    return user.copyWith(avatarUrl: avatarUrl ?? user.avatarUrl);
  }
}
