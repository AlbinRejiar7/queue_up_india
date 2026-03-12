import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.currentUserName,
    required this.replyName,
    required this.dummyReply,
    List<ChatMessage> initialMessages = const <ChatMessage>[],
  }) : super(ChatState(messages: initialMessages)) {
    on<ChatMessageSent>(_onMessageSent);
    on<ChatMessageReceived>(_onMessageReceived);
  }

  final String currentUserName;
  final String replyName;
  final String dummyReply;

  Future<void> _onMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final text = event.message.trim();
    if (text.isEmpty) {
      return;
    }

    final message = ChatMessage(
      id: _nextId(),
      senderName: currentUserName,
      message: text,
      isMe: true,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(messages: <ChatMessage>[...state.messages, message]));

    final replyText = dummyReply.trim();
    if (replyText.isEmpty) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (isClosed) {
      return;
    }

    add(
      ChatMessageReceived(
        message: ChatMessage(
          id: _nextId(),
          senderName: replyName,
          message: replyText,
          isMe: false,
          timestamp: DateTime.now(),
        ),
      ),
    );
  }

  void _onMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        messages: <ChatMessage>[...state.messages, event.message],
      ),
    );
  }

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();
}
