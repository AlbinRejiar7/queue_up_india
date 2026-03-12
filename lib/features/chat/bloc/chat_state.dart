import 'package:equatable/equatable.dart';

import '../models/chat_message.dart';

class ChatState extends Equatable {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.oldestCursor,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? oldestCursor;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? oldestCursor,
    bool clearOldestCursor = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      oldestCursor: clearOldestCursor
          ? null
          : oldestCursor ?? this.oldestCursor,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    messages,
    isLoading,
    isLoadingMore,
    hasMore,
    oldestCursor,
  ];
}
