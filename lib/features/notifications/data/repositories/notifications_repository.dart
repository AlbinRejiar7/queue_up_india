import '../../models/notification_item.dart';

abstract class NotificationsRepository {
  Stream<List<NotificationItem>> watchNotifications();

  Future<void> markAsRead(String notificationId);

  Future<void> sendChatRequest({
    required String targetUserId,
    required String gameId,
    required String rank,
    required String language,
    required String title,
    required String body,
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
