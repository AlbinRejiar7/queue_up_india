import 'package:equatable/equatable.dart';

import '../../../core/constants/app_options.dart';
import '../models/matchmaking_status.dart';
import '../models/solo_matchmaking_metadata_model.dart';
import '../models/solo_matchmaking_session_model.dart';
import '../models/solo_squad_model.dart';

enum MatchmakingUiPhase { setup, searching, squadFound, confirmed }

class MatchmakingState extends Equatable {
  const MatchmakingState({
    required this.currentUserId,
    required this.selectedGameId,
    required this.selectedRankId,
    required this.selectedLanguageId,
    required this.isSubmitting,
    required this.playersFound,
    required this.estimatedSeconds,
    required this.acceptSecondsRemaining,
    required this.searchSecondsElapsed,
    required this.showLowQueueFallback,
    this.session,
    this.metadata,
    this.squad,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  MatchmakingState.initial({required String currentUserId})
    : this(
        currentUserId: currentUserId,
        selectedGameId: AppOptions.valorantId,
        selectedRankId: AppOptions.defaultRankForGame(AppOptions.valorantId).name,
        selectedLanguageId: AppOptions.languageOptions.first,
        isSubmitting: false,
        playersFound: 1,
        estimatedSeconds: 35,
        acceptSecondsRemaining: 0,
        searchSecondsElapsed: 0,
        showLowQueueFallback: false,
      );

  final String currentUserId;
  final String selectedGameId;
  final String selectedRankId;
  final String selectedLanguageId;
  final bool isSubmitting;
  final int playersFound;
  final int estimatedSeconds;
  final int acceptSecondsRemaining;
  final int searchSecondsElapsed;
  final bool showLowQueueFallback;
  final SoloMatchmakingSessionModel? session;
  final SoloMatchmakingMetadataModel? metadata;
  final SoloSquadModel? squad;
  final String? feedbackMessage;
  final bool feedbackIsError;

  MatchmakingUiPhase get phase {
    if (isSubmitting && session == null) {
      return MatchmakingUiPhase.searching;
    }
    if (squad?.status == MatchmakingStatus.confirmed ||
        session?.status == MatchmakingStatus.confirmed) {
      return MatchmakingUiPhase.confirmed;
    }
    if (session?.status == MatchmakingStatus.waiting ||
        session?.status == MatchmakingStatus.acceptedWaiting) {
      return MatchmakingUiPhase.squadFound;
    }
    if (session?.status == MatchmakingStatus.searching) {
      return MatchmakingUiPhase.searching;
    }
    return MatchmakingUiPhase.setup;
  }

  bool get currentUserAccepted {
    final activeSquad = squad;
    if (activeSquad == null) {
      return false;
    }
    return activeSquad.isAcceptedBy(currentUserId);
  }

  MatchmakingState copyWith({
    String? selectedGameId,
    String? selectedRankId,
    String? selectedLanguageId,
    bool? isSubmitting,
    int? playersFound,
    int? estimatedSeconds,
    int? acceptSecondsRemaining,
    int? searchSecondsElapsed,
    bool? showLowQueueFallback,
    SoloMatchmakingSessionModel? session,
    bool clearSession = false,
    SoloMatchmakingMetadataModel? metadata,
    bool clearMetadata = false,
    SoloSquadModel? squad,
    bool clearSquad = false,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? feedbackIsError,
  }) {
    return MatchmakingState(
      currentUserId: currentUserId,
      selectedGameId: selectedGameId ?? this.selectedGameId,
      selectedRankId: selectedRankId ?? this.selectedRankId,
      selectedLanguageId: selectedLanguageId ?? this.selectedLanguageId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      playersFound: playersFound ?? this.playersFound,
      estimatedSeconds: estimatedSeconds ?? this.estimatedSeconds,
      acceptSecondsRemaining:
          acceptSecondsRemaining ?? this.acceptSecondsRemaining,
      searchSecondsElapsed: searchSecondsElapsed ?? this.searchSecondsElapsed,
      showLowQueueFallback:
          showLowQueueFallback ?? this.showLowQueueFallback,
      session: clearSession ? null : session ?? this.session,
      metadata: clearMetadata ? null : metadata ?? this.metadata,
      squad: clearSquad ? null : squad ?? this.squad,
      feedbackMessage:
          clearFeedback ? null : feedbackMessage ?? this.feedbackMessage,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    currentUserId,
    selectedGameId,
    selectedRankId,
    selectedLanguageId,
    isSubmitting,
    playersFound,
    estimatedSeconds,
    acceptSecondsRemaining,
    searchSecondsElapsed,
    showLowQueueFallback,
    session,
    metadata,
    squad,
    feedbackMessage,
    feedbackIsError,
  ];
}
