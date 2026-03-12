import '../../models/notification_item.dart';

abstract class NotificationsRepository {
  Stream<List<NotificationItem>> watchNotifications();

  Future<void> markAsRead(String notificationId);
}
