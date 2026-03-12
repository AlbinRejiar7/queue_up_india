import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/country_codes.dart';
import '../../../core/utils/app_preferences.dart';
import '../viewmodel/registration_view_model.dart';
import 'registration_event.dart';
import 'registration_state.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({required RegistrationViewModel registrationViewModel})
    : _registrationViewModel = registrationViewModel,
      super(const RegistrationInitial()) {
    on<RegistrationPhoneChanged>(_onPhoneChanged);
    on<RegistrationUsernameChanged>(_onUsernameChanged);
    on<RegistrationOtpChanged>(_onOtpChanged);
    on<RegistrationAvatarSelected>(_onAvatarSelected);
    on<RegistrationCountryCodeChanged>(_onCountryCodeChanged);
    on<RegistrationSendOtpPressed>(_onSendOtpPressed);
    on<RegistrationVerifyOtpPressed>(_onVerifyOtpPressed);
    on<RegistrationGooglePressed>(_onGooglePressed);
    on<RegistrationNavigationConsumed>(_onNavigationConsumed);
    on<RegistrationModeChanged>(_onModeChanged);
  }

  final RegistrationViewModel _registrationViewModel;

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
    emit(
      RegistrationSuccess(
        data: state.data.copyWith(
          username: event.username,
          didCompleteRegistration: false,
        ),
      ),
    );
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

  Future<void> _onSendOtpPressed(
    RegistrationSendOtpPressed event,
    Emitter<RegistrationState> emit,
  ) async {
    if (!state.data.canSendOtp) {
      return;
    }

    emit(RegistrationLoading(data: state.data));
    try {
      await _registrationViewModel.sendOtp(_fullPhoneNumber(state.data));
      emit(
        RegistrationSuccess(
          data: state.data.copyWith(
            isOtpSent: true,
            otp: '',
            didCompleteRegistration: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        RegistrationError(
          data: state.data,
          message: AppStrings.otpSendFailed,
        ),
      );
    }
  }

  Future<void> _onVerifyOtpPressed(
    RegistrationVerifyOtpPressed event,
    Emitter<RegistrationState> emit,
  ) async {
    if (!state.data.canVerifyOtp) {
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
    } catch (_) {
      emit(
        RegistrationError(
          data: state.data,
          message: AppStrings.otpVerifyFailed,
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
    } catch (_) {
      emit(
        RegistrationError(
          data: state.data,
          message: AppStrings.authFailed,
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
}
