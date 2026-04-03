import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_timeouts.dart';
import '../../../core/constants/app_options.dart';
import '../../../core/utils/app_preferences.dart';
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
  }) : _availabilityViewModel = availabilityViewModel,
       _profileViewModel = profileViewModel,
       super(const HomeAvailabilityState.initial()) {
    on<HomeAvailabilityInitialized>(_onInitialized);
    on<HomeAvailabilityGameChanged>(_onGameChanged);
    on<HomeAvailabilityLanguageChanged>(_onLanguageChanged);
    on<HomeAvailabilityRankChanged>(_onRankChanged);
    on<HomeAvailabilityToggled>(_onToggled);
    on<HomeAvailabilitySyncRequested>(_onSyncRequested);
    on<HomeAvailabilityClearedExternally>(_onClearedExternally);
  }

  final AvailabilityViewModel _availabilityViewModel;
  final ProfileViewModel _profileViewModel;
  static const Duration _availabilitySyncDebounce = Duration(milliseconds: 600);
  Timer? _availabilityHeartbeatTimer;
  Timer? _availabilitySyncTimer;

  Future<void> _onInitialized(
    HomeAvailabilityInitialized event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    final nextGameId = event.gameId?.trim();
    final resolvedGameId = (nextGameId == null || nextGameId.isEmpty)
        ? (state.selectedGameId ?? AppOptions.valorantId)
        : nextGameId;

    String? resolvedLanguage = state.selectedLanguage;
    resolvedLanguage ??= await AppPreferences.loadSelectedLanguage();
    resolvedLanguage ??= await _resolvePreferredLanguage();

    final availability = await _safeFetchAvailability();
    String selectedGameId = resolvedGameId;
    String? selectedRank =
        state.selectedRank ?? await _loadSavedRank(resolvedGameId);
    String? selectedLanguage = resolvedLanguage;

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
      gameId: selectedGameId,
      rankName: selectedRank,
    );

    final nextState = state.copyWith(
      selectedGameId: selectedGameId,
      selectedLanguage: selectedLanguage,
      selectedRank: selectedRank,
      clearRank: !isRankValid,
      isAvailable:
          availability != null && isRankValid && selectedLanguage != null,
    );
    emit(nextState);
    await _persistSelections(
      gameId: nextState.selectedGameId,
      language: nextState.selectedLanguage,
      rank: nextState.selectedRank,
    );
    _syncAvailabilityHeartbeat(
      availability,
      isAvailable: nextState.isAvailable,
    );
  }

  Future<void> _onGameChanged(
    HomeAvailabilityGameChanged event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    final gameId = event.gameId.trim();
    if (gameId.isEmpty) {
      return;
    }

    final savedRank = await _loadSavedRank(gameId);
    final nextRank =
        AppOptions.isRankValidForGame(gameId: gameId, rankName: savedRank)
        ? savedRank
        : null;

    final nextState = _syncAvailability(
      state.copyWith(
        selectedGameId: gameId,
        selectedRank: nextRank,
        clearRank: nextRank == null,
      ),
    );
    emit(nextState);
    await AppPreferences.saveSelectedGameId(gameId);

    if (nextState.isAvailable && nextState.canToggleAvailability) {
      _scheduleAvailabilitySync();
    } else if (state.isAvailable && !nextState.isAvailable) {
      _clearAvailabilitySyncTimer();
      await _updateAvailability(nextState, startedNow: false);
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
    if (event.language == null) {
      await AppPreferences.clearSelectedLanguage();
    } else {
      await AppPreferences.saveSelectedLanguage(event.language!);
    }
    if (nextState.isAvailable && nextState.canToggleAvailability) {
      _scheduleAvailabilitySync();
    } else if (state.isAvailable && !nextState.isAvailable) {
      _clearAvailabilitySyncTimer();
      await _updateAvailability(nextState, startedNow: false);
    }
  }

  Future<void> _onRankChanged(
    HomeAvailabilityRankChanged event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    final nextState = _syncAvailability(
      state.copyWith(selectedRank: event.rank, clearRank: event.rank == null),
    );
    emit(nextState);
    final gameId = nextState.selectedGameId;
    if (gameId != null) {
      if (event.rank == null) {
        await AppPreferences.clearSelectedRank(gameId);
      } else {
        await AppPreferences.saveSelectedRank(
          gameId: gameId,
          rank: event.rank!,
        );
      }
    }
    if (nextState.isAvailable && nextState.canToggleAvailability) {
      _scheduleAvailabilitySync();
    } else if (state.isAvailable && !nextState.isAvailable) {
      _clearAvailabilitySyncTimer();
      await _updateAvailability(nextState, startedNow: false);
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

    _clearAvailabilitySyncTimer();
    final nextState = state.copyWith(isAvailable: !state.isAvailable);
    emit(nextState);
    final ok = await _updateAvailability(
      nextState,
      startedNow: nextState.isAvailable && !state.isAvailable,
    );
    if (!ok) {
      emit(nextState.copyWith(isAvailable: false));
      _clearAvailabilityHeartbeatTimer();
    }
  }

  Future<void> _onSyncRequested(
    HomeAvailabilitySyncRequested event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    _clearAvailabilitySyncTimer();
    final current = state;
    if (!current.isAvailable || !current.canToggleAvailability) {
      return;
    }

    final ok = await _updateAvailability(current, startedNow: false);
    if (!ok && !isClosed) {
      emit(current.copyWith(isAvailable: false));
      _clearAvailabilityHeartbeatTimer();
    }
  }

  Future<void> _onClearedExternally(
    HomeAvailabilityClearedExternally event,
    Emitter<HomeAvailabilityState> emit,
  ) async {
    _clearAvailabilitySyncTimer();
    _clearAvailabilityHeartbeatTimer();
    if (!state.isAvailable) {
      return;
    }
    emit(state.copyWith(isAvailable: false));
  }

  HomeAvailabilityState _syncAvailability(HomeAvailabilityState nextState) {
    if (!nextState.canToggleAvailability && nextState.isAvailable) {
      return nextState.copyWith(isAvailable: false);
    }
    return nextState;
  }

  Future<bool> _updateAvailability(
    HomeAvailabilityState current, {
    required bool startedNow,
  }) async {
    if (current.isAvailable && !current.canToggleAvailability) {
      return false;
    }
    try {
      await _availabilityViewModel.updateAvailability(
        isAvailable: current.isAvailable,
        gameId: current.selectedGameId ?? AppOptions.valorantId,
        rank: current.selectedRank ?? '',
        language: current.selectedLanguage ?? '',
        startedNow: startedNow,
      );
      if (current.isAvailable) {
        _scheduleAvailabilityHeartbeat(DateTime.now());
      } else {
        _clearAvailabilityHeartbeatTimer();
      }
      return true;
    } catch (_) {
      if (!current.isAvailable) {
        _clearAvailabilityHeartbeatTimer();
      }
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

  Future<String?> _loadSavedRank(String gameId) async {
    final savedRank = await AppPreferences.loadSelectedRank(gameId);
    if (savedRank == null) {
      return null;
    }
    if (!AppOptions.isRankValidForGame(gameId: gameId, rankName: savedRank)) {
      await AppPreferences.clearSelectedRank(gameId);
      return null;
    }
    return savedRank;
  }

  Future<void> _persistSelections({
    required String? gameId,
    required String? language,
    required String? rank,
  }) async {
    if (gameId != null && gameId.trim().isNotEmpty) {
      await AppPreferences.saveSelectedGameId(gameId);
      if (rank != null && rank.trim().isNotEmpty) {
        await AppPreferences.saveSelectedRank(gameId: gameId, rank: rank);
      }
    }

    if (language != null && language.trim().isNotEmpty) {
      await AppPreferences.saveSelectedLanguage(language);
    }
  }

  void _syncAvailabilityHeartbeat(
    AvailablePlayerModel? availability, {
    required bool isAvailable,
  }) {
    if (!isAvailable || availability == null) {
      _clearAvailabilityHeartbeatTimer();
      return;
    }
    _scheduleAvailabilityHeartbeat(availability.updatedAt);
  }

  void _scheduleAvailabilityHeartbeat(DateTime updatedAt) {
    _clearAvailabilityHeartbeatTimer();

    final nextHeartbeatAt = updatedAt.add(AppTimeouts.availabilityHeartbeat);
    final remaining = nextHeartbeatAt.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      add(const HomeAvailabilitySyncRequested());
      return;
    }

    _availabilityHeartbeatTimer = Timer(remaining, () {
      if (!isClosed) {
        add(const HomeAvailabilitySyncRequested());
      }
    });
  }

  void _clearAvailabilityHeartbeatTimer() {
    _availabilityHeartbeatTimer?.cancel();
    _availabilityHeartbeatTimer = null;
  }

  void _scheduleAvailabilitySync() {
    _availabilitySyncTimer?.cancel();
    _availabilitySyncTimer = Timer(_availabilitySyncDebounce, () {
      if (!isClosed) {
        add(const HomeAvailabilitySyncRequested());
      }
    });
  }

  void _clearAvailabilitySyncTimer() {
    _availabilitySyncTimer?.cancel();
    _availabilitySyncTimer = null;
  }

  @override
  Future<void> close() async {
    _clearAvailabilityHeartbeatTimer();
    _clearAvailabilitySyncTimer();
    return super.close();
  }
}
