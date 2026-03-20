enum MatchmakingStatus {
  idle,
  searching,
  waiting,
  acceptedWaiting,
  confirmed,
  cancelled,
  expired,
}

MatchmakingStatus matchmakingStatusFromValue(String? value) {
  switch (value) {
    case 'searching':
      return MatchmakingStatus.searching;
    case 'waiting':
      return MatchmakingStatus.waiting;
    case 'accepted_waiting':
      return MatchmakingStatus.acceptedWaiting;
    case 'confirmed':
      return MatchmakingStatus.confirmed;
    case 'cancelled':
      return MatchmakingStatus.cancelled;
    case 'expired':
      return MatchmakingStatus.expired;
    default:
      return MatchmakingStatus.idle;
  }
}

extension MatchmakingStatusX on MatchmakingStatus {
  String get value {
    switch (this) {
      case MatchmakingStatus.searching:
        return 'searching';
      case MatchmakingStatus.waiting:
        return 'waiting';
      case MatchmakingStatus.acceptedWaiting:
        return 'accepted_waiting';
      case MatchmakingStatus.confirmed:
        return 'confirmed';
      case MatchmakingStatus.cancelled:
        return 'cancelled';
      case MatchmakingStatus.expired:
        return 'expired';
      case MatchmakingStatus.idle:
        return 'idle';
    }
  }

  bool get isQueueActive {
    return this == MatchmakingStatus.searching ||
        this == MatchmakingStatus.waiting ||
        this == MatchmakingStatus.acceptedWaiting ||
        this == MatchmakingStatus.confirmed;
  }
}
