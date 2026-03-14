import 'package:equatable/equatable.dart';

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.type,
    this.status,
    this.fromUserId,
    this.fromUserName,
    this.fromUserAvatar,
    this.gameId,
    this.rank,
    this.language,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? type;
  final String? status;
  final String? fromUserId;
  final String? fromUserName;
  final String? fromUserAvatar;
  final String? gameId;
  final String? rank;
  final String? language;

  static const String typeChatRequest = 'chat_request';
  static const String typeChatRequestResponse = 'chat_request_response';
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusDeclined = 'declined';

  bool get isRead => readAt != null;
  bool get isChatRequest => type == typeChatRequest;
  bool get isPending => status == statusPending;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? readAt,
    String? type,
    String? status,
    String? fromUserId,
    String? fromUserName,
    String? fromUserAvatar,
    String? gameId,
    String? rank,
    String? language,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      type: type ?? this.type,
      status: status ?? this.status,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserAvatar: fromUserAvatar ?? this.fromUserAvatar,
      gameId: gameId ?? this.gameId,
      rank: rank ?? this.rank,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    body,
    createdAt,
    readAt,
    type,
    status,
    fromUserId,
    fromUserName,
    fromUserAvatar,
    gameId,
    rank,
    language,
  ];
}
