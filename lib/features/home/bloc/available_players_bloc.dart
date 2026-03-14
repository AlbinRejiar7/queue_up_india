import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_options.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/paged_result.dart';
import '../models/available_player_model.dart';
import '../viewmodel/available_players_view_model.dart';
import '../../notifications/viewmodel/notifications_view_model.dart';
import 'available_players_event.dart';
import 'available_players_state.dart';

class AvailablePlayersBloc
    extends Bloc<AvailablePlayersEvent, AvailablePlayersState> {
  AvailablePlayersBloc({
    required AvailablePlayersViewModel availablePlayersViewModel,
    required NotificationsViewModel notificationsViewModel,
  })  : _availablePlayersViewModel = availablePlayersViewModel,
        _notificationsViewModel = notificationsViewModel,
        super(const AvailablePlayersState.initial()) {
    on<AvailablePlayersLoaded>(_onLoaded);
    on<AvailablePlayersLoadMoreRequested>(_onLoadMore);
    on<AvailablePlayersLivePageUpdated>(_onLivePageUpdated);
    on<AvailablePlayersGameChanged>(_onGameChanged);
    on<AvailablePlayersRankChanged>(_onRankChanged);
    on<AvailablePlayersLanguageChanged>(_onLanguageChanged);
    on<AvailablePlayersReset>(_onReset);
    on<AvailablePlayersRequestSent>(_onRequestSent);
    on<AvailablePlayersRequestMessageCleared>(_onRequestMessageCleared);
  }

  final AvailablePlayersViewModel _availablePlayersViewModel;
  final NotificationsViewModel _notificationsViewModel;
  static const int _pageSize = 10;
  StreamSubscription<PagedResult<AvailablePlayerModel>>? _liveSubscription;
  List<AvailablePlayerModel> _livePlayers = const <AvailablePlayerModel>[];
  List<AvailablePlayerModel> _olderPlayers = const <AvailablePlayerModel>[];
  Object? _liveCursor;
  Object? _olderCursor;
  bool _liveHasMore = true;
  bool _olderHasMore = true;

  Future<void> _onLoaded(
    AvailablePlayersLoaded event,
    Emitter<AvailablePlayersState> emit,
  ) async {
    if (state.isLoading || state.players.isNotEmpty) {
      return;
    }
    await _reloadWithFilters(emit);
  }

  Future<void> _onLoadMore(
    AvailablePlayersLoadMoreRequested event,
    Emitter<AvailablePlayersState> emit,
  ) async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) {
      return;
    }
    final cursor = _olderPlayers.isEmpty ? _liveCursor : _olderCursor;
    if (cursor == null) {
      emit(state.copyWith(hasMore: false, isLoadingMore: false));
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _availablePlayersViewModel.loadAvailablePlayersPage(
        gameId: state.selectedGameId,
        rank: state.selectedRank,
        language: state.selectedLanguage,
        cursor: cursor,
        limit: _pageSize,
      );
      _olderPlayers = <AvailablePlayerModel>[
        ..._olderPlayers,
        ...page.items,
      ];
      _olderCursor = page.nextCursor;
      _olderHasMore = page.hasMore;
      final combined = _mergePlayers(_livePlayers, _olderPlayers);
      emit(
        state.copyWith(
          players: combined,
          cursor: _olderCursor ?? _liveCursor,
          hasMore: _olderHasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onGameChanged(
    AvailablePlayersGameChanged event,
    Emitter<AvailablePlayersState> emit,
  ) async {
    final gameId = event.gameId;
    final shouldClearRank =
        gameId == null ||
        !AppOptions.isRankValidForGame(
          gameId: gameId,
          rankName: state.selectedRank,
        );

    emit(
      state.copyWith(
        selectedGameId: gameId,
        clearGameId: gameId == null,
        clearRank: shouldClearRank,
      ),
    );
    await _reloadWithFilters(emit);
  }

  Future<void> _onRankChanged(
    AvailablePlayersRankChanged event,
    Emitter<AvailablePlayersState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedRank: event.rank,
        clearRank: event.rank == null,
      ),
    );
    await _reloadWithFilters(emit);
  }

  Future<void> _onLanguageChanged(
    AvailablePlayersLanguageChanged event,
    Emitter<AvailablePlayersState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedLanguage: event.language,
        clearLanguage: event.language == null,
      ),
    );
    await _reloadWithFilters(emit);
  }

  Future<void> _onReset(
    AvailablePlayersReset event,
    Emitter<AvailablePlayersState> emit,
  ) async {
    emit(
      state.copyWith(
        clearGameId: true,
        clearRank: true,
        clearLanguage: true,
      ),
    );
    await _reloadWithFilters(emit);
  }

  Future<void> _onRequestSent(
    AvailablePlayersRequestSent event,
    Emitter<AvailablePlayersState> emit,
  ) async {
    if (state.isRequesting) {
      return;
    }
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      emit(
        state.copyWith(
          requestMessage: AppStrings.chatRequestFailed,
          requestSuccess: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isRequesting: true,
        clearRequestMessage: true,
        clearRequestSuccess: true,
      ),
    );
    try {
      final alreadySent = await _notificationsViewModel.hasPendingChatRequest(
        targetUserId: event.player.id,
        fromUserId: currentUserId,
      );
      if (alreadySent) {
        emit(
          state.copyWith(
            isRequesting: false,
            requestMessage: AppStrings.chatRequestAlreadySent,
            requestSuccess: false,
          ),
        );
        return;
      }

      final incomingRequest = await _notificationsViewModel
          .hasIncomingChatRequest(
            targetUserId: event.player.id,
            fromUserId: currentUserId,
          );
      if (incomingRequest) {
        emit(
          state.copyWith(
            isRequesting: false,
            requestMessage: AppStrings.chatRequestIncomingExists(
              event.player.name,
            ),
            requestSuccess: false,
          ),
        );
        return;
      }

      await _notificationsViewModel.sendChatRequest(
        targetUserId: event.player.id,
        gameId: event.player.gameId,
        rank: event.player.rank,
        language: event.player.language,
        title: AppStrings.chatRequestTitle,
        body: AppStrings.chatRequestBody(event.player.name),
      );
      emit(
        state.copyWith(
          isRequesting: false,
          requestMessage: AppStrings.chatRequestSent,
          requestSuccess: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isRequesting: false,
          requestMessage: AppStrings.chatRequestFailed,
          requestSuccess: false,
        ),
      );
    }
  }

  void _onRequestMessageCleared(
    AvailablePlayersRequestMessageCleared event,
    Emitter<AvailablePlayersState> emit,
  ) {
    emit(
      state.copyWith(
        clearRequestMessage: true,
        clearRequestSuccess: true,
      ),
    );
  }

  void _onLivePageUpdated(
    AvailablePlayersLivePageUpdated event,
    Emitter<AvailablePlayersState> emit,
  ) {
    _livePlayers = event.page.items;
    _liveCursor = event.page.nextCursor;
    _liveHasMore = event.page.hasMore;

    if (_livePlayers.isNotEmpty && _olderPlayers.isNotEmpty) {
      final liveIds = _livePlayers.map((player) => player.id).toSet();
      _olderPlayers = _olderPlayers
          .where((player) => !liveIds.contains(player.id))
          .toList();
    }

    final combined = _mergePlayers(_livePlayers, _olderPlayers);
    final effectiveCursor =
        _olderPlayers.isEmpty ? _liveCursor : _olderCursor;
    final effectiveHasMore =
        _olderPlayers.isEmpty ? _liveHasMore : _olderHasMore;

    emit(
      state.copyWith(
        players: combined,
        cursor: effectiveCursor,
        hasMore: effectiveHasMore,
        isLoading: false,
      ),
    );
  }

  Future<void> _reloadWithFilters(Emitter<AvailablePlayersState> emit) async {
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    _livePlayers = const <AvailablePlayerModel>[];
    _olderPlayers = const <AvailablePlayerModel>[];
    _liveCursor = null;
    _olderCursor = null;
    _liveHasMore = true;
    _olderHasMore = true;

    emit(
      state.copyWith(
        isLoading: true,
        isLoadingMore: false,
        hasMore: true,
        clearCursor: true,
        players: const <AvailablePlayerModel>[],
      ),
    );

    _liveSubscription = _availablePlayersViewModel
        .watchAvailablePlayersPage(
          gameId: state.selectedGameId,
          rank: state.selectedRank,
          language: state.selectedLanguage,
          limit: _pageSize,
        )
        .listen((page) {
          add(AvailablePlayersLivePageUpdated(page: page));
        });
  }

  List<AvailablePlayerModel> _mergePlayers(
    List<AvailablePlayerModel> live,
    List<AvailablePlayerModel> older,
  ) {
    final seen = <String>{};
    final combined = <AvailablePlayerModel>[];
    for (final player in live) {
      if (seen.add(player.id)) {
        combined.add(player);
      }
    }
    for (final player in older) {
      if (seen.add(player.id)) {
        combined.add(player);
      }
    }
    return combined;
  }

  @override
  Future<void> close() async {
    await _liveSubscription?.cancel();
    return super.close();
  }
}
