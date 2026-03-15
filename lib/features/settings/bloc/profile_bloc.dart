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
            didLogout: false,
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
          didLogout: false,
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
          didLogout: false,
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
          didLogout: false,
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
      emit(ProfileSuccess(data: state.data.copyWith(showSavedNotice: true)));
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
        data: state.data.copyWith(showSavedNotice: false, didLogout: false),
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
    emit(ProfileSuccess(data: state.data.copyWith(didLogout: true)));
  }

  void _onProfileLogoutConsumed(
    ProfileLogoutConsumed event,
    Emitter<ProfileState> emit,
  ) {
    emit(ProfileSuccess(data: state.data.copyWith(didLogout: false)));
  }
}
