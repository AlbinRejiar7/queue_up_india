import 'package:equatable/equatable.dart';

import '../models/notification_item.dart';

class NotificationsState extends Equatable {
  const NotificationsState({
    this.notifications = const <NotificationItem>[],
    this.isLoading = true,
  });

  final List<NotificationItem> notifications;
  final bool isLoading;

  NotificationsState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => <Object?>[notifications, isLoading];
}
