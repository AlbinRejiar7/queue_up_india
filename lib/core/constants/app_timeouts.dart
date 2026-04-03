abstract final class AppTimeouts {
  static const Duration availabilityTtl = Duration(minutes: 15);
  static const Duration availabilityHeartbeat = Duration(minutes: 5);
  static const Duration partyTtl = Duration(hours: 3);
}
