import 'package:equatable/equatable.dart';

import '../models/solo_matchmaking_metadata_model.dart';
import '../models/solo_matchmaking_session_model.dart';
import '../models/solo_squad_model.dart';

abstract class MatchmakingEvent extends Equatable {
  const MatchmakingEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class MatchmakingInitialized extends MatchmakingEvent {
  const MatchmakingInitialized({
    required this.gameId,
    this.initialRank,
    this.initialLanguage,
    this.autoStart = false,
  });

  final String gameId;
  final String? initialRank;
  final String? initialLanguage;
  final bool autoStart;

  @override
  List<Object?> get props => <Object?>[
    gameId,
    initialRank,
    initialLanguage,
    autoStart,
  ];
}

class MatchmakingRankChanged extends MatchmakingEvent {
  const MatchmakingRankChanged(this.rankId);

  final String rankId;

  @override
  List<Object?> get props => <Object?>[rankId];
}

class MatchmakingGameChanged extends MatchmakingEvent {
  const MatchmakingGameChanged(this.gameId);

  final String gameId;

  @override
  List<Object?> get props => <Object?>[gameId];
}

class MatchmakingLanguageChanged extends MatchmakingEvent {
  const MatchmakingLanguageChanged(this.languageId);

  final String languageId;

  @override
  List<Object?> get props => <Object?>[languageId];
}

class MatchmakingStartRequested extends MatchmakingEvent {
  const MatchmakingStartRequested();
}

class MatchmakingCancelRequested extends MatchmakingEvent {
  const MatchmakingCancelRequested();
}

class MatchmakingAcceptRequested extends MatchmakingEvent {
  const MatchmakingAcceptRequested();
}

class MatchmakingRejectRequested extends MatchmakingEvent {
  const MatchmakingRejectRequested();
}

class MatchmakingSessionUpdated extends MatchmakingEvent {
  const MatchmakingSessionUpdated(this.session);

  final SoloMatchmakingSessionModel? session;

  @override
  List<Object?> get props => <Object?>[session];
}

class MatchmakingMetadataUpdated extends MatchmakingEvent {
  const MatchmakingMetadataUpdated(this.metadata);

  final SoloMatchmakingMetadataModel? metadata;

  @override
  List<Object?> get props => <Object?>[metadata];
}

class MatchmakingSquadUpdated extends MatchmakingEvent {
  const MatchmakingSquadUpdated(this.squad);

  final SoloSquadModel? squad;

  @override
  List<Object?> get props => <Object?>[squad];
}

class MatchmakingCountdownTicked extends MatchmakingEvent {
  const MatchmakingCountdownTicked();
}

class MatchmakingSearchTicked extends MatchmakingEvent {
  const MatchmakingSearchTicked();
}

class MatchmakingKeepWaitingRequested extends MatchmakingEvent {
  const MatchmakingKeepWaitingRequested();
}

class MatchmakingFeedbackConsumed extends MatchmakingEvent {
  const MatchmakingFeedbackConsumed();
}
