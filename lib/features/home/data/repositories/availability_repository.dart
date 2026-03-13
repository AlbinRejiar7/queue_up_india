import '../../models/available_player_model.dart';
import '../../../../core/utils/paged_result.dart';

abstract class AvailabilityRepository {
  Future<void> setAvailability({
    required bool isAvailable,
    required String gameId,
    required String rank,
    required String language,
    bool startedNow = false,
  });

  Stream<List<AvailablePlayerModel>> watchAvailablePlayers();

  Stream<PagedResult<AvailablePlayerModel>> watchAvailablePlayersPage({
    String? gameId,
    String? rank,
    String? language,
    int limit = 10,
  });

  Future<AvailablePlayerModel?> fetchCurrentAvailability();

  Future<PagedResult<AvailablePlayerModel>> fetchAvailablePlayersPage({
    String? gameId,
    String? rank,
    String? language,
    Object? cursor,
    int limit = 10,
  });
}
