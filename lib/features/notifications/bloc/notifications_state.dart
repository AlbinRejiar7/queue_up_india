import 'package:equatable/equatable.dart';

import '../../home/models/available_player_model.dart';
import '../models/notification_item.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.notifications = const <NotificationItem>[],
    this.isLoading = true,
    this.pendingChatPlayer,
    this.actionMessage,
    this.actionSuccess,
  });

  final List<NotificationItem> notifications;
  final bool isLoading;
  final AvailablePlayerModel? pendingChatPlayer;
  final String? actionMessage;
  final bool? actionSuccess;

  bool get hasUnread => notifications.any((item) => !item.isRead);

  bool get hasPendingRequests =>
      notifications.any(
        (item) => item.isChatRequest && item.isPending && !item.isRead,
      );

  NotificationsState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
    AvailablePlayerModel? pendingChatPlayer,
    bool clearPendingChatPlayer = false,
    String? actionMessage,
    bool clearActionMessage = false,
    bool? actionSuccess,
    bool clearActionSuccess = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      pendingChatPlayer: clearPendingChatPlayer
          ? null
          : pendingChatPlayer ?? this.pendingChatPlayer,
      actionMessage:
          clearActionMessage ? null : actionMessage ?? this.actionMessage,
      actionSuccess:
          clearActionSuccess ? null : actionSuccess ?? this.actionSuccess,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    notifications,
    isLoading,
    pendingChatPlayer,
    actionMessage,
    actionSuccess,
  ];
}
