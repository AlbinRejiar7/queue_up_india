import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_pulse_model.dart';

class ActivityPulseService {
  ActivityPulseService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<ActivityPulseModel> fetchForGame(String gameId) async {
    if (gameId.trim().isEmpty) {
      return const ActivityPulseModel(
        availableSoloPlayers: 0,
        openParties: 0,
      );
    }

    try {
      final results = await Future.wait<dynamic>([
        _db
            .collection('availability')
            .where('isAvailable', isEqualTo: true)
            .where('gameId', isEqualTo: gameId)
            .count()
            .get(),
        _db
            .collection('parties')
            .where('gameId', isEqualTo: gameId)
            .where('status', isEqualTo: 'open')
            .count()
            .get(),
      ]);

      final availableSnapshot = results[0];
      final openPartiesSnapshot = results[1];

      return ActivityPulseModel(
        availableSoloPlayers: availableSnapshot.count ?? 0,
        openParties: openPartiesSnapshot.count ?? 0,
      );
    } catch (_) {
      return const ActivityPulseModel(
        availableSoloPlayers: 0,
        openParties: 0,
      );
    }
  }
}
