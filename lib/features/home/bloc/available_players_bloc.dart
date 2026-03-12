import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_options.dart';
import '../models/available_player_model.dart';
import 'available_players_event.dart';
import 'available_players_state.dart';

class AvailablePlayersBloc
    extends Bloc<AvailablePlayersEvent, AvailablePlayersState> {
  AvailablePlayersBloc() : super(const AvailablePlayersState.initial()) {
    on<AvailablePlayersLoaded>(_onLoaded);
    on<AvailablePlayersGameChanged>(_onGameChanged);
    on<AvailablePlayersRankChanged>(_onRankChanged);
    on<AvailablePlayersLanguageChanged>(_onLanguageChanged);
    on<AvailablePlayersReset>(_onReset);
  }

  static const List<AvailablePlayerModel> _seedPlayers =
      <AvailablePlayerModel>[
        AvailablePlayerModel(
          id: 'ap_001',
          name: 'ViperRavi',
          gameId: AppOptions.valorantId,
          rank: 'Diamond 2',
          language: 'Hindi',
        ),
        AvailablePlayerModel(
          id: 'ap_002',
          name: 'RushNeon',
          gameId: AppOptions.valorantId,
          rank: 'Platinum 1',
          language: 'English',
        ),
        AvailablePlayerModel(
          id: 'ap_003',
          name: 'BGMI_Scorch',
          gameId: AppOptions.pubgId,
          rank: 'Ace',
          language: 'Tamil',
        ),
        AvailablePlayerModel(
          id: 'ap_004',
          name: 'DropMasterIN',
          gameId: AppOptions.pubgId,
          rank: 'Crown',
          language: 'Telugu',
        ),
      ];

  void _onLoaded(
    AvailablePlayersLoaded event,
    Emitter<AvailablePlayersState> emit,
  ) {
    final stateWithPlayers = state.copyWith(allPlayers: _seedPlayers);
    emit(_applyFilters(stateWithPlayers));
  }

  void _onGameChanged(
    AvailablePlayersGameChanged event,
    Emitter<AvailablePlayersState> emit,
  ) {
    final gameId = event.gameId;
    final shouldClearRank =
        gameId == null ||
        !AppOptions.isRankValidForGame(
          gameId: gameId,
          rankName: state.selectedRank,
        );

    emit(
      _applyFilters(
        state.copyWith(
          selectedGameId: gameId,
          clearGameId: gameId == null,
          clearRank: shouldClearRank,
        ),
      ),
    );
  }

  void _onRankChanged(
    AvailablePlayersRankChanged event,
    Emitter<AvailablePlayersState> emit,
  ) {
    emit(
      _applyFilters(
        state.copyWith(
          selectedRank: event.rank,
          clearRank: event.rank == null,
        ),
      ),
    );
  }

  void _onLanguageChanged(
    AvailablePlayersLanguageChanged event,
    Emitter<AvailablePlayersState> emit,
  ) {
    emit(
      _applyFilters(
        state.copyWith(
          selectedLanguage: event.language,
          clearLanguage: event.language == null,
        ),
      ),
    );
  }

  void _onReset(
    AvailablePlayersReset event,
    Emitter<AvailablePlayersState> emit,
  ) {
    emit(
      _applyFilters(
        state.copyWith(
          clearGameId: true,
          clearRank: true,
          clearLanguage: true,
        ),
      ),
    );
  }

  AvailablePlayersState _applyFilters(AvailablePlayersState nextState) {
    final filtered = nextState.allPlayers.where((player) {
      final matchesGame = nextState.selectedGameId == null ||
          player.gameId == nextState.selectedGameId;
      final matchesRank = nextState.selectedRank == null ||
          player.rank == nextState.selectedRank;
      final matchesLanguage = nextState.selectedLanguage == null ||
          player.language == nextState.selectedLanguage;
      return matchesGame && matchesRank && matchesLanguage;
    }).toList(growable: false);

    return nextState.copyWith(filteredPlayers: filtered);
  }
}
