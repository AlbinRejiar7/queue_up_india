import 'package:equatable/equatable.dart';

abstract class AvailablePlayersEvent extends Equatable {
  const AvailablePlayersEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class AvailablePlayersLoaded extends AvailablePlayersEvent {
  const AvailablePlayersLoaded();
}

class AvailablePlayersGameChanged extends AvailablePlayersEvent {
  const AvailablePlayersGameChanged({this.gameId});

  final String? gameId;

  @override
  List<Object?> get props => <Object?>[gameId];
}

class AvailablePlayersRankChanged extends AvailablePlayersEvent {
  const AvailablePlayersRankChanged({this.rank});

  final String? rank;

  @override
  List<Object?> get props => <Object?>[rank];
}

class AvailablePlayersLanguageChanged extends AvailablePlayersEvent {
  const AvailablePlayersLanguageChanged({this.language});

  final String? language;

  @override
  List<Object?> get props => <Object?>[language];
}

class AvailablePlayersReset extends AvailablePlayersEvent {
  const AvailablePlayersReset();
}
