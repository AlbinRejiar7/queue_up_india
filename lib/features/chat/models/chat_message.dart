import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.message,
    required this.isMe,
    required this.timestamp,
  });

  final String id;
  final String senderName;
  final String message;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage copyWith({
    String? id,
    String? senderName,
    String? message,
    bool? isMe,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        senderName,
        message,
        isMe,
        timestamp,
      ];
}
