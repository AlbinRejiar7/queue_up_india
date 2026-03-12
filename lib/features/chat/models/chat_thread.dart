import 'package:equatable/equatable.dart';

class ChatThread extends Equatable {
  const ChatThread({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerAvatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final String peerId;
  final String peerName;
  final String peerAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  ChatThread copyWith({
    String? id,
    String? peerId,
    String? peerName,
    String? peerAvatarUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatThread(
      id: id ?? this.id,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    peerId,
    peerName,
    peerAvatarUrl,
    lastMessage,
    lastMessageAt,
    unreadCount,
  ];
}
