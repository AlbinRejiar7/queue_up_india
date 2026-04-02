import '../../models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<bool> isUsernameAvailable({required String username}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return true;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const UserModel(
      id: 'google_001',
      displayName: 'ShadowPlayer',
      avatarUrl: null,
    );
  }

  @override
  Future<UserModel> signInWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return UserModel(
      id: 'password_001',
      displayName: username.trim(),
      avatarUrl: null,
    );
  }

  @override
  Future<UserModel> registerWithUsernamePassword({
    required String username,
    required String password,
    String? avatarUrl,
    String? recoveryEmail,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return UserModel(
      id: 'password_002',
      displayName: username.trim().isEmpty ? 'QueuePlayer' : username.trim(),
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<bool> canSendPasswordReset({required String username}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return username.trim().isNotEmpty;
  }

  @override
  Future<void> sendPasswordReset({required String username}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}
