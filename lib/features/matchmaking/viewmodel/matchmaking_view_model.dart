import '../data/repositories/matchmaking_repository.dart';
import '../models/solo_matchmaking_metadata_model.dart';
import '../models/solo_matchmaking_session_model.dart';
import '../models/solo_squad_model.dart';

class MatchmakingViewModel {
  MatchmakingViewModel({required MatchmakingRepository repository})
    : _repository = repository;

  final MatchmakingRepository _repository;

  Future<SoloMatchmakingSessionModel?> getCurrentSession() {
    return _repository.getCurrentSession();
  }

  Stream<SoloMatchmakingSessionModel?> watchCurrentSession() {
    return _repository.watchCurrentSession();
  }

  Stream<SoloMatchmakingMetadataModel?> watchBucketMetadata(String bucketId) {
    return _repository.watchBucketMetadata(bucketId);
  }

  Stream<SoloSquadModel?> watchSquad(String squadId) {
    return _repository.watchSquad(squadId);
  }

  Future<void> startSoloQueue({
    required String gameId,
    required String rankId,
    required String languageId,
  }) {
    return _repository.startSoloQueue(
      gameId: gameId,
      rankId: rankId,
      languageId: languageId,
    );
  }

  Future<void> cancelSoloQueue() {
    return _repository.cancelSoloQueue();
  }

  Future<void> acceptSquad({required String squadId}) {
    return _repository.acceptSquad(squadId: squadId);
  }

  Future<void> rejectSquad({required String squadId}) {
    return _repository.rejectSquad(squadId: squadId);
  }
}
