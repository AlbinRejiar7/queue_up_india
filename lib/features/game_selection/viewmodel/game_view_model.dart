import '../data/repositories/game_repository.dart';
import '../models/game_model.dart';

class GameViewModel {
  GameViewModel({required GameRepository gameRepository})
    : _gameRepository = gameRepository;

  final GameRepository _gameRepository;

  Future<List<GameModel>> loadPopularGames() {
    return _gameRepository.fetchPopularGames();
  }
}
