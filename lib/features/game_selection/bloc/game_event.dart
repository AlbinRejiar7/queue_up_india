import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class GamesRequested extends GameEvent {
  const GamesRequested();
}

class GameSelected extends GameEvent {
  const GameSelected({required this.gameId});

  final String gameId;

  @override
  List<Object?> get props => <Object?>[gameId];
}
