import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/services/availability_session_manager.dart';
import '../models/language_model.dart';
import '../models/profile_preferences_model.dart';
import '../viewmodel/profile_view_model.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileViewModel profileViewModel})
    : _profileViewModel = profileViewModel,
      super(const ProfileInitial()) {
    on<ProfileRequested>(_onProfileRequested);
    on<ProfileQueueNameChanged>(_onProfileQueueNameChanged);
    on<ProfileUsernameCheckRequested>(_onProfileUsernameCheckRequested);
    on<ProfilePreferredLanguageChanged>(_onProfilePreferredLanguageChanged);
    on<ProfileRecoveryEmailChanged>(_onProfileRecoveryEmailChanged);
    on<ProfileAvatarChanged>(_onProfileAvatarChanged);
    on<ProfileSavePressed>(_onProfileSavePressed);
    on<ProfileSaveNoticeConsumed>(_onProfileSaveNoticeConsumed);
    on<ProfileAuthEmailUpdateRequested>(_onProfileAuthEmailUpdateRequested);
    on<ProfileEmailUpdateNoticeConsumed>(_onProfileEmailUpdateNoticeConsumed);
    on<ProfilePasswordRequested>(_onProfilePasswordRequested);
    on<ProfilePasswordNoticeConsumed>(_onProfilePasswordNoticeConsumed);
    on<ProfileLogoutRequested>(_onProfileLogoutRequested);
    on<ProfileLogoutConsumed>(_onProfileLogoutConsumed);
    on<ProfileDeleteRequested>(_onProfileDeleteRequested);
    on<ProfileDeleteConsumed>(_onProfileDeleteConsumed);
    on<ProfileBugReportRequested>(_onProfileBugReportRequested);
    on<ProfileBugReportNoticeConsumed>(_onProfileBugReportNoticeConsumed);
    on<ProfileSaveWithBypassRequested>(_onProfileSaveWithBypassRequested);
    on<ProfileGeneralSavePressed>(_onProfileGeneralSavePressed);
    on<ProfileUsernameSavePressed>(_onProfileUsernameSavePressed);
  }

  final ProfileViewModel _profileViewModel;
  Timer? _usernameDebounce;

  Future<void> _onProfileRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading(data: state.data));

    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _profileViewModel.loadLanguages(),
        _profileViewModel.loadPreferences(),
      ]);

      final prefs = results[1] as ProfilePreferencesModel;
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            languages: List<LanguageModel>.from(results[0] as List<dynamic>),
            queueName: prefs.queueName,
            savedQueueName: prefs.queueName,
            preferredLanguageCode: prefs.preferredLanguageCode,
            avatarUrl: prefs.avatarUrl,
            recoveryEmail: prefs.recoveryEmail,
            authEmail: prefs.authEmail,
            pendingAuthEmail: prefs.pendingAuthEmail,
            hasLinkedEmail: prefs.hasLinkedEmail,
            usernameStatus: ProfileUsernameCheckStatus.unknown,
            isUsernameChecking: false,
            showSavedNotice: false,
            showPasswordNotice: false,
            showEmailUpdateNotice: false,
            showBugReportNotice: false,
            isSubmittingBugReport: false,
            isSubmittingPassword: false,
            isSubmittingEmailUpdate: false,
            didLogout: false,
            didDeleteAccount: false,
            lastUsernameChangedAt: prefs.lastUsernameChangedAt,
          ),
        ),
      );
    } catch (_) {
      emit(
        ProfileError(message: AppStrings.profileLoadFailed, data: state.data),
      );
    }
  }

  void _onProfileQueueNameChanged(
    ProfileQueueNameChanged event,
    Emitter<ProfileState> emit,
  ) {
    final normalized = _normalizeUsername(event.queueName);
    final savedNormalized = _normalizeUsername(state.data.savedQueueName);
    final status = normalized.length < 3
        ? ProfileUsernameCheckStatus.invalid
        : normalized == savedNormalized
        ? ProfileUsernameCheckStatus.available
        : ProfileUsernameCheckStatus.unknown;

    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          queueName: event.queueName,
          usernameStatus: status,
          isUsernameChecking: false,
          showSavedNotice: false,
          showPasswordNotice: false,
          showBugReportNotice: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );

    _usernameDebounce?.cancel();
    if (status != ProfileUsernameCheckStatus.unknown) {
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 450), () {
      add(ProfileUsernameCheckRequested(username: event.queueName));
    });
  }

  Future<void> _onProfileUsernameCheckRequested(
    ProfileUsernameCheckRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final requestedNormalized = _normalizeUsername(event.username);
    final currentNormalized = _normalizeUsername(state.data.queueName);
    final savedNormalized = _normalizeUsername(state.data.savedQueueName);

    if (requestedNormalized != currentNormalized) {
      return;
    }

    if (requestedNormalized.length < 3) {
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            usernameStatus: ProfileUsernameCheckStatus.invalid,
            isUsernameChecking: false,
          ),
        ),
      );
      return;
    }

    if (requestedNormalized == savedNormalized) {
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            usernameStatus: ProfileUsernameCheckStatus.available,
            isUsernameChecking: false,
          ),
        ),
      );
      return;
    }

    emit(ProfileSuccess(data: state.data.copyWith(isUsernameChecking: true)));

    try {
      final available = await _profileViewModel.isUsernameAvailable(
        event.username,
      );
      final stillSame =
          _normalizeUsername(state.data.queueName) == requestedNormalized;
      if (!stillSame) {
        return;
      }

      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            isUsernameChecking: false,
            usernameStatus: available
                ? ProfileUsernameCheckStatus.available
                : ProfileUsernameCheckStatus.taken,
          ),
        ),
      );
    } catch (_) {
      emit(
        ProfileError(
          message: AppStrings.usernameCheckFailed,
          data: state.data.copyWith(isUsernameChecking: false),
        ),
      );
    }
  }

  void _onProfilePreferredLanguageChanged(
    ProfilePreferredLanguageChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          preferredLanguageCode: event.languageCode,
          showSavedNotice: false,
          showPasswordNotice: false,
          showBugReportNotice: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
  }

  void _onProfileRecoveryEmailChanged(
    ProfileRecoveryEmailChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          recoveryEmail: event.recoveryEmail,
          showSavedNotice: false,
          showPasswordNotice: false,
          showBugReportNotice: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
  }

  void _onProfileAvatarChanged(
    ProfileAvatarChanged event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          avatarUrl: event.avatarUrl,
          showSavedNotice: false,
          showPasswordNotice: false,
          showBugReportNotice: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
  }

  Future<void> _onProfileSavePressed(
    ProfileSavePressed event,
    Emitter<ProfileState> emit,
  ) async {
    if (!state.data.canSave) {
      return;
    }

    emit(
      ProfileSuccess(
        data: state.data.copyWith(isSubmittingUsername: true),
      ),
    );
    try {
      await _profileViewModel.savePreferences(
        ProfilePreferencesModel(
          queueName: state.data.queueName.trim(),
          preferredLanguageCode: state.data.preferredLanguageCode,
          avatarUrl: state.data.avatarUrl,
          recoveryEmail: state.data.recoveryEmail.trim(),
        ),
      );
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            savedQueueName: state.data.queueName.trim(),
            usernameStatus: ProfileUsernameCheckStatus.available,
            isUsernameChecking: false,
            showSavedNotice: true,
            showPasswordNotice: false,
            showEmailUpdateNotice: false,
            showBugReportNotice: false,
            didDeleteAccount: false,
            lastUsernameChangedAt: DateTime.now(),
            isSubmittingUsername: false,
          ),
        ),
      );
    } on StateError catch (error) {
      emit(
        ProfileError(
          message: _mapProfileSaveError(error),
          data: state.data.copyWith(isSubmittingUsername: false),
        ),
      );
    } catch (_) {
      emit(
        ProfileError(
          message: AppStrings.profileSaveFailed,
          data: state.data.copyWith(isSubmittingUsername: false),
        ),
      );
    }
  }

  Future<void> _onProfileGeneralSavePressed(
    ProfileGeneralSavePressed event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(isSubmittingGeneral: true),
      ),
    );
    try {
      await _profileViewModel.savePreferences(
        ProfilePreferencesModel(
          // Use savedQueueName to ensure the username is NOT updated
          queueName: state.data.savedQueueName,
          preferredLanguageCode: state.data.preferredLanguageCode,
          avatarUrl: state.data.avatarUrl,
          recoveryEmail: state.data.recoveryEmail.trim(),
        ),
      );
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            showSavedNotice: true,
            showPasswordNotice: false,
            showEmailUpdateNotice: false,
            showBugReportNotice: false,
            didDeleteAccount: false,
            isSubmittingGeneral: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        ProfileError(
          message: AppStrings.profileSaveFailed,
          data: state.data.copyWith(isSubmittingGeneral: false),
        ),
      );
    }
  }

  Future<void> _onProfileUsernameSavePressed(
    ProfileUsernameSavePressed event,
    Emitter<ProfileState> emit,
  ) async {
    // This is basically ProfileSavePressed but logically separated for clarity
    add(const ProfileSavePressed());
  }

  Future<void> _onProfileSaveWithBypassRequested(
    ProfileSaveWithBypassRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // This assumes the ad was already watched in the UI.
    emit(
      ProfileSuccess(
        data: state.data.copyWith(isSubmittingUsername: true),
      ),
    );
    try {
      await _profileViewModel.savePreferences(
        ProfilePreferencesModel(
          queueName: state.data.queueName.trim(),
          preferredLanguageCode: state.data.preferredLanguageCode,
          avatarUrl: state.data.avatarUrl,
          recoveryEmail: state.data.recoveryEmail.trim(),
        ),
      );
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            savedQueueName: state.data.queueName.trim(),
            usernameStatus: ProfileUsernameCheckStatus.available,
            isUsernameChecking: false,
            showSavedNotice: true,
            showPasswordNotice: false,
            showEmailUpdateNotice: false,
            showBugReportNotice: false,
            didDeleteAccount: false,
            lastUsernameChangedAt: DateTime.now(),
            isSubmittingUsername: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        ProfileError(
          message: AppStrings.profileSaveFailed,
          data: state.data.copyWith(isSubmittingUsername: false),
        ),
      );
    }
  }

  void _onProfileSaveNoticeConsumed(
    ProfileSaveNoticeConsumed event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          showSavedNotice: false,
          showPasswordNotice: false,
          showEmailUpdateNotice: false,
          showBugReportNotice: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
  }

  Future<void> _onProfileAuthEmailUpdateRequested(
    ProfileAuthEmailUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final trimmedEmail = event.newEmail.trim().toLowerCase();
    if (trimmedEmail.isEmpty) {
      emit(
        ProfileError(
          message: AppStrings.linkedEmailInvalid,
          data: state.data.copyWith(isSubmittingEmailUpdate: false),
        ),
      );
      return;
    }

    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          showSavedNotice: false,
          showPasswordNotice: false,
          showEmailUpdateNotice: false,
          showBugReportNotice: false,
          isSubmittingEmailUpdate: true,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );

    try {
      await _profileViewModel.requestAuthEmailUpdate(
        username: state.data.queueName.trim(),
        newEmail: trimmedEmail,
        currentPassword: event.currentPassword.trim(),
      );
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            pendingAuthEmail: trimmedEmail,
            showEmailUpdateNotice: true,
            isSubmittingEmailUpdate: false,
            didLogout: false,
            didDeleteAccount: false,
          ),
        ),
      );
    } on StateError catch (error) {
      emit(
        ProfileError(
          message: _mapEmailUpdateError(error),
          data: state.data.copyWith(isSubmittingEmailUpdate: false),
        ),
      );
    } catch (error) {
      emit(
        ProfileError(
          message: AuthErrorMapper.message(
            error,
            fallback: AppStrings.linkedEmailUpdateFailed,
          ),
          data: state.data.copyWith(isSubmittingEmailUpdate: false),
        ),
      );
    }
  }

  void _onProfileEmailUpdateNoticeConsumed(
    ProfileEmailUpdateNoticeConsumed event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          showEmailUpdateNotice: false,
          isSubmittingEmailUpdate: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
  }

  Future<void> _onProfilePasswordRequested(
    ProfilePasswordRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (event.newPassword.trim().length < 6) {
      emit(
        ProfileError(
          message: AppStrings.passwordTooShort,
          data: state.data.copyWith(isSubmittingPassword: false),
        ),
      );
      return;
    }

    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          showSavedNotice: false,
          showPasswordNotice: false,
          showEmailUpdateNotice: false,
          showBugReportNotice: false,
          isSubmittingPassword: true,
          isSubmittingEmailUpdate: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );

    try {
      await _profileViewModel.updatePassword(
        username: state.data.queueName.trim(),
        newPassword: event.newPassword.trim(),
        currentPassword: event.currentPassword?.trim(),
      );
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            showPasswordNotice: true,
            isSubmittingPassword: false,
            isSubmittingEmailUpdate: false,
            didLogout: false,
            didDeleteAccount: false,
          ),
        ),
      );
    } on StateError catch (error) {
      emit(
        ProfileError(
          message: _mapPasswordError(error),
          data: state.data.copyWith(isSubmittingPassword: false),
        ),
      );
    } catch (error) {
      emit(
        ProfileError(
          message: AuthErrorMapper.message(
            error,
            fallback: AppStrings.passwordUpdateFailed,
          ),
          data: state.data.copyWith(isSubmittingPassword: false),
        ),
      );
    }
  }

  void _onProfilePasswordNoticeConsumed(
    ProfilePasswordNoticeConsumed event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          showPasswordNotice: false,
          isSubmittingPassword: false,
          isSubmittingEmailUpdate: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
  }

  Future<void> _onProfileLogoutRequested(
    ProfileLogoutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading(data: state.data));
    try {
      await PushNotificationService.instance.removeCurrentUserToken();
    } catch (_) {}
    try {
      await AvailabilitySessionManager.clearAvailabilityOnTerminate();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await AppPreferences.setLoggedIn(false);
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          didLogout: true,
          didDeleteAccount: false,
          showBugReportNotice: false,
          isSubmittingBugReport: false,
          isSubmittingPassword: false,
          isSubmittingEmailUpdate: false,
        ),
      ),
    );
  }

  void _onProfileLogoutConsumed(
    ProfileLogoutConsumed event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          didLogout: false,
          didDeleteAccount: false,
          showBugReportNotice: false,
          isSubmittingBugReport: false,
          isSubmittingPassword: false,
          isSubmittingEmailUpdate: false,
        ),
      ),
    );
  }

  Future<void> _onProfileDeleteRequested(
    ProfileDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading(data: state.data));
    try {
      await PushNotificationService.instance.removeCurrentUserToken();
    } catch (_) {}
    try {
      await AvailabilitySessionManager.clearAvailabilityOnTerminate();
    } catch (_) {}

    try {
      await _profileViewModel.deleteAccount(displayName: state.data.queueName);
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      await AppPreferences.setLoggedIn(false);
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            didDeleteAccount: true,
            didLogout: false,
            showBugReportNotice: false,
            isSubmittingBugReport: false,
            isSubmittingPassword: false,
            isSubmittingEmailUpdate: false,
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      final message = error.code == 'requires-recent-login'
          ? AppStrings.deleteAccountReauthRequired
          : AppStrings.deleteAccountFailed;
      emit(ProfileError(message: message, data: state.data));
    } catch (_) {
      emit(
        ProfileError(message: AppStrings.deleteAccountFailed, data: state.data),
      );
    }
  }

  void _onProfileDeleteConsumed(
    ProfileDeleteConsumed event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          didDeleteAccount: false,
          didLogout: false,
          showBugReportNotice: false,
          isSubmittingBugReport: false,
          isSubmittingPassword: false,
          isSubmittingEmailUpdate: false,
        ),
      ),
    );
  }

  Future<void> _onProfileBugReportRequested(
    ProfileBugReportRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final details = event.details.trim();
    if (details.isEmpty) {
      emit(
        ProfileError(
          message: AppStrings.bugReportDetailsRequired,
          data: state.data.copyWith(isSubmittingBugReport: false),
        ),
      );
      return;
    }

    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          showBugReportNotice: false,
          isSubmittingBugReport: true,
          isSubmittingPassword: false,
          isSubmittingEmailUpdate: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );

    try {
      await _profileViewModel.submitBugReport(details: details);
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            showBugReportNotice: true,
            isSubmittingBugReport: false,
            isSubmittingPassword: false,
            isSubmittingEmailUpdate: false,
            didLogout: false,
            didDeleteAccount: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        ProfileError(
          message: AppStrings.bugReportSubmitFailed,
          data: state.data.copyWith(
            showBugReportNotice: false,
            isSubmittingBugReport: false,
            isSubmittingPassword: false,
            isSubmittingEmailUpdate: false,
            didLogout: false,
            didDeleteAccount: false,
          ),
        ),
      );
    }
  }

  void _onProfileBugReportNoticeConsumed(
    ProfileBugReportNoticeConsumed event,
    Emitter<ProfileState> emit,
  ) {
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          showBugReportNotice: false,
          isSubmittingBugReport: false,
          isSubmittingPassword: false,
          isSubmittingEmailUpdate: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
  }

  String _mapProfileSaveError(StateError error) {
    final message = error.message.toString().toLowerCase();
    if (message.contains('username') && message.contains('taken')) {
      return AppStrings.usernameTaken;
    }
    if (message.contains('username') && message.contains('invalid')) {
      return AppStrings.usernameInvalid;
    }
    if (message.contains('recovery email') && message.contains('invalid')) {
      return AppStrings.invalidRecoveryEmail;
    }
    return AppStrings.profileSaveFailed;
  }

  String _mapEmailUpdateError(StateError error) {
    final message = error.message.toString().toLowerCase();
    if (message.contains('current password') && message.contains('required')) {
      return AppStrings.currentPasswordRequired;
    }
    if (message.contains('invalid')) {
      return AppStrings.linkedEmailInvalid;
    }
    if (message.contains('already set')) {
      return AppStrings.linkedEmailAlreadySet;
    }
    return AppStrings.linkedEmailUpdateFailed;
  }

  String _mapPasswordError(StateError error) {
    final message = error.message.toString().toLowerCase();
    if (message.contains('current password') && message.contains('required')) {
      return AppStrings.currentPasswordRequired;
    }
    if (message.contains('password') && message.contains('short')) {
      return AppStrings.passwordTooShort;
    }
    return AppStrings.passwordUpdateFailed;
  }

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  @override
  Future<void> close() {
    _usernameDebounce?.cancel();
    return super.close();
  }
}
