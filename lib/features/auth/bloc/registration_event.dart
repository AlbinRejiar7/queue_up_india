import 'package:equatable/equatable.dart';

import 'registration_state.dart';

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class RegistrationUsernameChanged extends RegistrationEvent {
  const RegistrationUsernameChanged({required this.username});

  final String username;

  @override
  List<Object?> get props => <Object?>[username];
}

class RegistrationPasswordResetUsernameChanged extends RegistrationEvent {
  const RegistrationPasswordResetUsernameChanged({required this.username});

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

class RegistrationPasswordResetAvailabilityRequested extends RegistrationEvent {
  const RegistrationPasswordResetAvailabilityRequested({
    required this.username,
  });

  final String username;

  @override
  List<Object?> get props => <Object?>[username];
}

class RegistrationPasswordChanged extends RegistrationEvent {
  const RegistrationPasswordChanged({required this.password});

  final String password;

  @override
  List<Object?> get props => <Object?>[password];
}

class RegistrationConfirmPasswordChanged extends RegistrationEvent {
  const RegistrationConfirmPasswordChanged({required this.confirmPassword});

  final String confirmPassword;

  @override
  List<Object?> get props => <Object?>[confirmPassword];
}

class RegistrationRecoveryEmailChanged extends RegistrationEvent {
  const RegistrationRecoveryEmailChanged({required this.recoveryEmail});

  final String recoveryEmail;

  @override
  List<Object?> get props => <Object?>[recoveryEmail];
}

class RegistrationAvatarSelected extends RegistrationEvent {
  const RegistrationAvatarSelected({required this.avatarUrl});

  final String avatarUrl;

  @override
  List<Object?> get props => <Object?>[avatarUrl];
}

class RegistrationSubmitPressed extends RegistrationEvent {
  const RegistrationSubmitPressed();
}

class RegistrationGooglePressed extends RegistrationEvent {
  const RegistrationGooglePressed();
}

class RegistrationForgotPasswordPressed extends RegistrationEvent {
  const RegistrationForgotPasswordPressed();
}

class RegistrationPasswordResetNoticeConsumed extends RegistrationEvent {
  const RegistrationPasswordResetNoticeConsumed();
}

class RegistrationPasswordResetFlowResetRequested extends RegistrationEvent {
  const RegistrationPasswordResetFlowResetRequested();
}

class RegistrationResetRequested extends RegistrationEvent {
  const RegistrationResetRequested();
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
