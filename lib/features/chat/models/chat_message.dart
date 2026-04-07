import 'package:equatable/equatable.dart';

enum ChatMessageType { user, system }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.type = ChatMessageType.user,
  });

  final String id;
  final String senderName;
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final ChatMessageType type;

  bool get isSystem => type == ChatMessageType.system;

  ChatMessage copyWith({
    String? id,
    String? senderName,
    String? message,
    bool? isMe,
    DateTime? timestamp,
    ChatMessageType? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    senderName,
    message,
    isMe,
    timestamp,
    type,
  ];
}
