import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../viewmodel/registration_view_model.dart';
import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({required RegistrationViewModel registrationViewModel})
    : _registrationViewModel = registrationViewModel,
      super(const RegistrationInitial()) {
    on<RegistrationUsernameChanged>(_onUsernameChanged);
    on<RegistrationPasswordResetUsernameChanged>(
      _onPasswordResetUsernameChanged,
    );
    on<RegistrationUsernameCheckRequested>(_onUsernameCheckRequested);
    on<RegistrationPasswordResetAvailabilityRequested>(
      _onPasswordResetAvailabilityRequested,
    );
    on<RegistrationPasswordChanged>(_onPasswordChanged);
    on<RegistrationConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<RegistrationRecoveryEmailChanged>(_onRecoveryEmailChanged);
    on<RegistrationAvatarSelected>(_onAvatarSelected);
    on<RegistrationSubmitPressed>(_onSubmitPressed);
    on<RegistrationGooglePressed>(_onGooglePressed);
    on<RegistrationForgotPasswordPressed>(_onForgotPasswordPressed);
    on<RegistrationPasswordResetNoticeConsumed>(_onPasswordResetNoticeConsumed);
    on<RegistrationPasswordResetFlowResetRequested>(
      _onPasswordResetFlowResetRequested,
    );
    on<RegistrationResetRequested>(_onResetRequested);
    on<RegistrationModeChanged>(_onModeChanged);
    on<RegistrationLegalAcceptedChanged>(_onLegalAcceptedChanged);
  }

  final RegistrationViewModel _registrationViewModel;
  Timer? _usernameDebounce;
  Timer? _passwordResetDebounce;

  void _onUsernameChanged(
    RegistrationUsernameChanged event,
    Emitter<RegistrationState> emit,
  ) {
    final normalized = _normalizeUsername(event.username);
    final status = normalized.length < 3
        ? UsernameCheckStatus.invalid
        : (state.data.isRegistration
              ? UsernameCheckStatus.unknown
              : state.data.usernameStatus);

    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          username: event.username,
          usernameStatus: status,
          isUsernameChecking: false,
          isSubmitting: false,
          didCompleteRegistration: false,
          showPasswordResetNotice: false,
        ),
      ),
    );

    _usernameDebounce?.cancel();
    if (status == UsernameCheckStatus.invalid) {
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () {
      if (state.data.isRegistration) {
        add(RegistrationUsernameCheckRequested(username: event.username));
      }
    });
  }

  void _onPasswordResetUsernameChanged(
    RegistrationPasswordResetUsernameChanged event,
    Emitter<RegistrationState> emit,
  ) {
    final normalized = _normalizeUsername(event.username);

    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          passwordResetUsername: event.username,
          canResetPassword: false,
          isCheckingPasswordReset: false,
          isSubmitting: false,
          showPasswordResetNotice: false,
        ),
      ),
    );

    _passwordResetDebounce?.cancel();
    if (normalized.length < 3) {
      return;
    }

    _passwordResetDebounce = Timer(const Duration(milliseconds: 450), () {
      add(
        RegistrationPasswordResetAvailabilityRequested(
          username: event.username,
        ),
      );
    });
  }

  Future<void> _onUsernameCheckRequested(
    RegistrationUsernameCheckRequested event,
    Emitter<RegistrationState> emit,
  ) async {
    if (!state.data.isRegistration) {
      return;
    }

    final requestedNormalized = _normalizeUsername(event.username);
    final currentNormalized = _normalizeUsername(state.data.username);
    if (requestedNormalized != currentNormalized) {
      return;
    }

    if (requestedNormalized.length < 3) {
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            usernameStatus: UsernameCheckStatus.invalid,
            isUsernameChecking: false,
          ),
        ),
      );
      return;
    }

    emit(
      RegistrationSuccess(data: state.data.copyWith(isUsernameChecking: true)),
    );

    try {
      final available = await _registrationViewModel.isUsernameAvailable(
        event.username,
      );
      final stillSame =
          _normalizeUsername(state.data.username) == requestedNormalized;
      if (!stillSame) {
        return;
      }

      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            isUsernameChecking: false,
            usernameStatus: available
                ? UsernameCheckStatus.available
                : UsernameCheckStatus.taken,
          ),
        ),
      );
    } catch (_) {
      emit(
        RegistrationError(
          data: state.data.copyWith(isUsernameChecking: false),
          message: AppStrings.usernameCheckFailed,
        ),
      );
    }
  }

  Future<void> _onPasswordResetAvailabilityRequested(
    RegistrationPasswordResetAvailabilityRequested event,
    Emitter<RegistrationState> emit,
  ) async {
    if (state.data.isRegistration) {
      return;
    }

    final requestedNormalized = _normalizeUsername(event.username);
    final currentNormalized = state.data.normalizedPasswordResetUsername;
    if (requestedNormalized != currentNormalized) {
      return;
    }

    if (requestedNormalized.length < 3) {
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            canResetPassword: false,
            isCheckingPasswordReset: false,
          ),
        ),
      );
      return;
    }

    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          isCheckingPasswordReset: true,
          canResetPassword: false,
        ),
      ),
    );

    try {
      final canReset = await _registrationViewModel.canSendPasswordReset(
        event.username,
      );
      final stillSame =
          state.data.normalizedPasswordResetUsername == requestedNormalized;
      if (!stillSame) {
        return;
      }

      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            canResetPassword: canReset,
            isCheckingPasswordReset: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            canResetPassword: false,
            isCheckingPasswordReset: false,
          ),
        ),
      );
    }
  }

  void _onPasswordChanged(
    RegistrationPasswordChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          password: event.password,
          isSubmitting: false,
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  void _onConfirmPasswordChanged(
    RegistrationConfirmPasswordChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          confirmPassword: event.confirmPassword,
          isSubmitting: false,
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  void _onRecoveryEmailChanged(
    RegistrationRecoveryEmailChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          recoveryEmail: event.recoveryEmail,
          isSubmitting: false,
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  void _onAvatarSelected(
    RegistrationAvatarSelected event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          selectedAvatarUrl: event.avatarUrl,
          isSubmitting: false,
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  Future<void> _onSubmitPressed(
    RegistrationSubmitPressed event,
    Emitter<RegistrationState> emit,
  ) async {
    final data = state.data;
    if (!data.canSubmit) {
      emit(
        RegistrationError(data: data, message: _submitValidationMessage(data)),
      );
      return;
    }

    emit(
      RegistrationLoading(
        data: data.copyWith(isSubmitting: true, didCompleteRegistration: false),
      ),
    );

    try {
      if (data.isRegistration) {
        await _registrationViewModel.registerWithUsernamePassword(
          username: data.username.trim(),
          password: data.password,
          avatarUrl: data.selectedAvatarUrl,
          recoveryEmail: data.recoveryEmail.trim().isEmpty
              ? null
              : data.recoveryEmail.trim(),
        );
      } else {
        await _registrationViewModel.signInWithUsernamePassword(
          username: data.username.trim(),
          password: data.password,
        );
      }
      await AppPreferences.setLoggedIn(true);
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            isSubmitting: false,
            didCompleteRegistration: true,
            showPasswordResetNotice: false,
            usernameStatus: data.isRegistration
                ? UsernameCheckStatus.available
                : state.data.usernameStatus,
          ),
        ),
      );
    } catch (error) {
      emit(
        RegistrationError(
          data: state.data.copyWith(isSubmitting: false),
          message: AuthErrorMapper.message(
            error,
            fallback: data.isRegistration
                ? AppStrings.createAccountFailed
                : AppStrings.loginFailed,
          ),
        ),
      );
    }
  }

  Future<void> _onGooglePressed(
    RegistrationGooglePressed event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(
      RegistrationLoading(
        data: state.data.copyWith(
          isSubmitting: true,
          didCompleteRegistration: false,
        ),
      ),
    );

    try {
      await _registrationViewModel.continueWithGoogle(
        avatarUrl: state.data.isRegistration
            ? state.data.selectedAvatarUrl
            : null,
      );
      await AppPreferences.setLoggedIn(true);
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            isSubmitting: false,
            didCompleteRegistration: true,
            showPasswordResetNotice: false,
          ),
        ),
      );
    } catch (error) {
      emit(
        RegistrationError(
          data: state.data.copyWith(isSubmitting: false),
          message: AuthErrorMapper.message(
            error,
            fallback: AppStrings.authFailed,
          ),
        ),
      );
    }
  }

  Future<void> _onForgotPasswordPressed(
    RegistrationForgotPasswordPressed event,
    Emitter<RegistrationState> emit,
  ) async {
    final data = state.data;
    if (data.isRegistration) {
      return;
    }
    if (data.normalizedPasswordResetUsername.length < 3) {
      emit(
        RegistrationError(
          data: data,
          message: AppStrings.forgotPasswordEnterUsername,
        ),
      );
      return;
    }
    if (!data.canResetPassword) {
      emit(
        RegistrationError(
          data: data,
          message: AppStrings.forgotPasswordDisabled,
        ),
      );
      return;
    }

    emit(
      RegistrationLoading(
        data: data.copyWith(
          isSubmitting: true,
          didCompleteRegistration: false,
          showPasswordResetNotice: false,
        ),
      ),
    );

    try {
      await _registrationViewModel.sendPasswordReset(
        data.passwordResetUsername.trim(),
      );
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            isSubmitting: false,
            showPasswordResetNotice: true,
          ),
        ),
      );
    } catch (error) {
      emit(
        RegistrationError(
          data: state.data.copyWith(isSubmitting: false),
          message: AuthErrorMapper.message(
            error,
            fallback: AppStrings.forgotPasswordFailed,
          ),
        ),
      );
    }
  }

  void _onPasswordResetNoticeConsumed(
    RegistrationPasswordResetNoticeConsumed event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(showPasswordResetNotice: false),
      ),
    );
  }

  void _onPasswordResetFlowResetRequested(
    RegistrationPasswordResetFlowResetRequested event,
    Emitter<RegistrationState> emit,
  ) {
    _passwordResetDebounce?.cancel();
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          passwordResetUsername: '',
          canResetPassword: false,
          isCheckingPasswordReset: false,
          isSubmitting: false,
          showPasswordResetNotice: false,
        ),
      ),
    );
  }

  void _onResetRequested(
    RegistrationResetRequested event,
    Emitter<RegistrationState> emit,
  ) {
    _usernameDebounce?.cancel();
    _passwordResetDebounce?.cancel();
    emit(const RegistrationSuccess(data: RegistrationViewData.initial()));
  }

  void _onModeChanged(
    RegistrationModeChanged event,
    Emitter<RegistrationState> emit,
  ) {
    if (state.data.mode == event.mode) {
      return;
    }
    _usernameDebounce?.cancel();
    _passwordResetDebounce?.cancel();
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          mode: event.mode,
          password: '',
          confirmPassword: '',
          passwordResetUsername: '',
          recoveryEmail: event.mode == RegistrationMode.login
              ? ''
              : state.data.recoveryEmail,
          usernameStatus: event.mode == RegistrationMode.register
              ? state.data.usernameStatus
              : UsernameCheckStatus.unknown,
          isUsernameChecking: false,
          canResetPassword: false,
          isCheckingPasswordReset: false,
          isSubmitting: false,
          didCompleteRegistration: false,
          showPasswordResetNotice: false,
          acceptedLegal: event.mode == RegistrationMode.login
              ? false
              : state.data.acceptedLegal,
          clearAvatar: event.mode == RegistrationMode.login,
        ),
      ),
    );
  }

  void _onLegalAcceptedChanged(
    RegistrationLegalAcceptedChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          acceptedLegal: event.accepted,
          isSubmitting: false,
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  String _submitValidationMessage(RegistrationViewData data) {
    if (!data.hasUsername) {
      return AppStrings.usernameRequired;
    }
    if (data.normalizedUsername.length < 3) {
      return AppStrings.usernameInvalid;
    }
    if (!data.hasValidPassword) {
      return AppStrings.passwordTooShort;
    }
    if (data.isRegistration) {
      if (data.usernameStatus == UsernameCheckStatus.taken) {
        return AppStrings.usernameTaken;
      }
      if (data.isUsernameChecking || !data.isUsernameAvailable) {
        return AppStrings.usernameCheckFailed;
      }
      if (!data.doPasswordsMatch) {
        return AppStrings.passwordMismatch;
      }
      if (!data.hasSelectedAvatar) {
        return AppStrings.avatarRequired;
      }
      if (!data.isRecoveryEmailValid) {
        return AppStrings.invalidRecoveryEmail;
      }
      if (!data.acceptedLegal) {
        return AppStrings.acceptLegalRequired;
      }
    }
    return data.isRegistration
        ? AppStrings.createAccountFailed
        : AppStrings.loginFailed;
  }

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  @override
  Future<void> close() {
    _usernameDebounce?.cancel();
    _passwordResetDebounce?.cancel();
    return super.close();
  }
}
