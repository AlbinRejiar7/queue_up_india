import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_options.dart';
import '../../../core/constants/app_strings.dart';
import '../../chat/viewmodel/chat_view_model.dart';
import '../../home/models/available_player_model.dart';
import '../models/notification_item.dart';
import '../viewmodel/notifications_view_model.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required NotificationsViewModel notificationsViewModel,
    required ChatViewModel chatViewModel,
  })  : _notificationsViewModel = notificationsViewModel,
        _chatViewModel = chatViewModel,
        super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsUpdated>(_onUpdated);
    on<NotificationReadRequested>(_onReadRequested);
    on<NotificationsMarkAllReadRequested>(_onMarkAllReadRequested);
    on<NotificationDismissed>(_onNotificationDismissed);
    on<NotificationsClearedRequested>(_onNotificationsCleared);
    on<NotificationRequestAccepted>(_onRequestAccepted);
    on<NotificationRequestDeclined>(_onRequestDeclined);
    on<NotificationsActionCleared>(_onActionCleared);
  }

  final NotificationsViewModel _notificationsViewModel;
  final ChatViewModel _chatViewModel;
  StreamSubscription? _subscription;

  void _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) {
    _subscription ??= _notificationsViewModel
        .watchNotifications()
        .listen((notifications) {
          add(NotificationsUpdated(notifications: notifications));
        });
  }

  void _onUpdated(
    NotificationsUpdated event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      state.copyWith(
        notifications: event.notifications,
        isLoading: false,
      ),
    );
  }

  Future<void> _onReadRequested(
    NotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _notificationsViewModel.markAsRead(event.notificationId);
  }

  Future<void> _onMarkAllReadRequested(
    NotificationsMarkAllReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _notificationsViewModel.markAllAsRead();
  }

  Future<void> _onNotificationDismissed(
    NotificationDismissed event,
    Emitter<NotificationsState> emit,
  ) async {
    await _notificationsViewModel.deleteNotification(event.notificationId);
  }

  Future<void> _onNotificationsCleared(
    NotificationsClearedRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _notificationsViewModel.clearNotifications();
    emit(
      state.copyWith(
        actionMessage: AppStrings.notificationsCleared,
        actionSuccess: true,
      ),
    );
  }

  Future<void> _onRequestAccepted(
    NotificationRequestAccepted event,
    Emitter<NotificationsState> emit,
  ) async {
    final notification = event.notification;
    final fromUserId = notification.fromUserId;
    if (fromUserId == null || fromUserId.isEmpty) {
      emit(
        state.copyWith(
          actionMessage: AppStrings.requestActionFailed,
          actionSuccess: false,
        ),
      );
      return;
    }

    final chatPlayer = AvailablePlayerModel(
      id: fromUserId,
      name: notification.fromUserName ?? 'Player',
      avatarUrl: notification.fromUserAvatar ?? AppImages.avatarHost,
      gameId: notification.gameId ?? AppOptions.valorantId,
      rank: notification.rank ?? AppOptions.valorantRankOptions.first.name,
      language: notification.language ?? AppOptions.languageOptions.first,
      availableSince: DateTime.now(),
    );

    try {
      await _notificationsViewModel.updateNotificationStatus(
        notificationId: notification.id,
        status: NotificationItem.statusAccepted,
      );
      await _notificationsViewModel.markAsRead(notification.id);
      await _notificationsViewModel.sendChatRequestResponse(
        targetUserId: fromUserId,
        status: NotificationItem.statusAccepted,
        title: AppStrings.chatRequestAcceptedTitle,
        body: AppStrings.chatRequestAcceptedBody,
        gameId: notification.gameId,
        rank: notification.rank,
        language: notification.language,
      );
      await _chatViewModel.sendMessage(
        scope: ChatScope.direct,
        targetId: fromUserId,
        message: AppStrings.chatRequestAcceptedMessage,
      );

      emit(
        state.copyWith(
          pendingChatPlayer: chatPlayer,
          actionMessage: AppStrings.requestAcceptedToast,
          actionSuccess: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          actionMessage: AppStrings.requestActionFailed,
          actionSuccess: false,
        ),
      );
    }
  }

  Future<void> _onRequestDeclined(
    NotificationRequestDeclined event,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final notification = event.notification;
      final fromUserId = notification.fromUserId;
      await _notificationsViewModel.updateNotificationStatus(
        notificationId: notification.id,
        status: NotificationItem.statusDeclined,
      );
      await _notificationsViewModel.markAsRead(notification.id);
      if (fromUserId != null && fromUserId.isNotEmpty) {
        await _notificationsViewModel.sendChatRequestResponse(
          targetUserId: fromUserId,
          status: NotificationItem.statusDeclined,
          title: AppStrings.chatRequestDeclinedTitle,
          body: AppStrings.chatRequestDeclinedBody,
          gameId: notification.gameId,
          rank: notification.rank,
          language: notification.language,
        );
      }
      emit(
        state.copyWith(
          actionMessage: AppStrings.requestDeclinedToast,
          actionSuccess: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          actionMessage: AppStrings.requestActionFailed,
          actionSuccess: false,
        ),
      );
    }
  }

  void _onActionCleared(
    NotificationsActionCleared event,
    Emitter<NotificationsState> emit,
  ) {
    emit(
      state.copyWith(
        clearPendingChatPlayer: true,
        clearActionMessage: true,
        clearActionSuccess: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
