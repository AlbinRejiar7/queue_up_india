import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ProfileRequested extends ProfileEvent {
  const ProfileRequested();
}

class ProfileQueueNameChanged extends ProfileEvent {
  const ProfileQueueNameChanged({required this.queueName});

  final String queueName;

  @override
  List<Object?> get props => <Object?>[queueName];
}

class ProfileUsernameCheckRequested extends ProfileEvent {
  const ProfileUsernameCheckRequested({required this.username});

  final String username;

  @override
  List<Object?> get props => <Object?>[username];
}

class ProfilePreferredLanguageChanged extends ProfileEvent {
  const ProfilePreferredLanguageChanged({required this.languageCode});

  final String languageCode;

  @override
  List<Object?> get props => <Object?>[languageCode];
}

class ProfileRecoveryEmailChanged extends ProfileEvent {
  const ProfileRecoveryEmailChanged({required this.recoveryEmail});

  final String recoveryEmail;

  @override
  List<Object?> get props => <Object?>[recoveryEmail];
}

class ProfileSavePressed extends ProfileEvent {
  const ProfileSavePressed();
}

class ProfileSaveNoticeConsumed extends ProfileEvent {
  const ProfileSaveNoticeConsumed();
}

class ProfileAuthEmailUpdateRequested extends ProfileEvent {
  const ProfileAuthEmailUpdateRequested({
    required this.newEmail,
    required this.currentPassword,
  });

  final String newEmail;
  final String currentPassword;

  @override
  List<Object?> get props => <Object?>[newEmail, currentPassword];
}

class ProfileEmailUpdateNoticeConsumed extends ProfileEvent {
  const ProfileEmailUpdateNoticeConsumed();
}

class ProfilePasswordRequested extends ProfileEvent {
  const ProfilePasswordRequested({
    required this.newPassword,
    this.currentPassword,
  });

  final String newPassword;
  final String? currentPassword;

  @override
  List<Object?> get props => <Object?>[newPassword, currentPassword];
}

class ProfilePasswordNoticeConsumed extends ProfileEvent {
  const ProfilePasswordNoticeConsumed();
}

class ProfileAvatarChanged extends ProfileEvent {
  const ProfileAvatarChanged({required this.avatarUrl});

  final String avatarUrl;

  @override
  List<Object?> get props => <Object?>[avatarUrl];
}

class ProfileLogoutRequested extends ProfileEvent {
  const ProfileLogoutRequested();
}

class ProfileLogoutConsumed extends ProfileEvent {
  const ProfileLogoutConsumed();
}

class ProfileDeleteRequested extends ProfileEvent {
  const ProfileDeleteRequested();
}

class ProfileDeleteConsumed extends ProfileEvent {
  const ProfileDeleteConsumed();
}

class ProfileBugReportRequested extends ProfileEvent {
  const ProfileBugReportRequested({required this.details});

  final String details;

  @override
  List<Object?> get props => <Object?>[details];
}

class ProfileBugReportNoticeConsumed extends ProfileEvent {
  const ProfileBugReportNoticeConsumed();
}
