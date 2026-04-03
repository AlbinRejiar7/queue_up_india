import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_options.dart';
import '../../../core/constants/app_strings.dart';
import '../models/available_player_model.dart';
import '../viewmodel/available_players_view_model.dart';
import '../../notifications/viewmodel/notifications_view_model.dart';
import '../../chat/viewmodel/chat_view_model.dart';
import 'available_players_event.dart';
import 'available_players_state.dart';

class AvailablePlayersBloc
    extends Bloc<AvailablePlayersEvent, AvailablePlayersState> {
  AvailablePlayersBloc({
    required AvailablePlayersViewModel availablePlayersViewModel,
    required NotificationsViewModel notificationsViewModel,
    required ChatViewModel chatViewModel,
  }) : _availablePlayersViewModel = availablePlayersViewModel,
       _notificationsViewModel = notificationsViewModel,
       _chatViewModel = chatViewModel,
       super(const AvailablePlayersState.initial()) {
    on<AvailablePlayersLoaded>(_onLoaded);
    on<AvailablePlayersLoadMoreRequested>(_onLoadMore);
    on<AvailablePlayersGameChanged>(_onGameChanged);
    on<AvailablePlayersRankChanged>(_onRankChanged);
    on<AvailablePlayersLanguageChanged>(_onLanguageChanged);
    on<AvailablePlayersReset>(_onReset);
    on<AvailablePlayersRefreshRequested>(_onRefresh);
    on<AvailablePlayersRequestSent>(_onRequestSent);
    on<AvailablePlayersRequestMessageCleared>(_onRequestMessageCleared);
  }

  final AvailablePlayersViewModel _availablePlayersViewModel;
  final NotificationsViewModel _notificationsViewModel;
  final ChatViewModel _chatViewModel;
  static const int _pageSize = 10;

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
    final cursor = state.cursor;
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
      final combined = _mergePlayers(state.players, page.items);
      emit(
        state.copyWith(
          players: combined,
          cursor: page.nextCursor,
          hasMore: page.hasMore,
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
      state.copyWith(selectedRank: event.rank, clearRank: event.rank == null),
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
      state.copyWith(clearGameId: true, clearRank: true, clearLanguage: true),
    );
    await _reloadWithFilters(emit);
  }

  Future<void> _onRefresh(
    AvailablePlayersRefreshRequested event,
    Emitter<AvailablePlayersState> emit,
  ) async {
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
        clearRequestMessageType: true,
        clearRequestActionPeerId: true,
      ),
    );
    try {
      final hasChat = await _chatViewModel.hasDirectChat(
        peerId: event.player.id,
      );
      if (hasChat) {
        emit(
          state.copyWith(
            isRequesting: false,
            requestMessage: AppStrings.chatAlreadyExists(event.player.name),
            requestSuccess: null,
            requestMessageType: RequestMessageType.info,
            requestActionPeerId: event.player.id,
          ),
        );
        return;
      }

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
            requestMessageType: RequestMessageType.error,
            requestActionPeerId: null,
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
            requestMessageType: RequestMessageType.error,
            requestActionPeerId: null,
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
          requestMessageType: RequestMessageType.success,
          requestActionPeerId: null,
        ),
      );
    } on StateError catch (error) {
      final isBlockedError = error.message == 'Blocked user';
      emit(
        state.copyWith(
          isRequesting: false,
          requestMessage: isBlockedError
              ? AppStrings.blockedChatDisabled
              : AppStrings.chatRequestFailed,
          requestSuccess: false,
          requestMessageType: RequestMessageType.error,
          requestActionPeerId: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isRequesting: false,
          requestMessage: AppStrings.chatRequestFailed,
          requestSuccess: false,
          requestMessageType: RequestMessageType.error,
          requestActionPeerId: null,
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
        clearRequestMessageType: true,
        clearRequestActionPeerId: true,
      ),
    );
  }

  Future<void> _reloadWithFilters(Emitter<AvailablePlayersState> emit) async {
    emit(
      state.copyWith(
        isLoading: true,
        isLoadingMore: false,
        hasMore: true,
        clearCursor: true,
        players: const <AvailablePlayerModel>[],
      ),
    );

    try {
      final page = await _availablePlayersViewModel.loadAvailablePlayersPage(
        gameId: state.selectedGameId,
        rank: state.selectedRank,
        language: state.selectedLanguage,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          players: page.items,
          cursor: page.nextCursor,
          hasMore: page.hasMore,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          players: const <AvailablePlayerModel>[],
          clearCursor: true,
          hasMore: false,
          isLoading: false,
        ),
      );
    }
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
}
