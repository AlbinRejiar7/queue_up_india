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

class ProfilePreferredLanguageChanged extends ProfileEvent {
  const ProfilePreferredLanguageChanged({required this.languageCode});

  final String languageCode;

  @override
  List<Object?> get props => <Object?>[languageCode];
}

class ProfileSavePressed extends ProfileEvent {
  const ProfileSavePressed();
}

class ProfileSaveNoticeConsumed extends ProfileEvent {
  const ProfileSaveNoticeConsumed();
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
