import 'package:equatable/equatable.dart';

import '../../../core/utils/paged_result.dart';
import '../models/chat_thread.dart';

abstract class ChatBadgeEvent extends Equatable {
  const ChatBadgeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ChatBadgeStarted extends ChatBadgeEvent {
  const ChatBadgeStarted();
}

class ChatBadgeUpdated extends ChatBadgeEvent {
  const ChatBadgeUpdated({required this.page});

  final PagedResult<ChatThread> page;

  @override
  List<Object?> get props => <Object?>[page];
}
