import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_timeouts.dart';
import '../models/activity_pulse_model.dart';

class ActivityPulseService {
  ActivityPulseService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<ActivityPulseModel> fetchForGame(String gameId) async {
    if (gameId.trim().isEmpty) {
      return const ActivityPulseModel(availableSoloPlayers: 0, openParties: 0);
    }

    final cutoff = DateTime.now().subtract(AppTimeouts.availabilityTtl);
    try {
      final results = await Future.wait<dynamic>([
        _db
            .collection('availability')
            .where('isAvailable', isEqualTo: true)
            .where('gameId', isEqualTo: gameId)
            .where('updatedAt', isGreaterThan: Timestamp.fromDate(cutoff))
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
      try {
        final fallbackResults = await Future.wait<dynamic>([
          _db
              .collection('availability')
              .where('isAvailable', isEqualTo: true)
              .where('gameId', isEqualTo: gameId)
              .get(),
          _db
              .collection('parties')
              .where('gameId', isEqualTo: gameId)
              .where('status', isEqualTo: 'open')
              .count()
              .get(),
        ]);

        final availableDocs =
            fallbackResults[0] as QuerySnapshot<Map<String, dynamic>>;
        final openPartiesSnapshot = fallbackResults[1];
        final availableCount = availableDocs.docs.where((doc) {
          final data = doc.data();
          final updatedAt = data['updatedAt'];
          if (updatedAt is Timestamp) {
            return updatedAt.toDate().isAfter(cutoff);
          }
          if (updatedAt is DateTime) {
            return updatedAt.isAfter(cutoff);
          }
          final availableSince = data['availableSince'];
          if (availableSince is Timestamp) {
            return availableSince.toDate().isAfter(cutoff);
          }
          if (availableSince is DateTime) {
            return availableSince.isAfter(cutoff);
          }
          return false;
        }).length;

        return ActivityPulseModel(
          availableSoloPlayers: availableCount,
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
}
