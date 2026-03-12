import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_options.dart';
import '../../models/game_model.dart';
import 'game_repository.dart';

class FirestoreGameRepository implements GameRepository {
  FirestoreGameRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<GameModel>> fetchPopularGames() async {
    final snapshot = await _db
        .collection('games')
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) {
      return _fallbackGames();
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final id = doc.id;
      final name = (data['name'] as String?) ?? AppOptions.gameNameById(id);
      final label =
          (data['activePartiesLabel'] as String?) ?? 'Active now';
      return GameModel(
        id: id,
        name: name,
        activePartiesLabel: label,
        coverUrl: _coverForGame(id),
      );
    }).toList();
  }

  List<GameModel> _fallbackGames() {
    return const <GameModel>[
      GameModel(
        id: AppOptions.valorantId,
        name: 'Valorant',
        activePartiesLabel: 'Active now',
        coverUrl: AppImages.valorant,
      ),
      GameModel(
        id: AppOptions.pubgId,
        name: 'PUBG',
        activePartiesLabel: 'Active now',
        coverUrl: AppImages.pubg,
      ),
      GameModel(
        id: AppOptions.freeFireId,
        name: 'Free Fire',
        activePartiesLabel: 'Active now',
        coverUrl: AppImages.freeFire,
      ),
    ];
  }

  String _coverForGame(String gameId) {
    if (gameId == AppOptions.pubgId) {
      return AppImages.pubg;
    }
    if (gameId == AppOptions.freeFireId) {
      return AppImages.freeFire;
    }
    return AppImages.valorant;
  }
}
