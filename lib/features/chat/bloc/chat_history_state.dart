import 'package:equatable/equatable.dart';

import '../models/chat_thread.dart';

class ChatHistoryState extends Equatable {
  const ChatHistoryState({
    this.threads = const <ChatThread>[],
    this.cursor,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
  });

  const ChatHistoryState.initial() : this();

  final List<ChatThread> threads;
  final Object? cursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;

  ChatHistoryState copyWith({
    List<ChatThread>? threads,
    Object? cursor,
    bool clearCursor = false,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
  }) {
    return ChatHistoryState(
      threads: threads ?? this.threads,
      cursor: clearCursor ? null : cursor ?? this.cursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    threads,
    cursor,
    hasMore,
    isLoading,
    isLoadingMore,
  ];
}
