import 'package:equatable/equatable.dart';

import '../../../core/constants/country_codes.dart';

enum RegistrationMode { login, register }

enum UsernameCheckStatus { unknown, available, taken, invalid }

class RegistrationViewData extends Equatable {
  const RegistrationViewData({
    required this.phoneNumber,
    required this.otp,
    required this.isOtpSent,
    required this.username,
    required this.usernameStatus,
    required this.isUsernameChecking,
    required this.selectedAvatarUrl,
    required this.selectedCountryCodeId,
    required this.otpResendSeconds,
    required this.didCompleteRegistration,
    required this.acceptedLegal,
    required this.mode,
  });

  const RegistrationViewData.initial()
    : phoneNumber = '',
      otp = '',
      isOtpSent = false,
      username = '',
      usernameStatus = UsernameCheckStatus.unknown,
      isUsernameChecking = false,
      selectedAvatarUrl = null,
      selectedCountryCodeId = defaultCountryCodeId,
      otpResendSeconds = 0,
      didCompleteRegistration = false,
      acceptedLegal = false,
      mode = RegistrationMode.login;

  final String phoneNumber;
  final String otp;
  final bool isOtpSent;
  final String username;
  final UsernameCheckStatus usernameStatus;
  final bool isUsernameChecking;
  final String? selectedAvatarUrl;
  final String selectedCountryCodeId;
  final int otpResendSeconds;
  final bool didCompleteRegistration;
  final bool acceptedLegal;
  final RegistrationMode mode;

  bool get isRegistration => mode == RegistrationMode.register;

  bool get hasUsername => username.trim().isNotEmpty;

  bool get isUsernameAvailable =>
      usernameStatus == UsernameCheckStatus.available;

  bool get canSendOtp {
    if (otpResendSeconds > 0) {
      return false;
    }
    if (isRegistration && !hasUsername) {
      return false;
    }
    if (isRegistration && !isUsernameAvailable) {
      return false;
    }
    if (isRegistration && !acceptedLegal) {
      return false;
    }
    final option = countryCodeOptionById(selectedCountryCodeId);
    final dialDigits = option == null
        ? ''
        : option.dialCode.replaceAll(RegExp(r'[^0-9]'), '');
    final totalDigits = dialDigits.length + phoneNumber.length;
    return phoneNumber.length >= 6 &&
        phoneNumber.length <= 15 &&
        totalDigits <= 15;
  }

  bool get canVerifyOtp {
    if (!isOtpSent || otp.length != 6) {
      return false;
    }
    if (isRegistration && !hasUsername) {
      return false;
    }
    if (isRegistration && !isUsernameAvailable) {
      return false;
    }
    if (isRegistration && !acceptedLegal) {
      return false;
    }
    return true;
  }

  RegistrationViewData copyWith({
    String? phoneNumber,
    String? otp,
    bool? isOtpSent,
    String? username,
    bool clearUsername = false,
    UsernameCheckStatus? usernameStatus,
    bool? isUsernameChecking,
    String? selectedAvatarUrl,
    bool clearAvatar = false,
    String? selectedCountryCodeId,
    int? otpResendSeconds,
    bool? didCompleteRegistration,
    bool? acceptedLegal,
    RegistrationMode? mode,
  }) {
    return RegistrationViewData(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      otp: otp ?? this.otp,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      username: clearUsername ? '' : username ?? this.username,
      usernameStatus: usernameStatus ?? this.usernameStatus,
      isUsernameChecking: isUsernameChecking ?? this.isUsernameChecking,
      selectedAvatarUrl: clearAvatar
          ? null
          : selectedAvatarUrl ?? this.selectedAvatarUrl,
      selectedCountryCodeId:
          selectedCountryCodeId ?? this.selectedCountryCodeId,
      otpResendSeconds: otpResendSeconds ?? this.otpResendSeconds,
      didCompleteRegistration:
          didCompleteRegistration ?? this.didCompleteRegistration,
      acceptedLegal: acceptedLegal ?? this.acceptedLegal,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    phoneNumber,
    otp,
    isOtpSent,
    username,
    usernameStatus,
    isUsernameChecking,
    selectedAvatarUrl,
    selectedCountryCodeId,
    otpResendSeconds,
    didCompleteRegistration,
    acceptedLegal,
    mode,
  ];
}

abstract class RegistrationState extends Equatable {
  const RegistrationState({required this.data});

  final RegistrationViewData data;

  @override
  List<Object?> get props => <Object?>[data];
}

class RegistrationInitial extends RegistrationState {
  const RegistrationInitial()
    : super(data: const RegistrationViewData.initial());
}

class RegistrationLoading extends RegistrationState {
  const RegistrationLoading({required super.data});
}

class RegistrationSuccess extends RegistrationState {
  const RegistrationSuccess({required super.data});
}

class RegistrationError extends RegistrationState {
  const RegistrationError({required this.message, required super.data});

  final String message;

  @override
  List<Object?> get props => <Object?>[data, message];
}
