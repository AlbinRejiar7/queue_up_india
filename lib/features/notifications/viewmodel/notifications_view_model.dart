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

  Future<void> sendChatRequest({
    required String targetUserId,
    required String gameId,
    required String rank,
    required String language,
    required String title,
    required String body,
  }) {
    return _repository.sendChatRequest(
      targetUserId: targetUserId,
      gameId: gameId,
      rank: rank,
      language: language,
      title: title,
      body: body,
    );
  }

  Future<void> sendChatRequestResponse({
    required String targetUserId,
    required String status,
    required String title,
    required String body,
    String? gameId,
    String? rank,
    String? language,
  }) {
    return _repository.sendChatRequestResponse(
      targetUserId: targetUserId,
      status: status,
      title: title,
      body: body,
      gameId: gameId,
      rank: rank,
      language: language,
    );
  }

  Future<void> updateNotificationStatus({
    required String notificationId,
    required String status,
  }) {
    return _repository.updateNotificationStatus(
      notificationId: notificationId,
      status: status,
    );
  }
}
