import 'package:equatable/equatable.dart';

import '../models/language_model.dart';

class ProfileViewData extends Equatable {
  const ProfileViewData({
    required this.languages,
    required this.queueName,
    required this.preferredLanguageCode,
    required this.avatarUrl,
    this.showSavedNotice = false,
    this.didLogout = false,
  });

  const ProfileViewData.initial()
    : languages = const <LanguageModel>[],
      queueName = '',
      preferredLanguageCode = '',
      avatarUrl = '',
      showSavedNotice = false,
      didLogout = false;

  final List<LanguageModel> languages;
  final String queueName;
  final String preferredLanguageCode;
  final String avatarUrl;
  final bool showSavedNotice;
  final bool didLogout;

  bool get canSave =>
      queueName.trim().isNotEmpty && preferredLanguageCode.trim().isNotEmpty;

  ProfileViewData copyWith({
    List<LanguageModel>? languages,
    String? queueName,
    String? preferredLanguageCode,
    String? avatarUrl,
    bool? showSavedNotice,
    bool? didLogout,
  }) {
    return ProfileViewData(
      languages: languages ?? this.languages,
      queueName: queueName ?? this.queueName,
      preferredLanguageCode:
          preferredLanguageCode ?? this.preferredLanguageCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      showSavedNotice: showSavedNotice ?? this.showSavedNotice,
      didLogout: didLogout ?? this.didLogout,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    languages,
    queueName,
    preferredLanguageCode,
    avatarUrl,
    showSavedNotice,
    didLogout,
  ];
}

abstract class ProfileState extends Equatable {
  const ProfileState({required this.data});

  final ProfileViewData data;

  @override
  List<Object?> get props => <Object?>[data];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial() : super(data: const ProfileViewData.initial());
}

class ProfileLoading extends ProfileState {
  const ProfileLoading({required super.data});
}

class ProfileSuccess extends ProfileState {
  const ProfileSuccess({required super.data});
}

class ProfileError extends ProfileState {
  const ProfileError({required this.message, required super.data});

  final String message;

  @override
  List<Object?> get props => <Object?>[data, message];
}
