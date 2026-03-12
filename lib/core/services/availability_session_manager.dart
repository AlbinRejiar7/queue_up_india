import 'package:firebase_auth/firebase_auth.dart';

import '../../features/home/data/repositories/availability_repository.dart';
import '../constants/app_options.dart';
import '../di/injection_container.dart';

class AvailabilitySessionManager {
  static bool _clearedOnStartup = false;

  static Future<void> clearAvailabilityOnStartup() async {
    if (_clearedOnStartup) {
      return;
    }
    _clearedOnStartup = true;
    await _clearAvailability();
  }

  static Future<void> clearAvailabilityOnTerminate() async {
    await _clearAvailability();
  }

  static Future<void> _clearAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      await sl<AvailabilityRepository>().setAvailability(
        isAvailable: false,
        gameId: AppOptions.valorantId,
        rank: '',
        language: '',
      );
    } catch (_) {}
  }
}
