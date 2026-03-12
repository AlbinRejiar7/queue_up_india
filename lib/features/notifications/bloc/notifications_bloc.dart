import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../viewmodel/notifications_view_model.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required NotificationsViewModel notificationsViewModel})
    : _notificationsViewModel = notificationsViewModel,
      super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted);
    on<NotificationsUpdated>(_onUpdated);
    on<NotificationReadRequested>(_onReadRequested);
  }

  final NotificationsViewModel _notificationsViewModel;
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

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
