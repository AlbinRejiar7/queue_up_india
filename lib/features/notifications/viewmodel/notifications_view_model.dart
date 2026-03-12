import '../data/repositories/notifications_repository.dart';
import '../models/notification_item.dart';

class NotificationsViewModel {
  NotificationsViewModel({required NotificationsRepository repository})
    : _repository = repository;

  final NotificationsRepository _repository;

  Stream<List<NotificationItem>> watchNotifications() {
    return _repository.watchNotifications();
  }

  Future<void> markAsRead(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}
