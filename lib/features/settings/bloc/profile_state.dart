import 'package:equatable/equatable.dart';

import '../models/language_model.dart';

class ProfileViewData extends Equatable {
  const ProfileViewData({
    required this.languages,
    required this.queueName,
    required this.preferredLanguageCode,
    required this.avatarUrl,
    this.showSavedNotice = false,
    this.showBugReportNotice = false,
    this.isSubmittingBugReport = false,
    this.didLogout = false,
    this.didDeleteAccount = false,
  });

  const ProfileViewData.initial()
    : languages = const <LanguageModel>[],
      queueName = '',
      preferredLanguageCode = '',
      avatarUrl = '',
      showSavedNotice = false,
      showBugReportNotice = false,
      isSubmittingBugReport = false,
      didLogout = false,
      didDeleteAccount = false;

  final List<LanguageModel> languages;
  final String queueName;
  final String preferredLanguageCode;
  final String avatarUrl;
  final bool showSavedNotice;
  final bool showBugReportNotice;
  final bool isSubmittingBugReport;
  final bool didLogout;
  final bool didDeleteAccount;

  bool get canSave =>
      queueName.trim().isNotEmpty && preferredLanguageCode.trim().isNotEmpty;

  ProfileViewData copyWith({
    List<LanguageModel>? languages,
    String? queueName,
    String? preferredLanguageCode,
    String? avatarUrl,
    bool? showSavedNotice,
    bool? showBugReportNotice,
    bool? isSubmittingBugReport,
    bool? didLogout,
    bool? didDeleteAccount,
  }) {
    return ProfileViewData(
      languages: languages ?? this.languages,
      queueName: queueName ?? this.queueName,
      preferredLanguageCode:
          preferredLanguageCode ?? this.preferredLanguageCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      showSavedNotice: showSavedNotice ?? this.showSavedNotice,
      showBugReportNotice: showBugReportNotice ?? this.showBugReportNotice,
      isSubmittingBugReport:
          isSubmittingBugReport ?? this.isSubmittingBugReport,
      didLogout: didLogout ?? this.didLogout,
      didDeleteAccount: didDeleteAccount ?? this.didDeleteAccount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    languages,
    queueName,
    preferredLanguageCode,
    avatarUrl,
    showSavedNotice,
    showBugReportNotice,
    isSubmittingBugReport,
    didLogout,
    didDeleteAccount,
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
