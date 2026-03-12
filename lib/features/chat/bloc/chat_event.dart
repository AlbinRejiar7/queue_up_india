import 'package:equatable/equatable.dart';

import '../models/chat_message.dart';
import '../../../core/utils/paged_result.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ChatStarted extends ChatEvent {
  const ChatStarted();
}

class ChatMessageSent extends ChatEvent {
  const ChatMessageSent({required this.message});

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class ChatLatestPageUpdated extends ChatEvent {
  const ChatLatestPageUpdated({required this.page});

  final PagedResult<ChatMessage> page;

  @override
  List<Object?> get props => <Object?>[page];
}

class ChatLoadOlderRequested extends ChatEvent {
  const ChatLoadOlderRequested();
}
