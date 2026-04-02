import 'package:equatable/equatable.dart';

enum RegistrationMode { login, register }

enum UsernameCheckStatus { unknown, available, taken, invalid }

class RegistrationViewData extends Equatable {
  const RegistrationViewData({
    required this.username,
    required this.passwordResetUsername,
    required this.password,
    required this.confirmPassword,
    required this.recoveryEmail,
    required this.usernameStatus,
    required this.isUsernameChecking,
    required this.canResetPassword,
    required this.isCheckingPasswordReset,
    required this.isSubmitting,
    required this.selectedAvatarUrl,
    required this.didCompleteRegistration,
    required this.showPasswordResetNotice,
    required this.acceptedLegal,
    required this.mode,
  });

  const RegistrationViewData.initial()
    : username = '',
      passwordResetUsername = '',
      password = '',
      confirmPassword = '',
      recoveryEmail = '',
      usernameStatus = UsernameCheckStatus.unknown,
      isUsernameChecking = false,
      canResetPassword = false,
      isCheckingPasswordReset = false,
      isSubmitting = false,
      selectedAvatarUrl = null,
      didCompleteRegistration = false,
      showPasswordResetNotice = false,
      acceptedLegal = false,
      mode = RegistrationMode.login;

  final String username;
  final String passwordResetUsername;
  final String password;
  final String confirmPassword;
  final String recoveryEmail;
  final UsernameCheckStatus usernameStatus;
  final bool isUsernameChecking;
  final bool canResetPassword;
  final bool isCheckingPasswordReset;
  final bool isSubmitting;
  final String? selectedAvatarUrl;
  final bool didCompleteRegistration;
  final bool showPasswordResetNotice;
  final bool acceptedLegal;
  final RegistrationMode mode;

  bool get isRegistration => mode == RegistrationMode.register;

  String get normalizedUsername =>
      username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');

  String get normalizedPasswordResetUsername => passwordResetUsername
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]'), '');

  bool get hasUsername => username.trim().isNotEmpty;

  bool get hasSelectedAvatar => (selectedAvatarUrl ?? '').trim().isNotEmpty;

  bool get isUsernameAvailable =>
      usernameStatus == UsernameCheckStatus.available;

  bool get isRecoveryEmailValid {
    final trimmed = recoveryEmail.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
  }

  bool get hasValidPassword => password.trim().length >= 6;

  bool get doPasswordsMatch => password == confirmPassword;

  bool get canSubmit {
    if (normalizedUsername.length < 3) {
      return false;
    }
    if (!hasValidPassword) {
      return false;
    }
    if (isRegistration) {
      if (!isUsernameAvailable) {
        return false;
      }
      if (!doPasswordsMatch) {
        return false;
      }
      if (!hasSelectedAvatar) {
        return false;
      }
      if (!acceptedLegal) {
        return false;
      }
      if (!isRecoveryEmailValid) {
        return false;
      }
    }
    return true;
  }

  RegistrationViewData copyWith({
    String? username,
    String? passwordResetUsername,
    String? password,
    String? confirmPassword,
    String? recoveryEmail,
    UsernameCheckStatus? usernameStatus,
    bool? isUsernameChecking,
    bool? canResetPassword,
    bool? isCheckingPasswordReset,
    bool? isSubmitting,
    String? selectedAvatarUrl,
    bool clearAvatar = false,
    bool? didCompleteRegistration,
    bool? showPasswordResetNotice,
    bool? acceptedLegal,
    RegistrationMode? mode,
  }) {
    return RegistrationViewData(
      username: username ?? this.username,
      passwordResetUsername:
          passwordResetUsername ?? this.passwordResetUsername,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      usernameStatus: usernameStatus ?? this.usernameStatus,
      isUsernameChecking: isUsernameChecking ?? this.isUsernameChecking,
      canResetPassword: canResetPassword ?? this.canResetPassword,
      isCheckingPasswordReset:
          isCheckingPasswordReset ?? this.isCheckingPasswordReset,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedAvatarUrl: clearAvatar
          ? null
          : selectedAvatarUrl ?? this.selectedAvatarUrl,
      didCompleteRegistration:
          didCompleteRegistration ?? this.didCompleteRegistration,
      showPasswordResetNotice:
          showPasswordResetNotice ?? this.showPasswordResetNotice,
      acceptedLegal: acceptedLegal ?? this.acceptedLegal,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    username,
    passwordResetUsername,
    password,
    confirmPassword,
    recoveryEmail,
    usernameStatus,
    isUsernameChecking,
    canResetPassword,
    isCheckingPasswordReset,
    isSubmitting,
    selectedAvatarUrl,
    didCompleteRegistration,
    showPasswordResetNotice,
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
