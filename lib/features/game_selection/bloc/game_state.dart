import 'package:equatable/equatable.dart';

import '../models/game_model.dart';

class GameViewData extends Equatable {
  const GameViewData({required this.games, this.selectedGameId});

  const GameViewData.initial()
    : games = const <GameModel>[],
      selectedGameId = null;

  final List<GameModel> games;
  final String? selectedGameId;

  GameViewData copyWith({
    List<GameModel>? games,
    String? selectedGameId,
    bool clearSelectedGameId = false,
  }) {
    return GameViewData(
      games: games ?? this.games,
      selectedGameId: clearSelectedGameId
          ? null
          : selectedGameId ?? this.selectedGameId,
    );
  }

  @override
  List<Object?> get props => <Object?>[games, selectedGameId];
}

abstract class GameState extends Equatable {
  const GameState({required this.data});

  final GameViewData data;

  @override
  List<Object?> get props => <Object?>[data];
}

class GameInitial extends GameState {
  const GameInitial() : super(data: const GameViewData.initial());
}

class GameLoading extends GameState {
  const GameLoading({required super.data});
}

class GameSuccess extends GameState {
  const GameSuccess({required super.data});
}

class GameError extends GameState {
  const GameError({required this.message, required super.data});

  final String message;

  @override
  List<Object?> get props => <Object?>[data, message];
}
