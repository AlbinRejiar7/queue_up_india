import '../../models/game_model.dart';

abstract class GameRepository {
  Future<List<GameModel>> fetchPopularGames();
}
