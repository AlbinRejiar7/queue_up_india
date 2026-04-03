import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/chat_message.dart';
import '../viewmodel/chat_view_model.dart';
import '../../../core/utils/paged_result.dart';
import '../../../core/services/in_app_alert_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required ChatViewModel chatViewModel,
    required ChatScope scope,
    required String targetId,
  }) : _chatViewModel = chatViewModel,
       _scope = scope,
       _targetId = targetId,
       super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatLatestPageUpdated>(_onLatestPageUpdated);
    on<ChatLoadOlderRequested>(_onLoadOlderRequested);
    add(const ChatStarted());
  }

  final ChatViewModel _chatViewModel;
  final ChatScope _scope;
  final String _targetId;
  StreamSubscription<PagedResult<ChatMessage>>? _subscription;
  bool _hasSeeded = false;
  static const int _pageSize = 10;

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    _subscription ??= _chatViewModel
        .watchLatestMessages(
          scope: _scope,
          targetId: _targetId,
          limit: _pageSize,
        )
        .listen((page) {
          add(ChatLatestPageUpdated(page: page));
        });
    if (_scope == ChatScope.direct) {
      await _markDirectRead();
    }
  }

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.message.trim();
    if (text.isEmpty) {
      return;
    }
    await _chatViewModel.sendMessage(
      scope: _scope,
      targetId: _targetId,
      message: text,
    );
  }

  void _onLatestPageUpdated(
    ChatLatestPageUpdated event,
    Emitter<ChatState> emit,
  ) {
    final latest = event.page.items;
    final shouldMarkReadForInitialDirectPage =
        _scope == ChatScope.direct &&
        state.messages.isEmpty &&
        latest.any((message) => !message.isMe);
    if (state.messages.isEmpty) {
      emit(
        state.copyWith(
          messages: latest,
          isLoading: false,
          oldestCursor: event.page.nextCursor,
          hasMore: event.page.hasMore,
        ),
      );
      _hasSeeded = true;
      if (shouldMarkReadForInitialDirectPage) {
        _markDirectRead();
      }
      return;
    }

    final latestById = <String, ChatMessage>{
      for (final message in latest) message.id: message,
    };
    final existingById = <String, ChatMessage>{
      for (final message in state.messages) message.id: message,
    };
    final updated = state.messages
        .map((message) => latestById[message.id] ?? message)
        .toList();

    final newMessages = latest
        .where((message) => !existingById.containsKey(message.id))
        .toList();
    if (newMessages.isNotEmpty) {
      updated.addAll(newMessages);
    }

    emit(
      state.copyWith(
        messages: updated,
        isLoading: false,
        hasMore: state.hasMore,
        oldestCursor: state.oldestCursor,
      ),
    );

    if (_scope == ChatScope.direct) {
      final hasIncoming = newMessages.any((message) => !message.isMe);
      if (hasIncoming) {
        _markDirectRead();
      }
      return;
    }

    if (!_hasSeeded) {
      _hasSeeded = true;
      return;
    }

    if (newMessages.isEmpty) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final hasIncoming = newMessages.any((message) => !message.isMe);
    if (uid != null && hasIncoming) {
      InAppAlertService.notify();
    }
  }

  Future<void> _onLoadOlderRequested(
    ChatLoadOlderRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore || state.oldestCursor == null) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _chatViewModel.fetchOlderMessages(
        scope: _scope,
        targetId: _targetId,
        cursor: state.oldestCursor,
        limit: _pageSize,
      );
      emit(
        state.copyWith(
          messages: <ChatMessage>[...page.items, ...state.messages],
          oldestCursor: page.nextCursor,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _markDirectRead() async {
    try {
      await _chatViewModel.markDirectChatRead(peerId: _targetId);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
