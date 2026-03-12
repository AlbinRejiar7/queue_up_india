import '../data/repositories/availability_repository.dart';
import '../models/available_player_model.dart';

class AvailabilityViewModel {
  AvailabilityViewModel({required AvailabilityRepository repository})
    : _repository = repository;

  final AvailabilityRepository _repository;

  Future<void> updateAvailability({
    required bool isAvailable,
    required String gameId,
    required String rank,
    required String language,
  }) {
    return _repository.setAvailability(
      isAvailable: isAvailable,
      gameId: gameId,
      rank: rank,
      language: language,
    );
  }

  Future<AvailablePlayerModel?> fetchCurrentAvailability() {
    return _repository.fetchCurrentAvailability();
  }
}
