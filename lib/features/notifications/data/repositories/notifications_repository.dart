import '../../models/notification_item.dart';

abstract class NotificationsRepository {
  Stream<List<NotificationItem>> watchNotifications();

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead();

  Future<void> deleteNotification(String notificationId);

  Future<void> clearNotifications();

  Future<void> sendChatRequest({
    required String targetUserId,
    required String gameId,
    required String rank,
    required String language,
    required String title,
    required String body,
  });

  Future<bool> hasPendingChatRequest({
    required String targetUserId,
    required String fromUserId,
  });

  Future<bool> hasIncomingChatRequest({
    required String targetUserId,
    required String fromUserId,
  });

  Future<void> sendChatRequestResponse({
    required String targetUserId,
    required String status,
    required String title,
    required String body,
    String? gameId,
    String? rank,
    String? language,
  });

  Future<void> updateNotificationStatus({
    required String notificationId,
    required String status,
  });
}
