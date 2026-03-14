import 'package:equatable/equatable.dart';

import '../models/notification_item.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

class NotificationsUpdated extends NotificationsEvent {
  const NotificationsUpdated({required this.notifications});

  final List<NotificationItem> notifications;

  @override
  List<Object?> get props => <Object?>[notifications];
}

class NotificationReadRequested extends NotificationsEvent {
  const NotificationReadRequested({required this.notificationId});

  final String notificationId;

  @override
  List<Object?> get props => <Object?>[notificationId];
}

class NotificationsMarkAllReadRequested extends NotificationsEvent {
  const NotificationsMarkAllReadRequested();
}

class NotificationDismissed extends NotificationsEvent {
  const NotificationDismissed({required this.notificationId});

  final String notificationId;

  @override
  List<Object?> get props => <Object?>[notificationId];
}

class NotificationsClearedRequested extends NotificationsEvent {
  const NotificationsClearedRequested();
}

class NotificationRequestAccepted extends NotificationsEvent {
  const NotificationRequestAccepted({required this.notification});

  final NotificationItem notification;

  @override
  List<Object?> get props => <Object?>[notification];
}

class NotificationRequestDeclined extends NotificationsEvent {
  const NotificationRequestDeclined({required this.notification});

  final NotificationItem notification;

  @override
  List<Object?> get props => <Object?>[notification];
}

class NotificationsActionCleared extends NotificationsEvent {
  const NotificationsActionCleared();
}
