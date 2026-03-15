import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../viewmodel/chat_view_model.dart';
import '../../../core/utils/paged_result.dart';
import '../models/chat_thread.dart';
import 'chat_badge_event.dart';
import 'chat_badge_state.dart';

class ChatBadgeBloc extends Bloc<ChatBadgeEvent, ChatBadgeState> {
  ChatBadgeBloc({required ChatViewModel chatViewModel})
      : _chatViewModel = chatViewModel,
        super(const ChatBadgeState.initial()) {
    on<ChatBadgeStarted>(_onStarted);
    on<ChatBadgeStopped>(_onStopped);
    on<ChatBadgeUpdated>(_onUpdated);
  }

  static const int _pageSize = 20;

  final ChatViewModel _chatViewModel;
  StreamSubscription<PagedResult<ChatThread>>? _subscription;

  void _onStarted(
    ChatBadgeStarted event,
    Emitter<ChatBadgeState> emit,
  ) {
    if (_subscription != null) {
      return;
    }
    try {
      _subscription = _chatViewModel
          .watchDirectThreadsPage(limit: _pageSize)
          .listen((page) {
        add(ChatBadgeUpdated(page: page));
      });
    } catch (_) {
      emit(state.copyWith(isLoading: false, hasUnread: false));
    }
  }

  void _onUpdated(
    ChatBadgeUpdated event,
    Emitter<ChatBadgeState> emit,
  ) {
    final hasUnread = event.page.items.any((thread) => thread.unreadCount > 0);
    emit(state.copyWith(hasUnread: hasUnread, isLoading: false));
  }

  Future<void> _onStopped(
    ChatBadgeStopped event,
    Emitter<ChatBadgeState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    emit(state.copyWith(hasUnread: false, isLoading: false));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
