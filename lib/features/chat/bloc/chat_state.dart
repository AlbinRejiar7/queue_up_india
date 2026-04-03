import 'package:equatable/equatable.dart';

import '../models/chat_message.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.oldestCursor,
    this.sendErrorMessage,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? oldestCursor;
  final String? sendErrorMessage;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? oldestCursor,
    String? sendErrorMessage,
    bool clearOldestCursor = false,
    bool clearSendErrorMessage = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      oldestCursor: clearOldestCursor
          ? null
          : oldestCursor ?? this.oldestCursor,
      sendErrorMessage: clearSendErrorMessage
          ? null
          : sendErrorMessage ?? this.sendErrorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    messages,
    isLoading,
    isLoadingMore,
    hasMore,
    oldestCursor,
    sendErrorMessage,
  ];
}
