import '../data/repositories/availability_repository.dart';
import '../models/available_player_model.dart';
import '../../../core/utils/paged_result.dart';

class AvailablePlayersViewModel {
  AvailablePlayersViewModel({required AvailabilityRepository repository})
    : _repository = repository;

  final AvailabilityRepository _repository;

  Stream<List<AvailablePlayerModel>> watchAvailablePlayers() {
    return _repository.watchAvailablePlayers();
  }

  Stream<PagedResult<AvailablePlayerModel>> watchAvailablePlayersPage({
    String? gameId,
    String? rank,
    String? language,
    int limit = 10,
  }) {
    return _repository.watchAvailablePlayersPage(
      gameId: gameId,
      rank: rank,
      language: language,
      limit: limit,
    );
  }

  Future<PagedResult<AvailablePlayerModel>> loadAvailablePlayersPage({
    String? gameId,
    String? rank,
    String? language,
    Object? cursor,
    int limit = 10,
  }) {
    return _repository.fetchAvailablePlayersPage(
      gameId: gameId,
      rank: rank,
      language: language,
      cursor: cursor,
      limit: limit,
    );
  }

  Future<AvailablePlayerModel?> fetchAvailablePlayer(String userId) {
    return _repository.fetchAvailabilityById(userId);
  }
}
