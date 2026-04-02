import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_preferences.dart';
import '../viewmodel/game_view_model.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({required GameViewModel gameViewModel})
    : _gameViewModel = gameViewModel,
      super(const GameInitial()) {
    on<GamesRequested>(_onGamesRequested);
    on<GameSelected>(_onGameSelected);
  }

  final GameViewModel _gameViewModel;

  Future<void> _onGamesRequested(
    GamesRequested event,
    Emitter<GameState> emit,
  ) async {
    emit(GameLoading(data: state.data));

    try {
      final games = await _gameViewModel.loadPopularGames();
      final savedGameId = await AppPreferences.loadSelectedGameId();
      final hasSavedGame =
          savedGameId != null && games.any((game) => game.id == savedGameId);
      final selectedGameId =
          state.data.selectedGameId ??
          (hasSavedGame
              ? savedGameId
              : (games.isEmpty ? null : games.first.id));
      emit(
        GameSuccess(
          data: state.data.copyWith(
            games: games,
            selectedGameId: selectedGameId,
          ),
        ),
      );
    } catch (_) {
      emit(GameError(message: AppStrings.gameLoadFailed, data: state.data));
    }
  }

  Future<void> _onGameSelected(
    GameSelected event,
    Emitter<GameState> emit,
  ) async {
    if (event.gameId.trim().isNotEmpty) {
      await AppPreferences.saveSelectedGameId(event.gameId);
    }
    emit(GameSuccess(data: state.data.copyWith(selectedGameId: event.gameId)));
  }
}
