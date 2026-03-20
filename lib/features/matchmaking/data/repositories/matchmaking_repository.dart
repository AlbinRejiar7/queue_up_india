import '../../models/solo_matchmaking_metadata_model.dart';
import '../../models/solo_matchmaking_session_model.dart';
import '../../models/solo_squad_model.dart';

abstract class MatchmakingRepository {
  Future<SoloMatchmakingSessionModel?> getCurrentSession();

  Stream<SoloMatchmakingSessionModel?> watchCurrentSession();

  Stream<SoloMatchmakingMetadataModel?> watchBucketMetadata(String bucketId);

  Stream<SoloSquadModel?> watchSquad(String squadId);

  Future<void> startSoloQueue({
    required String gameId,
    required String rankId,
    required String languageId,
  });

  Future<void> cancelSoloQueue();

  Future<void> acceptSquad({
    required String squadId,
  });

  Future<void> rejectSquad({
    required String squadId,
  });
}
