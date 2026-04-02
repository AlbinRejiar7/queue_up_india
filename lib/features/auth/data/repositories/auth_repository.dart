import '../../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithGoogle();

  Future<bool> isUsernameAvailable({required String username});

  Future<UserModel> signInWithUsernamePassword({
    required String username,
    required String password,
  });

  Future<UserModel> registerWithUsernamePassword({
    required String username,
    required String password,
    String? avatarUrl,
    String? recoveryEmail,
  });

  Future<bool> canSendPasswordReset({required String username});

  Future<void> sendPasswordReset({required String username});
}
