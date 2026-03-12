import 'package:equatable/equatable.dart';

import '../models/chat_message.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ChatMessageSent extends ChatEvent {
  const ChatMessageSent({required this.message});

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class ChatMessageReceived extends ChatEvent {
  const ChatMessageReceived({required this.message});

  final ChatMessage message;

  @override
  List<Object?> get props => <Object?>[message];
}
