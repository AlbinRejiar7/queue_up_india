import 'package:equatable/equatable.dart';

abstract class ChatBadgeEvent extends Equatable {
  const ChatBadgeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ChatBadgeStarted extends ChatBadgeEvent {
  const ChatBadgeStarted();
}

class ChatBadgeStopped extends ChatBadgeEvent {
  const ChatBadgeStopped();
}

class ChatBadgeUpdated extends ChatBadgeEvent {
  const ChatBadgeUpdated({required this.hasUnread});

  final bool hasUnread;

  @override
  List<Object?> get props => <Object?>[hasUnread];
}
