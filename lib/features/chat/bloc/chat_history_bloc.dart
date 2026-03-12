import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/paged_result.dart';
import '../models/chat_thread.dart';
import '../viewmodel/chat_view_model.dart';
import 'chat_history_event.dart';
import 'chat_history_state.dart';

class ChatHistoryBloc extends Bloc<ChatHistoryEvent, ChatHistoryState> {
  ChatHistoryBloc({required ChatViewModel chatViewModel})
      : _chatViewModel = chatViewModel,
        super(const ChatHistoryState.initial()) {
    on<ChatHistoryStarted>(_onStarted);
    on<ChatHistoryLoadMoreRequested>(_onLoadMore);
    on<ChatHistoryLivePageUpdated>(_onLiveUpdated);
    add(const ChatHistoryStarted());
  }

  static const int _pageSize = 10;

  final ChatViewModel _chatViewModel;
  StreamSubscription<PagedResult<ChatThread>>? _liveSubscription;
  List<ChatThread> _liveThreads = const <ChatThread>[];
  List<ChatThread> _olderThreads = const <ChatThread>[];
  Object? _liveCursor;
  Object? _olderCursor;
  bool _liveHasMore = true;
  bool _olderHasMore = true;

  Future<void> _onStarted(
    ChatHistoryStarted event,
    Emitter<ChatHistoryState> emit,
  ) async {
    if (state.isLoading || state.threads.isNotEmpty) {
      return;
    }
    await _reload(emit);
  }

  Future<void> _onLoadMore(
    ChatHistoryLoadMoreRequested event,
    Emitter<ChatHistoryState> emit,
  ) async {
    if (state.isLoadingMore || state.isLoading || !state.hasMore) {
      return;
    }
    final cursor = _olderThreads.isEmpty ? _liveCursor : _olderCursor;
    if (cursor == null) {
      emit(state.copyWith(hasMore: false, isLoadingMore: false));
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _chatViewModel.fetchDirectThreadsPage(
        cursor: cursor,
        limit: _pageSize,
      );
      _olderThreads = <ChatThread>[
        ..._olderThreads,
        ...page.items,
      ];
      _olderCursor = page.nextCursor;
      _olderHasMore = page.hasMore;
      final combined = _mergeThreads(_liveThreads, _olderThreads);
      emit(
        state.copyWith(
          threads: combined,
          cursor: _olderCursor ?? _liveCursor,
          hasMore: _olderHasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _onLiveUpdated(
    ChatHistoryLivePageUpdated event,
    Emitter<ChatHistoryState> emit,
  ) {
    _liveThreads = event.page.items;
    _liveCursor = event.page.nextCursor;
    _liveHasMore = event.page.hasMore;

    if (_liveThreads.isNotEmpty && _olderThreads.isNotEmpty) {
      final liveIds = _liveThreads.map((thread) => thread.id).toSet();
      _olderThreads = _olderThreads
          .where((thread) => !liveIds.contains(thread.id))
          .toList();
    }

    final combined = _mergeThreads(_liveThreads, _olderThreads);
    final effectiveCursor =
        _olderThreads.isEmpty ? _liveCursor : _olderCursor;
    final effectiveHasMore =
        _olderThreads.isEmpty ? _liveHasMore : _olderHasMore;

    emit(
      state.copyWith(
        threads: combined,
        cursor: effectiveCursor,
        hasMore: effectiveHasMore,
        isLoading: false,
      ),
    );
  }

  Future<void> _reload(Emitter<ChatHistoryState> emit) async {
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    _liveThreads = const <ChatThread>[];
    _olderThreads = const <ChatThread>[];
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
        threads: const <ChatThread>[],
      ),
    );

    _liveSubscription = _chatViewModel
        .watchDirectThreadsPage(limit: _pageSize)
        .listen((page) {
      add(ChatHistoryLivePageUpdated(page: page));
    });
  }

  List<ChatThread> _mergeThreads(
    List<ChatThread> live,
    List<ChatThread> older,
  ) {
    final byId = <String, ChatThread>{};
    for (final thread in live) {
      byId[thread.id] = thread;
    }
    for (final thread in older) {
      byId.putIfAbsent(thread.id, () => thread);
    }
    final combined = byId.values.toList();
    combined.sort(
      (a, b) => b.lastMessageAt.compareTo(a.lastMessageAt),
    );
    return combined;
  }

  @override
  Future<void> close() async {
    await _liveSubscription?.cancel();
    return super.close();
  }
}
