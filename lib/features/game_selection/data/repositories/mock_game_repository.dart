import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_options.dart';
import '../../models/game_model.dart';
import 'game_repository.dart';

class MockGameRepository implements GameRepository {
  @override
  Future<List<GameModel>> fetchPopularGames() async {
    // TODO: Implement Firestore query here
    await Future<void>.delayed(const Duration(milliseconds: 550));

    return const <GameModel>[
      GameModel(
        id: AppOptions.valorantId,
        name: 'Valorant',
        activePartiesLabel: '2.4k active parties',
        coverUrl: AppImages.valorant,
      ),
      GameModel(
        id: AppOptions.pubgId,
        name: 'PUBG',
        activePartiesLabel: '1.8k active parties',
        coverUrl: AppImages.pubg,
      ),
      GameModel(
        id: AppOptions.freeFireId,
        name: 'Free Fire',
        activePartiesLabel: '1.3k active parties',
        coverUrl: AppImages.freeFire,
      ),
    ];
  }
}
