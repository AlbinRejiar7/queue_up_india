import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/country_codes.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../viewmodel/registration_view_model.dart';
import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({required RegistrationViewModel registrationViewModel})
    : _registrationViewModel = registrationViewModel,
      super(const RegistrationInitial()) {
    on<RegistrationPhoneChanged>(_onPhoneChanged);
    on<RegistrationUsernameChanged>(_onUsernameChanged);
    on<RegistrationUsernameCheckRequested>(_onUsernameCheckRequested);
    on<RegistrationOtpChanged>(_onOtpChanged);
    on<RegistrationAvatarSelected>(_onAvatarSelected);
    on<RegistrationCountryCodeChanged>(_onCountryCodeChanged);
    on<RegistrationSendOtpPressed>(_onSendOtpPressed);
    on<RegistrationVerifyOtpPressed>(_onVerifyOtpPressed);
    on<RegistrationGooglePressed>(_onGooglePressed);
    on<RegistrationNavigationConsumed>(_onNavigationConsumed);
    on<RegistrationResetRequested>(_onResetRequested);
    on<RegistrationModeChanged>(_onModeChanged);
  }

  final RegistrationViewModel _registrationViewModel;
  Timer? _usernameDebounce;

  void _onPhoneChanged(
    RegistrationPhoneChanged event,
    Emitter<RegistrationState> emit,
  ) {
    final sanitized = event.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final resetOtp = sanitized != state.data.phoneNumber;
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          phoneNumber: sanitized,
          otp: resetOtp ? '' : state.data.otp,
          isOtpSent: resetOtp ? false : state.data.isOtpSent,
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  void _onUsernameChanged(
    RegistrationUsernameChanged event,
    Emitter<RegistrationState> emit,
  ) {
    final normalized = _normalizeUsername(event.username);
    final status = normalized.length < 3
        ? UsernameCheckStatus.invalid
        : UsernameCheckStatus.unknown;
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          username: event.username,
          usernameStatus: status,
          isUsernameChecking: false,
          didCompleteRegistration: false,
        ),
      ),
    );

    _usernameDebounce?.cancel();
    if (!state.data.isRegistration) {
      return;
    }
    if (status == UsernameCheckStatus.invalid) {
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () {
      add(
        RegistrationUsernameCheckRequested(username: event.username),
      );
    });
  }

  void _onOtpChanged(
    RegistrationOtpChanged event,
    Emitter<RegistrationState> emit,
  ) {
    final sanitized = event.otp.replaceAll(RegExp(r'[^0-9]'), '');
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          otp: sanitized,
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
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  void _onCountryCodeChanged(
    RegistrationCountryCodeChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          selectedCountryCodeId: event.countryCodeId,
          isOtpSent: false,
          otp: '',
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  Future<void> _onUsernameCheckRequested(
    RegistrationUsernameCheckRequested event,
    Emitter<RegistrationState> emit,
  ) async {
    if (!state.data.isRegistration) {
      return;
    }
    final currentNormalized = _normalizeUsername(state.data.username);
    final requestedNormalized = _normalizeUsername(event.username);
    if (currentNormalized != requestedNormalized) {
      return;
    }

    emit(
      RegistrationSuccess(
        data: state.data.copyWith(isUsernameChecking: true),
      ),
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

  Future<void> _onSendOtpPressed(
    RegistrationSendOtpPressed event,
    Emitter<RegistrationState> emit,
  ) async {
    if (!state.data.canSendOtp) {
      final String message;
      if (state.data.isRegistration &&
          state.data.usernameStatus == UsernameCheckStatus.taken) {
        message = AppStrings.usernameTaken;
      } else if (state.data.isRegistration &&
          state.data.usernameStatus == UsernameCheckStatus.invalid) {
        message = AppStrings.usernameInvalid;
      } else if (state.data.isRegistration &&
          !state.data.isUsernameAvailable) {
        message = AppStrings.usernameCheckFailed;
      } else if (state.data.isRegistration && !state.data.hasUsername) {
        message = AppStrings.usernameRequired;
      } else if (state.data.phoneNumber.trim().isEmpty) {
        message = AppStrings.invalidPhoneNumber;
      } else {
        message = AppStrings.invalidPhoneNumber;
      }
      emit(
        RegistrationError(
          data: state.data,
          message: message,
        ),
      );
      return;
    }

    emit(RegistrationLoading(data: state.data));
    try {
      final fullPhone = _fullPhoneNumber(state.data);
      developer.log(
        'OTP login send requested',
        name: 'RegistrationBloc',
        error: _maskPhone(fullPhone),
      );
      if (!state.data.isRegistration) {
        final registered =
            await _registrationViewModel.isPhoneRegistered(fullPhone);
        if (!registered) {
          developer.log(
            'OTP blocked: phone not registered',
            name: 'RegistrationBloc',
            error: _maskPhone(fullPhone),
          );
          emit(
            RegistrationError(
              data: state.data,
              message: AppStrings.phoneNotRegistered,
            ),
          );
          return;
        }
      }
      await _registrationViewModel.sendOtp(fullPhone);
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            isOtpSent: true,
            otp: '',
            didCompleteRegistration: false,
          ),
        ),
      );
    } catch (error) {
      if (error.toString().toLowerCase().contains('not registered')) {
        emit(
          RegistrationError(
            data: state.data,
            message: AppStrings.phoneNotRegistered,
          ),
        );
        return;
      }
      emit(
        RegistrationError(
          data: state.data,
          message: AuthErrorMapper.message(
            error,
            fallback: AppStrings.otpSendFailed,
          ),
        ),
      );
    }
  }

  Future<void> _onVerifyOtpPressed(
    RegistrationVerifyOtpPressed event,
    Emitter<RegistrationState> emit,
  ) async {
    if (!state.data.canVerifyOtp) {
      final String message;
      if (!state.data.isOtpSent) {
        message = AppStrings.sendOtpFirst;
      } else if (state.data.otp.length != 6) {
        message = AppStrings.invalidOtp;
      } else if (state.data.isRegistration &&
          state.data.usernameStatus == UsernameCheckStatus.taken) {
        message = AppStrings.usernameTaken;
      } else if (state.data.isRegistration &&
          state.data.usernameStatus == UsernameCheckStatus.invalid) {
        message = AppStrings.usernameInvalid;
      } else if (state.data.isRegistration &&
          !state.data.isUsernameAvailable) {
        message = AppStrings.usernameCheckFailed;
      } else if (state.data.isRegistration && !state.data.hasUsername) {
        message = AppStrings.usernameRequired;
      } else {
        message = AppStrings.invalidOtp;
      }
      emit(RegistrationError(data: state.data, message: message));
      return;
    }

    emit(RegistrationLoading(data: state.data));
    try {
      await _registrationViewModel.verifyOtp(
        phoneNumber: _fullPhoneNumber(state.data),
        otp: state.data.otp,
        avatarUrl:
            state.data.isRegistration ? state.data.selectedAvatarUrl : null,
        displayName:
            state.data.isRegistration ? state.data.username.trim() : null,
      );
      await AppPreferences.setLoggedIn(true);
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(didCompleteRegistration: true),
        ),
      );
    } catch (error) {
      emit(
        RegistrationError(
          data: state.data,
          message: AuthErrorMapper.message(
            error,
            fallback: AppStrings.otpVerifyFailed,
          ),
        ),
      );
    }
  }

  Future<void> _onGooglePressed(
    RegistrationGooglePressed event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(RegistrationLoading(data: state.data));
    try {
      await _registrationViewModel.continueWithGoogle(
        avatarUrl:
            state.data.isRegistration ? state.data.selectedAvatarUrl : null,
      );
      await AppPreferences.setLoggedIn(true);
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(didCompleteRegistration: true),
        ),
      );
    } catch (error) {
      emit(
        RegistrationError(
          data: state.data,
          message: AuthErrorMapper.message(
            error,
            fallback: AppStrings.authFailed,
          ),
        ),
      );
    }
  }

  void _onNavigationConsumed(
    RegistrationNavigationConsumed event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(didCompleteRegistration: false),
      ),
    );
  }

  void _onResetRequested(
    RegistrationResetRequested event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      const RegistrationSuccess(data: RegistrationViewData.initial()),
    );
  }

  void _onModeChanged(
    RegistrationModeChanged event,
    Emitter<RegistrationState> emit,
  ) {
    if (state.data.mode == event.mode) {
      return;
    }
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          mode: event.mode,
          usernameStatus: event.mode == RegistrationMode.login
              ? UsernameCheckStatus.unknown
              : state.data.usernameStatus,
          isUsernameChecking: false,
          didCompleteRegistration: false,
        ),
      ),
    );
  }

  String _fullPhoneNumber(RegistrationViewData data) {
    final option = countryCodeOptionById(data.selectedCountryCodeId);
    final dialDigits = option == null
        ? ''
        : option.dialCode.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneDigits = data.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return '+$dialDigits$phoneDigits';
  }

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  String _maskPhone(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 4) {
      return phoneNumber;
    }
    final tail = digits.substring(digits.length - 4);
    return '+••••$tail';
  }

  @override
  Future<void> close() {
    _usernameDebounce?.cancel();
    return super.close();
  }
}
