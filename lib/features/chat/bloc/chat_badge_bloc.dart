import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/direct_chat_monitor_service.dart';
import '../utils/direct_chat_firebase_debug.dart';
import 'chat_badge_event.dart';
import 'chat_badge_state.dart';

class ChatBadgeBloc extends Bloc<ChatBadgeEvent, ChatBadgeState> {
  ChatBadgeBloc({required DirectChatMonitorService directChatMonitorService})
    : _directChatMonitorService = directChatMonitorService,
      super(const ChatBadgeState.initial()) {
    on<ChatBadgeStarted>(_onStarted);
    on<ChatBadgeStopped>(_onStopped);
    on<ChatBadgeUpdated>(_onUpdated);
  }

  final DirectChatMonitorService _directChatMonitorService;
  StreamSubscription<bool>? _subscription;

  void _onStarted(ChatBadgeStarted event, Emitter<ChatBadgeState> emit) {
    if (_subscription != null) {
      return;
    }
    try {
      DirectChatFirebaseDebug.info(
        'ChatBadgeBloc._onStarted',
        'start unread listener',
      );
      _directChatMonitorService.start();
      emit(
        state.copyWith(
          hasUnread: _directChatMonitorService.currentHasUnread,
          isLoading: false,
        ),
      );
      _subscription = _directChatMonitorService.hasUnreadStream.listen((
        hasUnread,
      ) {
        add(ChatBadgeUpdated(hasUnread: hasUnread));
      });
    } catch (_) {
      emit(state.copyWith(isLoading: false, hasUnread: false));
    }
  }

  void _onUpdated(ChatBadgeUpdated event, Emitter<ChatBadgeState> emit) {
    emit(state.copyWith(hasUnread: event.hasUnread, isLoading: false));
  }

  Future<void> _onStopped(
    ChatBadgeStopped event,
    Emitter<ChatBadgeState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    DirectChatFirebaseDebug.info(
      'ChatBadgeBloc._onStopped',
      'stop unread listener',
    );
    emit(state.copyWith(isLoading: false));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
