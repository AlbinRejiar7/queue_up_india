import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_preferences.dart';
import '../viewmodel/auth_view_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthViewModel authViewModel})
    : _authViewModel = authViewModel,
      super(const AuthInitial()) {
    on<AuthGooglePressed>(_onGooglePressed);
    on<AuthGuestPressed>(_onGuestPressed);
    on<AuthResetRequested>(_onResetRequested);
  }

  final AuthViewModel _authViewModel;

  Future<void> _onGooglePressed(
    AuthGooglePressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authViewModel.continueWithGoogle();
      await AppPreferences.setLoggedIn(true);
      emit(AuthSuccess(user: user));
    } catch (_) {
      emit(const AuthError(message: AppStrings.authFailed));
    }
  }

  Future<void> _onGuestPressed(
    AuthGuestPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authViewModel.continueAsGuest();
      await AppPreferences.setLoggedIn(true);
      emit(AuthSuccess(user: user));
    } catch (_) {
      emit(const AuthError(message: AppStrings.authFailed));
    }
  }

  void _onResetRequested(AuthResetRequested event, Emitter<AuthState> emit) {
    emit(const AuthInitial());
  }
}
