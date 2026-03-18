import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/country_codes.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../data/repositories/auth_repository.dart';
import '../viewmodel/registration_view_model.dart';
import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({required RegistrationViewModel registrationViewModel})
    : _registrationViewModel = registrationViewModel,
      _auth = FirebaseAuth.instance,
      super(const RegistrationInitial()) {
    on<RegistrationPhoneChanged>(_onPhoneChanged);
    on<RegistrationUsernameChanged>(_onUsernameChanged);
    on<RegistrationUsernameCheckRequested>(_onUsernameCheckRequested);
    on<RegistrationOtpChanged>(_onOtpChanged);
    on<RegistrationAvatarSelected>(_onAvatarSelected);
    on<RegistrationCountryCodeChanged>(_onCountryCodeChanged);
    on<RegistrationSendOtpPressed>(_onSendOtpPressed);
    on<RegistrationVerifyOtpPressed>(_onVerifyOtpPressed);
    on<RegistrationOtpCooldownTicked>(_onOtpCooldownTicked);
    on<RegistrationOtpSessionRestored>(_onOtpSessionRestored);
    on<RegistrationAutoVerified>(_onAutoVerified);
    on<RegistrationOtpLogReceived>(_onOtpLogReceived);
    on<RegistrationGooglePressed>(_onGooglePressed);
    on<RegistrationNavigationConsumed>(_onNavigationConsumed);
    on<RegistrationResetRequested>(_onResetRequested);
    on<RegistrationModeChanged>(_onModeChanged);
    on<RegistrationLegalAcceptedChanged>(_onLegalAcceptedChanged);

    _authSubscription = _auth.authStateChanges().listen(_handleAuthChange);
    _otpLogSubscription = _registrationViewModel.otpLogs.listen(
      (OtpLogEvent event) {
        add(
          RegistrationOtpLogReceived(
            message: event.message,
            isError: event.isError,
          ),
        );
      },
    );
    unawaited(_restoreOtpSession());
  }

  final RegistrationViewModel _registrationViewModel;
  final FirebaseAuth _auth;
  Timer? _usernameDebounce;
  Timer? _otpCooldownTimer;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<OtpLogEvent>? _otpLogSubscription;

  static const int _otpCooldownSeconds = 60;
  static const Duration _otpSessionTtl = Duration(minutes: 10);

  void _onPhoneChanged(
    RegistrationPhoneChanged event,
    Emitter<RegistrationState> emit,
  ) {
    final sanitized = event.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final resetOtp = sanitized != state.data.phoneNumber;
    if (resetOtp) {
      _stopOtpCooldown();
      unawaited(AppPreferences.clearOtpSession());
      unawaited(AppPreferences.clearOtpPendingProfile());
    }
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          phoneNumber: sanitized,
          otp: resetOtp ? '' : state.data.otp,
          isOtpSent: resetOtp ? false : state.data.isOtpSent,
          otpResendSeconds: resetOtp ? 0 : state.data.otpResendSeconds,
          isSendingOtp: false,
          isVerifyingOtp: false,
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
    if (sanitized.length == 6 && state.data.otp.length != 6) {
      developer.log(
        'OTP input reached 6 digits',
        name: 'RegistrationBloc',
      );
    } else if (sanitized.isEmpty && state.data.otp.isNotEmpty) {
      developer.log(
        'OTP input cleared',
        name: 'RegistrationBloc',
      );
    }
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
    _stopOtpCooldown();
    unawaited(AppPreferences.clearOtpSession());
    unawaited(AppPreferences.clearOtpPendingProfile());
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          selectedCountryCodeId: event.countryCodeId,
          isOtpSent: false,
          otp: '',
          otpResendSeconds: 0,
          isSendingOtp: false,
          isVerifyingOtp: false,
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
    developer.log(
      'OTP send pressed (mode=${state.data.mode}, isOtpSent=${state.data.isOtpSent}, otpLen=${state.data.otp.length}, resend=${state.data.otpResendSeconds}s, usernameStatus=${state.data.usernameStatus}, acceptedLegal=${state.data.acceptedLegal})',
      name: 'RegistrationBloc',
      error: _maskPhone(_fullPhoneNumber(state.data)),
    );
    if (!event.userInitiated) {
      developer.log(
        'OTP send ignored: not user initiated',
        name: 'RegistrationBloc',
      );
      return;
    }
    if (state.data.otpResendSeconds > 0) {
      developer.log(
        'OTP send blocked by cooldown: ${state.data.otpResendSeconds}s',
        name: 'RegistrationBloc',
      );
      return;
    }
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
      } else if (state.data.isRegistration && !state.data.acceptedLegal) {
        message = AppStrings.acceptLegalRequired;
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

    emit(
      RegistrationLoading(
        data: state.data.copyWith(
          isSendingOtp: true,
          isVerifyingOtp: false,
        ),
      ),
    );
    _emitOtpLog(emit, 'OTP send started');
    try {
      await AppPreferences.saveOtpPendingProfile(
        displayName:
            state.data.isRegistration ? state.data.username.trim() : null,
        avatarUrl: state.data.isRegistration
            ? state.data.selectedAvatarUrl
            : null,
        isRegistration: state.data.isRegistration,
      );
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
      developer.log(
        'OTP send requested successfully',
        name: 'RegistrationBloc',
      );
      _startOtpCooldown(_otpCooldownSeconds);
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            isOtpSent: true,
            otp: '',
            otpResendSeconds: _otpCooldownSeconds,
            isSendingOtp: false,
            isVerifyingOtp: false,
            didCompleteRegistration: false,
          ),
        ),
      );
    } catch (error) {
      developer.log(
        'OTP send failed: $error',
        name: 'RegistrationBloc',
      );
      if (error.toString().toLowerCase().contains('not registered')) {
        emit(
          RegistrationError(
            data: state.data.copyWith(
              isSendingOtp: false,
              isVerifyingOtp: false,
            ),
            message: AppStrings.phoneNotRegistered,
          ),
        );
        return;
      }
      emit(
        RegistrationError(
          data: state.data.copyWith(
            isSendingOtp: false,
            isVerifyingOtp: false,
          ),
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
    developer.log(
      'OTP verify pressed (mode=${state.data.mode}, isOtpSent=${state.data.isOtpSent}, otpLen=${state.data.otp.length}, canVerify=${state.data.canVerifyOtp}, usernameStatus=${state.data.usernameStatus}, acceptedLegal=${state.data.acceptedLegal})',
      name: 'RegistrationBloc',
      error: _maskPhone(_fullPhoneNumber(state.data)),
    );
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
      } else if (state.data.isRegistration && !state.data.acceptedLegal) {
        message = AppStrings.acceptLegalRequired;
      } else if (state.data.isRegistration && !state.data.hasUsername) {
        message = AppStrings.usernameRequired;
      } else {
        message = AppStrings.invalidOtp;
      }
      emit(RegistrationError(data: state.data, message: message));
      return;
    }

    emit(
      RegistrationLoading(
        data: state.data.copyWith(
          isSendingOtp: false,
          isVerifyingOtp: true,
        ),
      ),
    );
    _emitOtpLog(emit, 'Verify OTP started');
    try {
      await _registrationViewModel.verifyOtp(
        phoneNumber: _fullPhoneNumber(state.data),
        otp: state.data.otp,
        avatarUrl:
            state.data.isRegistration ? state.data.selectedAvatarUrl : null,
        displayName:
            state.data.isRegistration ? state.data.username.trim() : null,
      );
      developer.log(
        'OTP verify success',
        name: 'RegistrationBloc',
      );
      await AppPreferences.setLoggedIn(true);
      _stopOtpCooldown();
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            didCompleteRegistration: true,
            isSendingOtp: false,
            isVerifyingOtp: false,
            otpLogId: state.data.otpLogId + 1,
            otpLogMessage: 'Verify OTP success',
            otpLogIsError: false,
          ),
        ),
      );
    } catch (error) {
      developer.log(
        'OTP verify failed: $error',
        name: 'RegistrationBloc',
      );
      emit(
        RegistrationError(
          data: state.data.copyWith(
            isSendingOtp: false,
            isVerifyingOtp: false,
          ),
          message: AuthErrorMapper.message(
            error,
            fallback: AppStrings.otpVerifyFailed,
          ),
        ),
      );
    }
  }

  void _handleAuthChange(User? user) {
    if (user == null) {
      return;
    }
    if (state.data.didCompleteRegistration) {
      return;
    }
    if (!state.data.isOtpSent && !state.data.isSendingOtp) {
      return;
    }
    add(const RegistrationAutoVerified());
  }

  void _onOtpLogReceived(
    RegistrationOtpLogReceived event,
    Emitter<RegistrationState> emit,
  ) {
    _emitOtpLog(
      emit,
      event.message,
      isError: event.isError,
    );
  }

  void _emitOtpLog(
    Emitter<RegistrationState> emit,
    String message, {
    bool isError = false,
  }) {
    final updatedData = state.data.copyWith(
      otpLogId: state.data.otpLogId + 1,
      otpLogMessage: message,
      otpLogIsError: isError,
    );
    if (state is RegistrationLoading) {
      emit(RegistrationLoading(data: updatedData));
    } else if (state is RegistrationError) {
      emit(
        RegistrationError(
          data: updatedData,
          message: (state as RegistrationError).message,
        ),
      );
    } else {
      emit(RegistrationSuccess(data: updatedData));
    }
  }

  Future<void> _onAutoVerified(
    RegistrationAutoVerified event,
    Emitter<RegistrationState> emit,
  ) async {
    if (state.data.didCompleteRegistration) {
      return;
    }
    await AppPreferences.setLoggedIn(true);
    _stopOtpCooldown();
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          didCompleteRegistration: true,
          isSendingOtp: false,
          isVerifyingOtp: false,
          otpLogId: state.data.otpLogId + 1,
          otpLogMessage: 'Auto-verification success',
          otpLogIsError: false,
        ),
      ),
    );
  }

  Future<void> _onGooglePressed(
    RegistrationGooglePressed event,
    Emitter<RegistrationState> emit,
  ) async {
    emit(
      RegistrationLoading(
        data: state.data.copyWith(
          isSendingOtp: false,
          isVerifyingOtp: false,
        ),
      ),
    );
    try {
      await _registrationViewModel.continueWithGoogle(
        avatarUrl:
            state.data.isRegistration ? state.data.selectedAvatarUrl : null,
      );
      await AppPreferences.setLoggedIn(true);
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            didCompleteRegistration: true,
            isSendingOtp: false,
            isVerifyingOtp: false,
          ),
        ),
      );
    } catch (error) {
      emit(
        RegistrationError(
          data: state.data.copyWith(
            isSendingOtp: false,
            isVerifyingOtp: false,
          ),
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
        data: state.data.copyWith(
          didCompleteRegistration: false,
          isSendingOtp: false,
          isVerifyingOtp: false,
        ),
      ),
    );
  }

  void _onResetRequested(
    RegistrationResetRequested event,
    Emitter<RegistrationState> emit,
  ) {
    _stopOtpCooldown();
    unawaited(AppPreferences.clearOtpSession());
    unawaited(AppPreferences.clearOtpPendingProfile());
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
    _stopOtpCooldown();
    unawaited(AppPreferences.clearOtpSession());
    unawaited(AppPreferences.clearOtpPendingProfile());
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          mode: event.mode,
          usernameStatus: event.mode == RegistrationMode.login
              ? UsernameCheckStatus.unknown
              : state.data.usernameStatus,
          isUsernameChecking: false,
          isOtpSent: false,
          otp: '',
          otpResendSeconds: 0,
          isSendingOtp: false,
          isVerifyingOtp: false,
          didCompleteRegistration: false,
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
          isSendingOtp: false,
          isVerifyingOtp: false,
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

  void _onOtpCooldownTicked(
    RegistrationOtpCooldownTicked event,
    Emitter<RegistrationState> emit,
  ) {
    if (event.secondsLeft <= 0) {
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(otpResendSeconds: 0),
        ),
      );
      return;
    }
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(otpResendSeconds: event.secondsLeft),
      ),
    );
  }

  void _onOtpSessionRestored(
    RegistrationOtpSessionRestored event,
    Emitter<RegistrationState> emit,
  ) {
    developer.log(
      'OTP session restored: resend=${event.resendSeconds}s, phoneLen=${event.phoneNumber.length}',
      name: 'RegistrationBloc',
    );
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          phoneNumber: event.phoneNumber,
          selectedCountryCodeId: event.countryCodeId,
          isOtpSent: true,
          otp: '',
          otpResendSeconds: event.resendSeconds,
          isSendingOtp: false,
          isVerifyingOtp: false,
          didCompleteRegistration: false,
        ),
      ),
    );
    if (event.resendSeconds > 0) {
      _startOtpCooldown(event.resendSeconds);
    }
  }

  Future<void> _restoreOtpSession() async {
    final session = await AppPreferences.loadOtpSession();
    if (session == null) {
      developer.log(
        'No OTP session to restore',
        name: 'RegistrationBloc',
      );
      return;
    }
    final age = DateTime.now().difference(session.sentAt);
    if (age > _otpSessionTtl) {
      developer.log(
        'Stored OTP session expired, clearing',
        name: 'RegistrationBloc',
      );
      await AppPreferences.clearOtpSession();
      return;
    }
    developer.log(
      'Stored OTP session found (age=${age.inSeconds}s, phoneLen=${session.phoneNumber.length})',
      name: 'RegistrationBloc',
    );
    final digits = session.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return;
    }
    final match = _matchCountryCode(digits);
    final dialDigits = match == null
        ? ''
        : match.dialCode.replaceAll(RegExp(r'[^0-9]'), '');
    final localNumber = dialDigits.isNotEmpty &&
            digits.startsWith(dialDigits)
        ? digits.substring(dialDigits.length)
        : digits;
    final elapsedSeconds = age.inSeconds;
    final int resendSeconds = (_otpCooldownSeconds - elapsedSeconds)
        .clamp(0, _otpCooldownSeconds)
        .toInt();
    add(
      RegistrationOtpSessionRestored(
        phoneNumber: localNumber,
        countryCodeId: match?.id ?? state.data.selectedCountryCodeId,
        resendSeconds: resendSeconds,
      ),
    );
  }

  CountryCodeOption? _matchCountryCode(String digits) {
    CountryCodeOption? best;
    for (final option in countryCodeOptions) {
      final dialDigits =
          option.dialCode.replaceAll(RegExp(r'[^0-9]'), '');
      if (dialDigits.isEmpty) {
        continue;
      }
      if (digits.startsWith(dialDigits)) {
        if (best == null ||
            dialDigits.length >
                best!.dialCode.replaceAll(RegExp(r'[^0-9]'), '').length) {
          best = option;
        }
      }
    }
    return best;
  }

  void _startOtpCooldown(int seconds) {
    _otpCooldownTimer?.cancel();
    if (seconds <= 0) {
      return;
    }
    _otpCooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        final remaining = seconds - timer.tick;
        if (remaining <= 0) {
          timer.cancel();
          add(const RegistrationOtpCooldownTicked(secondsLeft: 0));
        } else {
          add(RegistrationOtpCooldownTicked(secondsLeft: remaining));
        }
      },
    );
  }

  void _stopOtpCooldown() {
    _otpCooldownTimer?.cancel();
    _otpCooldownTimer = null;
  }

  @override
  Future<void> close() {
    _usernameDebounce?.cancel();
    _otpCooldownTimer?.cancel();
    _authSubscription?.cancel();
    _otpLogSubscription?.cancel();
    return super.close();
  }
}
