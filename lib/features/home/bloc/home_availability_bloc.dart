import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_options.dart';
import '../../settings/viewmodel/profile_view_model.dart';
import '../models/available_player_model.dart';
import '../viewmodel/availability_view_model.dart';
import 'home_availability_event.dart';
import 'home_availability_state.dart';

class HomeAvailabilityBloc
    extends Bloc<HomeAvailabilityEvent, HomeAvailabilityState> {
  HomeAvailabilityBloc({
    required AvailabilityViewModel availabilityViewModel,
    required ProfileViewModel profileViewModel,
  })  : _availabilityViewModel = availabilityViewModel,
        _profileViewModel = profileViewModel,
      super(const HomeAvailabilityState.initial()) {
    on<HomeAvailabilityInitialized>(_onInitialized);
    on<HomeAvailabilityGameChanged>(_onGameChanged);
    on<HomeAvailabilityLanguageChanged>(_onLanguageChanged);
    on<HomeAvailabilityRankChanged>(_onRankChanged);
    on<HomeAvailabilityToggled>(_onToggled);
  }

  final AvailabilityViewModel _availabilityViewModel;
  final ProfileViewModel _profileViewModel;

  Future<void> _onInitialized(
    HomeAvailabilityInitialized event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    final nextGameId = event.gameId?.trim();
    final resolvedGameId =
        (nextGameId == null || nextGameId.isEmpty)
            ? (state.selectedGameId ?? AppOptions.valorantId)
            : nextGameId;

    String? resolvedLanguage = state.selectedLanguage;
    if (resolvedLanguage == null) {
      resolvedLanguage = await _resolvePreferredLanguage();
    }

    final availability = await _safeFetchAvailability();
    String? selectedGameId = resolvedGameId;
    String? selectedRank = state.selectedRank;
    String? selectedLanguage = resolvedLanguage ?? state.selectedLanguage;

    if (availability != null) {
      if (availability.gameId.isNotEmpty) {
        selectedGameId = availability.gameId;
      }
      if (availability.rank.isNotEmpty) {
        selectedRank = availability.rank;
      }
      if (availability.language.isNotEmpty) {
        selectedLanguage = availability.language;
      }
    }

    final isRankValid = AppOptions.isRankValidForGame(
      gameId: selectedGameId ?? AppOptions.valorantId,
      rankName: selectedRank,
    );

    final nextState = state.copyWith(
      selectedGameId: selectedGameId,
      selectedLanguage: selectedLanguage,
      selectedRank: selectedRank,
      clearRank: !isRankValid,
      isAvailable: availability != null && isRankValid && selectedLanguage != null,
    );
    emit(nextState);
  }

  Future<void> _onGameChanged(
    HomeAvailabilityGameChanged event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    final gameId = event.gameId.trim();
    if (gameId.isEmpty) {
      return;
    }

    final isRankValid = AppOptions.isRankValidForGame(
      gameId: gameId,
      rankName: state.selectedRank,
    );

    final nextState = state.copyWith(
      selectedGameId: gameId,
      clearRank: !isRankValid,
      isAvailable: _ensureAvailability(state, isRankValid),
    );
    emit(nextState);

    if (nextState.isAvailable && nextState.canToggleAvailability) {
      final ok = await _updateAvailability(nextState);
      if (!ok) {
        emit(nextState.copyWith(isAvailable: false));
      }
    } else if (state.isAvailable && !nextState.isAvailable) {
      await _updateAvailability(nextState);
    }
  }

  Future<void> _onLanguageChanged(
    HomeAvailabilityLanguageChanged event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    final nextState = _syncAvailability(
      state.copyWith(
        selectedLanguage: event.language,
        clearLanguage: event.language == null,
      ),
    );
    emit(nextState);
    if (nextState.isAvailable && nextState.canToggleAvailability) {
      final ok = await _updateAvailability(nextState);
      if (!ok) {
        emit(nextState.copyWith(isAvailable: false));
      }
    } else if (state.isAvailable && !nextState.isAvailable) {
      await _updateAvailability(nextState);
    }
  }

  Future<void> _onRankChanged(
    HomeAvailabilityRankChanged event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    final nextState = _syncAvailability(
      state.copyWith(
        selectedRank: event.rank,
        clearRank: event.rank == null,
      ),
    );
    emit(nextState);
    if (nextState.isAvailable && nextState.canToggleAvailability) {
      final ok = await _updateAvailability(nextState);
      if (!ok) {
        emit(nextState.copyWith(isAvailable: false));
      }
    } else if (state.isAvailable && !nextState.isAvailable) {
      await _updateAvailability(nextState);
    }
  }

  Future<void> _onToggled(
    HomeAvailabilityToggled event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    if (!state.canToggleAvailability) {
      emit(state.copyWith(isAvailable: false));
      return;
    }

    final nextState = state.copyWith(isAvailable: !state.isAvailable);
    emit(nextState);
    final ok = await _updateAvailability(nextState);
    if (!ok) {
      emit(nextState.copyWith(isAvailable: false));
    }
  }

  HomeAvailabilityState _syncAvailability(HomeAvailabilityState nextState) {
    if (!nextState.canToggleAvailability && nextState.isAvailable) {
      return nextState.copyWith(isAvailable: false);
    }
    return nextState;
  }

  bool _ensureAvailability(HomeAvailabilityState currentState, bool rankValid) {
    if (currentState.isAvailable) {
      return currentState.selectedLanguage != null && rankValid;
    }
    return currentState.isAvailable;
  }

  Future<bool> _updateAvailability(HomeAvailabilityState current) async {
    if (current.isAvailable && !current.canToggleAvailability) {
      return false;
    }
    try {
      await _availabilityViewModel.updateAvailability(
        isAvailable: current.isAvailable,
        gameId: current.selectedGameId ?? AppOptions.valorantId,
        rank: current.selectedRank ?? '',
        language: current.selectedLanguage ?? '',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AvailablePlayerModel?> _safeFetchAvailability() async {
    try {
      return await _availabilityViewModel.fetchCurrentAvailability();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolvePreferredLanguage() async {
    try {
      final preferences = await _profileViewModel.loadPreferences();
      final languages = await _profileViewModel.loadLanguages();
      final preferred = preferences.preferredLanguageCode;
      for (final language in languages) {
        if (language.code == preferred) {
          final label = language.englishLabel;
          if (AppOptions.languageOptions.contains(label)) {
            return label;
          }
          break;
        }
      }
    } catch (_) {}
    return null;
  }
}
