import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthViewModel {
  AuthViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  Future<UserModel> continueWithGoogle() {
    return _authRepository.signInWithGoogle();
  }
}
