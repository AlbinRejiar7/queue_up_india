import 'package:equatable/equatable.dart';

class NotificationItem extends Equatable {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.type,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? type;

  bool get isRead => readAt != null;

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    DateTime? readAt,
    String? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      type: type ?? this.type,
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
  ];
}
