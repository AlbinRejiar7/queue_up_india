import 'package:equatable/equatable.dart';

import 'registration_state.dart';

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class RegistrationPhoneChanged extends RegistrationEvent {
  const RegistrationPhoneChanged({required this.phoneNumber});

  final String phoneNumber;

  @override
  List<Object?> get props => <Object?>[phoneNumber];
}

class RegistrationOtpChanged extends RegistrationEvent {
  const RegistrationOtpChanged({required this.otp});

  final String otp;

  @override
  List<Object?> get props => <Object?>[otp];
}

class RegistrationAvatarSelected extends RegistrationEvent {
  const RegistrationAvatarSelected({required this.avatarUrl});

  final String avatarUrl;

  @override
  List<Object?> get props => <Object?>[avatarUrl];
}

class RegistrationCountryCodeChanged extends RegistrationEvent {
  const RegistrationCountryCodeChanged({required this.countryCodeId});

  final String countryCodeId;

  @override
  List<Object?> get props => <Object?>[countryCodeId];
}

class RegistrationSendOtpPressed extends RegistrationEvent {
  const RegistrationSendOtpPressed({required this.userInitiated});

  final bool userInitiated;

  @override
  List<Object?> get props => <Object?>[userInitiated];
}

class RegistrationVerifyOtpPressed extends RegistrationEvent {
  const RegistrationVerifyOtpPressed();
}

class RegistrationOtpCooldownTicked extends RegistrationEvent {
  const RegistrationOtpCooldownTicked({required this.secondsLeft});

  final int secondsLeft;

  @override
  List<Object?> get props => <Object?>[secondsLeft];
}

class RegistrationOtpSessionRestored extends RegistrationEvent {
  const RegistrationOtpSessionRestored({
    required this.phoneNumber,
    required this.countryCodeId,
    required this.resendSeconds,
  });

  final String phoneNumber;
  final String countryCodeId;
  final int resendSeconds;

  @override
  List<Object?> get props => <Object?>[
    phoneNumber,
    countryCodeId,
    resendSeconds,
  ];
}

class RegistrationAutoVerified extends RegistrationEvent {
  const RegistrationAutoVerified();
}

class RegistrationOtpLogReceived extends RegistrationEvent {
  const RegistrationOtpLogReceived({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  List<Object?> get props => <Object?>[message, isError];
}

class RegistrationGooglePressed extends RegistrationEvent {
  const RegistrationGooglePressed();
}

class RegistrationNavigationConsumed extends RegistrationEvent {
  const RegistrationNavigationConsumed();
}

class RegistrationResetRequested extends RegistrationEvent {
  const RegistrationResetRequested();
}

class RegistrationUsernameChanged extends RegistrationEvent {
  const RegistrationUsernameChanged({required this.username});

  final String username;

  @override
  List<Object?> get props => <Object?>[username];
}

class RegistrationUsernameCheckRequested extends RegistrationEvent {
  const RegistrationUsernameCheckRequested({required this.username});

  final String username;

  @override
  List<Object?> get props => <Object?>[username];
}

class RegistrationModeChanged extends RegistrationEvent {
  const RegistrationModeChanged({required this.mode});

  final RegistrationMode mode;

  @override
  List<Object?> get props => <Object?>[mode];
}

class RegistrationLegalAcceptedChanged extends RegistrationEvent {
  const RegistrationLegalAcceptedChanged({required this.accepted});

  final bool accepted;

  @override
  List<Object?> get props => <Object?>[accepted];
}
