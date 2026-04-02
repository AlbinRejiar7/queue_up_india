import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart';

class RegistrationViewModel {
  RegistrationViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  Future<bool> isUsernameAvailable(String username) {
    return _authRepository.isUsernameAvailable(username: username);
  }

  Future<UserModel> signInWithUsernamePassword({
    required String username,
    required String password,
  }) {
    return _authRepository.signInWithUsernamePassword(
      username: username,
      password: password,
    );
  }

  Future<UserModel> registerWithUsernamePassword({
    required String username,
    required String password,
    String? avatarUrl,
    String? recoveryEmail,
  }) {
    return _authRepository.registerWithUsernamePassword(
      username: username,
      password: password,
      avatarUrl: avatarUrl,
      recoveryEmail: recoveryEmail,
    );
  }

  Future<UserModel> continueWithGoogle({String? avatarUrl}) async {
    final user = await _authRepository.signInWithGoogle();
    return user.copyWith(avatarUrl: avatarUrl ?? user.avatarUrl);
  }

  Future<bool> canSendPasswordReset(String username) {
    return _authRepository.canSendPasswordReset(username: username);
  }

  Future<void> sendPasswordReset(String username) {
    return _authRepository.sendPasswordReset(username: username);
  }
}
