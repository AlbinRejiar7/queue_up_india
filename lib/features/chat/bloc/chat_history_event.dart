import 'package:equatable/equatable.dart';

import '../../../core/utils/paged_result.dart';
import '../models/chat_thread.dart';

sealed class ChatHistoryEvent extends Equatable {
  const ChatHistoryEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class ChatHistoryStarted extends ChatHistoryEvent {
  const ChatHistoryStarted();
}

class ChatHistoryLoadMoreRequested extends ChatHistoryEvent {
  const ChatHistoryLoadMoreRequested();
}

class ChatHistoryLivePageUpdated extends ChatHistoryEvent {
  const ChatHistoryLivePageUpdated({required this.page});

  final PagedResult<ChatThread> page;

  @override
  List<Object?> get props => <Object?>[page];
}
