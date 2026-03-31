import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_preferences.dart';
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
    on<ProfilePreferredLanguageChanged>(_onProfilePreferredLanguageChanged);
    on<ProfileAvatarChanged>(_onProfileAvatarChanged);
    on<ProfileSavePressed>(_onProfileSavePressed);
    on<ProfileSaveNoticeConsumed>(_onProfileSaveNoticeConsumed);
    on<ProfileLogoutRequested>(_onProfileLogoutRequested);
    on<ProfileLogoutConsumed>(_onProfileLogoutConsumed);
    on<ProfileDeleteRequested>(_onProfileDeleteRequested);
    on<ProfileDeleteConsumed>(_onProfileDeleteConsumed);
    on<ProfileBugReportRequested>(_onProfileBugReportRequested);
    on<ProfileBugReportNoticeConsumed>(_onProfileBugReportNoticeConsumed);
  }

  final ProfileViewModel _profileViewModel;

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
            preferredLanguageCode: prefs.preferredLanguageCode,
            avatarUrl: prefs.avatarUrl,
            showSavedNotice: false,
            showBugReportNotice: false,
            isSubmittingBugReport: false,
            didLogout: false,
            didDeleteAccount: false,
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
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          queueName: event.queueName,
          showSavedNotice: false,
          showBugReportNotice: false,
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
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

    emit(ProfileLoading(data: state.data));
    try {
      await _profileViewModel.savePreferences(
        ProfilePreferencesModel(
          queueName: state.data.queueName.trim(),
          preferredLanguageCode: state.data.preferredLanguageCode,
          avatarUrl: state.data.avatarUrl,
        ),
      );
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            showSavedNotice: true,
            showBugReportNotice: false,
            didDeleteAccount: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        ProfileError(message: AppStrings.profileSaveFailed, data: state.data),
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
          showBugReportNotice: false,
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
      await AvailabilitySessionManager.clearAvailabilityOnTerminate();
    } catch (_) {}
    await AppPreferences.setLoggedIn(false);
    emit(
      ProfileSuccess(
        data: state.data.copyWith(
          didLogout: true,
          didDeleteAccount: false,
          showBugReportNotice: false,
          isSubmittingBugReport: false,
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
      await AvailabilitySessionManager.clearAvailabilityOnTerminate();
    } catch (_) {}

    try {
      await _profileViewModel.deleteAccount(displayName: state.data.queueName);
      await AppPreferences.setLoggedIn(false);
      emit(
        ProfileSuccess(
          data: state.data.copyWith(
            didDeleteAccount: true,
            didLogout: false,
            showBugReportNotice: false,
            isSubmittingBugReport: false,
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
          didLogout: false,
          didDeleteAccount: false,
        ),
      ),
    );
  }
}
