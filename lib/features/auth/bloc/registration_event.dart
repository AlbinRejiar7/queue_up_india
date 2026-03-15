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
  const RegistrationSendOtpPressed();
}

class RegistrationVerifyOtpPressed extends RegistrationEvent {
  const RegistrationVerifyOtpPressed();
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
