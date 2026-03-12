import 'package:equatable/equatable.dart';

import '../../../core/utils/paged_result.dart';
import '../models/available_player_model.dart';

abstract class AvailablePlayersEvent extends Equatable {
  const AvailablePlayersEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class AvailablePlayersLoaded extends AvailablePlayersEvent {
  const AvailablePlayersLoaded();
}

class AvailablePlayersLoadMoreRequested extends AvailablePlayersEvent {
  const AvailablePlayersLoadMoreRequested();
}

class AvailablePlayersLivePageUpdated extends AvailablePlayersEvent {
  const AvailablePlayersLivePageUpdated({required this.page});

  final PagedResult<AvailablePlayerModel> page;

  @override
  List<Object?> get props => <Object?>[page];
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
