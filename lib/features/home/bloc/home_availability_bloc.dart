import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_options.dart';
import 'home_availability_event.dart';
import 'home_availability_state.dart';

class HomeAvailabilityBloc
    extends Bloc<HomeAvailabilityEvent, HomeAvailabilityState> {
  HomeAvailabilityBloc() : super(const HomeAvailabilityState.initial()) {
    on<HomeAvailabilityInitialized>(_onInitialized);
    on<HomeAvailabilityGameChanged>(_onGameChanged);
    on<HomeAvailabilityLanguageChanged>(_onLanguageChanged);
    on<HomeAvailabilityRankChanged>(_onRankChanged);
    on<HomeAvailabilityToggled>(_onToggled);
  }

  void _onInitialized(
    HomeAvailabilityInitialized event,
    Emitter<HomeAvailabilityState> emit,
  ) {
    final nextGameId = event.gameId?.trim();
    if (nextGameId == null || nextGameId.isEmpty) {
      if (state.selectedGameId == null) {
        emit(state.copyWith(selectedGameId: AppOptions.valorantId));
      }
      return;
    }

    if (nextGameId == state.selectedGameId) {
      return;
    }

    final isRankValid = AppOptions.isRankValidForGame(
      gameId: nextGameId,
      rankName: state.selectedRank,
    );

    emit(
      state.copyWith(
        selectedGameId: nextGameId,
        clearRank: !isRankValid,
        isAvailable: _ensureAvailability(state, isRankValid),
      ),
    );
  }

  void _onGameChanged(
    HomeAvailabilityGameChanged event,
    Emitter<HomeAvailabilityState> emit,
  ) {
    final gameId = event.gameId.trim();
    if (gameId.isEmpty) {
      return;
    }

    final isRankValid = AppOptions.isRankValidForGame(
      gameId: gameId,
      rankName: state.selectedRank,
    );

    emit(
      state.copyWith(
        selectedGameId: gameId,
        clearRank: !isRankValid,
        isAvailable: _ensureAvailability(state, isRankValid),
      ),
    );
  }

  void _onLanguageChanged(
    HomeAvailabilityLanguageChanged event,
    Emitter<HomeAvailabilityState> emit,
  ) {
    emit(
      _syncAvailability(
        state.copyWith(
          selectedLanguage: event.language,
          clearLanguage: event.language == null,
        ),
      ),
    );
  }

  void _onRankChanged(
    HomeAvailabilityRankChanged event,
    Emitter<HomeAvailabilityState> emit,
  ) {
    emit(
      _syncAvailability(
        state.copyWith(
          selectedRank: event.rank,
          clearRank: event.rank == null,
        ),
      ),
    );
  }

  void _onToggled(
    HomeAvailabilityToggled event,
    Emitter<HomeAvailabilityState> emit,
  ) {
    if (!state.canToggleAvailability) {
      emit(state.copyWith(isAvailable: false));
      return;
    }

    emit(state.copyWith(isAvailable: !state.isAvailable));
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
}
