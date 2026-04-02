import 'package:equatable/equatable.dart';

import '../models/language_model.dart';

enum ProfileUsernameCheckStatus { unknown, available, taken, invalid }

class ProfileViewData extends Equatable {
  const ProfileViewData({
    required this.languages,
    required this.queueName,
    required this.savedQueueName,
    required this.preferredLanguageCode,
    required this.avatarUrl,
    required this.recoveryEmail,
    required this.authEmail,
    required this.pendingAuthEmail,
    required this.hasLinkedEmail,
    required this.usernameStatus,
    required this.isUsernameChecking,
    this.showSavedNotice = false,
    this.showPasswordNotice = false,
    this.showEmailUpdateNotice = false,
    this.showBugReportNotice = false,
    this.isSubmittingBugReport = false,
    this.isSubmittingPassword = false,
    this.isSubmittingEmailUpdate = false,
    this.didLogout = false,
    this.didDeleteAccount = false,
  });

  const ProfileViewData.initial()
    : languages = const <LanguageModel>[],
      queueName = '',
      savedQueueName = '',
      preferredLanguageCode = '',
      avatarUrl = '',
      recoveryEmail = '',
      authEmail = '',
      pendingAuthEmail = '',
      hasLinkedEmail = false,
      usernameStatus = ProfileUsernameCheckStatus.unknown,
      isUsernameChecking = false,
      showSavedNotice = false,
      showPasswordNotice = false,
      showEmailUpdateNotice = false,
      showBugReportNotice = false,
      isSubmittingBugReport = false,
      isSubmittingPassword = false,
      isSubmittingEmailUpdate = false,
      didLogout = false,
      didDeleteAccount = false;

  final List<LanguageModel> languages;
  final String queueName;
  final String savedQueueName;
  final String preferredLanguageCode;
  final String avatarUrl;
  final String recoveryEmail;
  final String authEmail;
  final String pendingAuthEmail;
  final bool hasLinkedEmail;
  final ProfileUsernameCheckStatus usernameStatus;
  final bool isUsernameChecking;
  final bool showSavedNotice;
  final bool showPasswordNotice;
  final bool showEmailUpdateNotice;
  final bool showBugReportNotice;
  final bool isSubmittingBugReport;
  final bool isSubmittingPassword;
  final bool isSubmittingEmailUpdate;
  final bool didLogout;
  final bool didDeleteAccount;

  bool get hasPendingAuthEmail => pendingAuthEmail.trim().isNotEmpty;

  bool get isUsernameChanged =>
      _normalizeUsername(queueName) != _normalizeUsername(savedQueueName);

  bool get isUsernameReadyToSave {
    final normalized = _normalizeUsername(queueName);
    if (normalized.length < 3) {
      return false;
    }
    if (!isUsernameChanged) {
      return true;
    }
    return usernameStatus == ProfileUsernameCheckStatus.available;
  }

  bool get isRecoveryEmailValid {
    final trimmed = recoveryEmail.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
  }

  bool get canSave =>
      queueName.trim().isNotEmpty &&
      preferredLanguageCode.trim().isNotEmpty &&
      !isUsernameChecking &&
      isRecoveryEmailValid &&
      isUsernameReadyToSave;

  ProfileViewData copyWith({
    List<LanguageModel>? languages,
    String? queueName,
    String? savedQueueName,
    String? preferredLanguageCode,
    String? avatarUrl,
    String? recoveryEmail,
    String? authEmail,
    String? pendingAuthEmail,
    bool? hasLinkedEmail,
    ProfileUsernameCheckStatus? usernameStatus,
    bool? isUsernameChecking,
    bool? showSavedNotice,
    bool? showPasswordNotice,
    bool? showEmailUpdateNotice,
    bool? showBugReportNotice,
    bool? isSubmittingBugReport,
    bool? isSubmittingPassword,
    bool? isSubmittingEmailUpdate,
    bool? didLogout,
    bool? didDeleteAccount,
  }) {
    return ProfileViewData(
      languages: languages ?? this.languages,
      queueName: queueName ?? this.queueName,
      savedQueueName: savedQueueName ?? this.savedQueueName,
      preferredLanguageCode:
          preferredLanguageCode ?? this.preferredLanguageCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      authEmail: authEmail ?? this.authEmail,
      pendingAuthEmail: pendingAuthEmail ?? this.pendingAuthEmail,
      hasLinkedEmail: hasLinkedEmail ?? this.hasLinkedEmail,
      usernameStatus: usernameStatus ?? this.usernameStatus,
      isUsernameChecking: isUsernameChecking ?? this.isUsernameChecking,
      showSavedNotice: showSavedNotice ?? this.showSavedNotice,
      showPasswordNotice: showPasswordNotice ?? this.showPasswordNotice,
      showEmailUpdateNotice:
          showEmailUpdateNotice ?? this.showEmailUpdateNotice,
      showBugReportNotice: showBugReportNotice ?? this.showBugReportNotice,
      isSubmittingBugReport:
          isSubmittingBugReport ?? this.isSubmittingBugReport,
      isSubmittingPassword: isSubmittingPassword ?? this.isSubmittingPassword,
      isSubmittingEmailUpdate:
          isSubmittingEmailUpdate ?? this.isSubmittingEmailUpdate,
      didLogout: didLogout ?? this.didLogout,
      didDeleteAccount: didDeleteAccount ?? this.didDeleteAccount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    languages,
    queueName,
    savedQueueName,
    preferredLanguageCode,
    avatarUrl,
    recoveryEmail,
    authEmail,
    pendingAuthEmail,
    hasLinkedEmail,
    usernameStatus,
    isUsernameChecking,
    showSavedNotice,
    showPasswordNotice,
    showEmailUpdateNotice,
    showBugReportNotice,
    isSubmittingBugReport,
    isSubmittingPassword,
    isSubmittingEmailUpdate,
    didLogout,
    didDeleteAccount,
  ];

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }
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
