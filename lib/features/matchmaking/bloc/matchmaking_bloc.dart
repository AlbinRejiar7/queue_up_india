import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_options.dart';
import '../../../core/constants/app_strings.dart';
import '../models/matchmaking_status.dart';
import '../models/solo_matchmaking_metadata_model.dart';
import '../models/solo_matchmaking_session_model.dart';
import '../models/solo_squad_model.dart';
import '../viewmodel/matchmaking_view_model.dart';
import 'matchmaking_event.dart';
import 'matchmaking_state.dart';

class MatchmakingBloc extends Bloc<MatchmakingEvent, MatchmakingState> {
  static const int _lowQueueFallbackAfterSeconds = 25;

  MatchmakingBloc({required MatchmakingViewModel matchmakingViewModel})
    : _matchmakingViewModel = matchmakingViewModel,
      super(
        MatchmakingState.initial(
          currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
      ) {
    on<MatchmakingInitialized>(_onInitialized);
    on<MatchmakingRankChanged>(_onRankChanged);
    on<MatchmakingGameChanged>(_onGameChanged);
    on<MatchmakingLanguageChanged>(_onLanguageChanged);
    on<MatchmakingStartRequested>(_onStartRequested);
    on<MatchmakingCancelRequested>(_onCancelRequested);
    on<MatchmakingAcceptRequested>(_onAcceptRequested);
    on<MatchmakingRejectRequested>(_onRejectRequested);
    on<MatchmakingSessionUpdated>(_onSessionUpdated);
    on<MatchmakingMetadataUpdated>(_onMetadataUpdated);
    on<MatchmakingSquadUpdated>(_onSquadUpdated);
    on<MatchmakingCountdownTicked>(_onCountdownTicked);
    on<MatchmakingSearchTicked>(_onSearchTicked);
    on<MatchmakingKeepWaitingRequested>(_onKeepWaitingRequested);
    on<MatchmakingFeedbackConsumed>(_onFeedbackConsumed);
  }

  final MatchmakingViewModel _matchmakingViewModel;
  StreamSubscription<SoloMatchmakingSessionModel?>? _sessionSubscription;
  StreamSubscription<SoloMatchmakingMetadataModel?>? _metadataSubscription;
  StreamSubscription<SoloSquadModel?>? _squadSubscription;
  Timer? _countdownTimer;
  Timer? _searchTimer;
  String? _currentBucketId;
  String? _currentSquadId;

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    await _metadataSubscription?.cancel();
    await _squadSubscription?.cancel();
    _countdownTimer?.cancel();
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _onInitialized(
    MatchmakingInitialized event,
    Emitter<MatchmakingState> emit,
  ) async {
    final resolvedRank = _resolveRank(
      gameId: event.gameId,
      rankId: event.initialRank,
    );
    final resolvedLanguage = _resolveLanguage(event.initialLanguage);
    emit(
      state.copyWith(
        selectedGameId: event.gameId,
        selectedRankId: resolvedRank,
        selectedLanguageId: resolvedLanguage,
        isSubmitting: event.autoStart,
        searchSecondsElapsed: 0,
        showLowQueueFallback: false,
      ),
    );

    await _sessionSubscription?.cancel();
    _sessionSubscription = _matchmakingViewModel.watchCurrentSession().listen((
      session,
    ) {
      add(MatchmakingSessionUpdated(session));
    });

    final existingSession = await _matchmakingViewModel.getCurrentSession();
    if (existingSession != null) {
      add(MatchmakingSessionUpdated(existingSession));
      return;
    }

    if (event.autoStart) {
      add(const MatchmakingStartRequested());
    }
  }

  void _onRankChanged(
    MatchmakingRankChanged event,
    Emitter<MatchmakingState> emit,
  ) {
    emit(state.copyWith(selectedRankId: event.rankId));
  }

  void _onGameChanged(
    MatchmakingGameChanged event,
    Emitter<MatchmakingState> emit,
  ) {
    emit(
      state.copyWith(
        selectedGameId: event.gameId,
        selectedRankId: AppOptions.defaultRankForGame(event.gameId).name,
      ),
    );
  }

  void _onLanguageChanged(
    MatchmakingLanguageChanged event,
    Emitter<MatchmakingState> emit,
  ) {
    emit(state.copyWith(selectedLanguageId: event.languageId));
  }

  Future<void> _onStartRequested(
    MatchmakingStartRequested event,
    Emitter<MatchmakingState> emit,
  ) async {
    if (state.session?.isActive == true) {
      _stopSearchTimer();
      emit(state.copyWith(isSubmitting: false));
      return;
    }
    emit(
      state.copyWith(
        isSubmitting: true,
        searchSecondsElapsed: 0,
        showLowQueueFallback: false,
        clearFeedback: true,
      ),
    );
    _startSearchTimer();
    try {
      await _matchmakingViewModel.startSoloQueue(
        gameId: state.selectedGameId,
        rankId: state.selectedRankId,
        languageId: state.selectedLanguageId,
      );
      emit(state.copyWith(isSubmitting: false));
    } catch (error) {
      _stopSearchTimer();
      emit(
        state.copyWith(
          isSubmitting: false,
          searchSecondsElapsed: 0,
          showLowQueueFallback: false,
          feedbackMessage: _formatError(error),
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onCancelRequested(
    MatchmakingCancelRequested event,
    Emitter<MatchmakingState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      await _matchmakingViewModel.cancelSoloQueue();
      emit(
        state.copyWith(
          isSubmitting: false,
          feedbackMessage: AppStrings.matchmakingCancelled,
          feedbackIsError: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          feedbackMessage: _formatError(error),
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onAcceptRequested(
    MatchmakingAcceptRequested event,
    Emitter<MatchmakingState> emit,
  ) async {
    final squadId = state.session?.squadId ?? state.squad?.id;
    if (squadId == null || squadId.isEmpty) {
      return;
    }
    emit(state.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      await _matchmakingViewModel.acceptSquad(squadId: squadId);
      emit(state.copyWith(isSubmitting: false));
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          feedbackMessage: _formatError(error),
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onRejectRequested(
    MatchmakingRejectRequested event,
    Emitter<MatchmakingState> emit,
  ) async {
    final squadId = state.session?.squadId ?? state.squad?.id;
    if (squadId == null || squadId.isEmpty) {
      return;
    }
    emit(state.copyWith(isSubmitting: true, clearFeedback: true));
    try {
      await _matchmakingViewModel.rejectSquad(squadId: squadId);
      emit(state.copyWith(isSubmitting: false));
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          feedbackMessage: _formatError(error),
          feedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onSessionUpdated(
    MatchmakingSessionUpdated event,
    Emitter<MatchmakingState> emit,
  ) async {
    final session = event.session;
    await _syncMetadataSubscription(session?.bucketId, session?.status);
    await _syncSquadSubscription(session?.squadId, session?.status);

    if (session == null) {
      _stopCountdown();
      _stopSearchTimer();
      emit(
        state.copyWith(
          clearSession: true,
          clearMetadata: true,
          clearSquad: true,
          acceptSecondsRemaining: 0,
          playersFound: 1,
          estimatedSeconds: _estimateSecondsFromQueue(1),
          searchSecondsElapsed: 0,
          showLowQueueFallback: false,
        ),
      );
      return;
    }

    if (session.status == MatchmakingStatus.searching) {
      _startSearchTimer();
    } else {
      _stopSearchTimer();
    }

    emit(
      _deriveState(
        state.copyWith(
          session: session,
          isSubmitting: false,
        ),
      ),
    );
  }

  void _onMetadataUpdated(
    MatchmakingMetadataUpdated event,
    Emitter<MatchmakingState> emit,
  ) {
    emit(_deriveState(state.copyWith(metadata: event.metadata)));
  }

  void _onSquadUpdated(
    MatchmakingSquadUpdated event,
    Emitter<MatchmakingState> emit,
  ) {
    final nextState = _deriveState(
      state.copyWith(
        squad: event.squad,
        acceptSecondsRemaining: _resolveCountdown(event.squad),
      ),
    );
    emit(nextState);
    if (event.squad?.status == MatchmakingStatus.waiting) {
      _startCountdown();
    } else {
      _stopCountdown();
    }
  }

  Future<void> _onCountdownTicked(
    MatchmakingCountdownTicked event,
    Emitter<MatchmakingState> emit,
  ) async {
    final remaining = _resolveCountdown(state.squad);
    emit(state.copyWith(acceptSecondsRemaining: remaining));
    if (remaining > 0 || state.currentUserAccepted) {
      return;
    }
    add(const MatchmakingRejectRequested());
  }

  void _onSearchTicked(
    MatchmakingSearchTicked event,
    Emitter<MatchmakingState> emit,
  ) {
    final nextSeconds = state.searchSecondsElapsed + 1;
    emit(
      state.copyWith(
        searchSecondsElapsed: nextSeconds,
        showLowQueueFallback:
            state.showLowQueueFallback ||
            nextSeconds >= _lowQueueFallbackAfterSeconds,
      ),
    );
  }

  void _onKeepWaitingRequested(
    MatchmakingKeepWaitingRequested event,
    Emitter<MatchmakingState> emit,
  ) {
    emit(
      state.copyWith(
        searchSecondsElapsed: 0,
        showLowQueueFallback: false,
      ),
    );
  }

  void _onFeedbackConsumed(
    MatchmakingFeedbackConsumed event,
    Emitter<MatchmakingState> emit,
  ) {
    emit(state.copyWith(clearFeedback: true));
  }

  Future<void> _syncMetadataSubscription(
    String? bucketId,
    MatchmakingStatus? status,
  ) async {
    if (bucketId == _currentBucketId && status == MatchmakingStatus.searching) {
      return;
    }
    if (status != MatchmakingStatus.searching || bucketId == null) {
      _currentBucketId = null;
      await _metadataSubscription?.cancel();
      _metadataSubscription = null;
      return;
    }
    _currentBucketId = bucketId;
    await _metadataSubscription?.cancel();
    _metadataSubscription = _matchmakingViewModel
        .watchBucketMetadata(bucketId)
        .listen((metadata) {
          add(MatchmakingMetadataUpdated(metadata));
        });
  }

  Future<void> _syncSquadSubscription(
    String? squadId,
    MatchmakingStatus? status,
  ) async {
    final shouldListen = status == MatchmakingStatus.waiting ||
        status == MatchmakingStatus.acceptedWaiting ||
        status == MatchmakingStatus.confirmed;
    if (!shouldListen || squadId == null) {
      _currentSquadId = null;
      await _squadSubscription?.cancel();
      _squadSubscription = null;
      _stopCountdown();
      return;
    }
    if (squadId == _currentSquadId) {
      return;
    }
    _currentSquadId = squadId;
    await _squadSubscription?.cancel();
    _squadSubscription = _matchmakingViewModel.watchSquad(squadId).listen((squad) {
      add(MatchmakingSquadUpdated(squad));
    });
  }

  MatchmakingState _deriveState(MatchmakingState nextState) {
    final squad = nextState.squad;
    if (squad != null &&
        (squad.status == MatchmakingStatus.waiting ||
            squad.status == MatchmakingStatus.acceptedWaiting ||
            squad.status == MatchmakingStatus.confirmed)) {
      return nextState.copyWith(
        playersFound: squad.participants.length,
        estimatedSeconds: 0,
        acceptSecondsRemaining: _resolveCountdown(squad),
      );
    }

    final queueSize = max(
      nextState.metadata?.activeUsers ?? 0,
      nextState.session?.queueSize ?? 1,
    );
    return nextState.copyWith(
      playersFound: min(max(queueSize, 1), 4),
      estimatedSeconds: nextState.session?.estimatedSeconds ??
          _estimateSecondsFromQueue(queueSize),
      acceptSecondsRemaining: 0,
      showLowQueueFallback:
          nextState.showLowQueueFallback &&
          (nextState.session?.status == MatchmakingStatus.searching ||
              nextState.isSubmitting),
      clearSquad: nextState.session?.status == MatchmakingStatus.searching ||
          nextState.session == null,
    );
  }

  int _estimateSecondsFromQueue(int queueSize) {
    if (queueSize >= 4) {
      return 5;
    }
    if (queueSize == 3) {
      return 12;
    }
    if (queueSize == 2) {
      return 20;
    }
    return 35;
  }

  int _resolveCountdown(SoloSquadModel? squad) {
    final deadline = squad?.acceptDeadlineAt;
    if (deadline == null) {
      return 0;
    }
    final difference = deadline.difference(DateTime.now()).inSeconds;
    return max(difference, 0);
  }

  void _startCountdown() {
    if (_countdownTimer != null) {
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const MatchmakingCountdownTicked());
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _startSearchTimer() {
    if (_searchTimer != null) {
      return;
    }
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const MatchmakingSearchTicked());
    });
  }

  void _stopSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = null;
  }

  String _resolveRank({
    required String gameId,
    required String? rankId,
  }) {
    if (rankId != null &&
        AppOptions.isRankValidForGame(gameId: gameId, rankName: rankId)) {
      return rankId;
    }
    return AppOptions.defaultRankForGame(gameId).name;
  }

  String _resolveLanguage(String? languageId) {
    if (languageId != null && AppOptions.languageOptions.contains(languageId)) {
      return languageId;
    }
    return AppOptions.languageOptions.first;
  }

  String _formatError(Object error) {
    final raw = error.toString();
    if (raw.contains('already in an active squad')) {
      return AppStrings.matchmakingAlreadyActive;
    }
    if (raw.contains('already in a party')) {
      return AppStrings.matchmakingPartyConflict;
    }
    return raw.replaceFirst('Exception: ', '');
  }
}
