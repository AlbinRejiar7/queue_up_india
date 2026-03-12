import 'app_images.dart';

class GameOption {
  const GameOption({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String imageUrl;
}

class RankOption {
  const RankOption({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;
}

abstract final class AppOptions {
  static const String valorantId = 'valorant';
  static const String pubgId = 'pubg';
  static const String freeFireId = 'freefire';

  static const List<GameOption> gameOptions = <GameOption>[
    GameOption(id: valorantId, name: 'Valorant', imageUrl: AppImages.valorant),
    GameOption(id: pubgId, name: 'PUBG', imageUrl: AppImages.pubg),
    GameOption(id: freeFireId, name: 'Free Fire', imageUrl: AppImages.freeFire),
  ];

  static const List<RankOption> valorantRankOptions = <RankOption>[
    RankOption(name: 'Iron 1', imageUrl: 'assets/rank_png/Iron_1_Rank.png'),
    RankOption(name: 'Iron 2', imageUrl: 'assets/rank_png/Iron_2_Rank.png'),
    RankOption(name: 'Iron 3', imageUrl: 'assets/rank_png/Iron_3_Rank.png'),
    RankOption(name: 'Bronze 1', imageUrl: 'assets/rank_png/Bronze_1_Rank.png'),
    RankOption(name: 'Bronze 2', imageUrl: 'assets/rank_png/Bronze_2_Rank.png'),
    RankOption(name: 'Bronze 3', imageUrl: 'assets/rank_png/Bronze_3_Rank.png'),
    RankOption(name: 'Silver 1', imageUrl: 'assets/rank_png/Silver_1_Rank.png'),
    RankOption(name: 'Silver 2', imageUrl: 'assets/rank_png/Silver_2_Rank.png'),
    RankOption(name: 'Silver 3', imageUrl: 'assets/rank_png/Silver_3_Rank.png'),
    RankOption(name: 'Gold 1', imageUrl: 'assets/rank_png/Gold_1_Rank.png'),
    RankOption(name: 'Gold 2', imageUrl: 'assets/rank_png/Gold_2_Rank.png'),
    RankOption(name: 'Gold 3', imageUrl: 'assets/rank_png/Gold_3_Rank.png'),
    RankOption(
      name: 'Platinum 1',
      imageUrl: 'assets/rank_png/Platinum_1_Rank.png',
    ),
    RankOption(
      name: 'Platinum 2',
      imageUrl: 'assets/rank_png/Platinum_2_Rank.png',
    ),
    RankOption(
      name: 'Platinum 3',
      imageUrl: 'assets/rank_png/Platinum_3_Rank.png',
    ),
    RankOption(
      name: 'Diamond 1',
      imageUrl: 'assets/rank_png/Diamond_1_Rank.png',
    ),
    RankOption(
      name: 'Diamond 2',
      imageUrl: 'assets/rank_png/Diamond_2_Rank.png',
    ),
    RankOption(
      name: 'Diamond 3',
      imageUrl: 'assets/rank_png/Diamond_3_Rank.png',
    ),
    RankOption(
      name: 'Ascendant 1',
      imageUrl: 'assets/rank_png/Ascendant_1_Rank.png',
    ),
    RankOption(
      name: 'Ascendant 2',
      imageUrl: 'assets/rank_png/Ascendant_2_Rank.png',
    ),
    RankOption(
      name: 'Ascendant 3',
      imageUrl: 'assets/rank_png/Ascendant_3_Rank.png',
    ),
    RankOption(
      name: 'Immortal 1',
      imageUrl: 'assets/rank_png/Immortal_1_Rank.png',
    ),
    RankOption(
      name: 'Immortal 2',
      imageUrl: 'assets/rank_png/Immortal_2_Rank.png',
    ),
    RankOption(
      name: 'Immortal 3',
      imageUrl: 'assets/rank_png/Immortal_3_Rank.png',
    ),
    RankOption(name: 'Radiant', imageUrl: 'assets/rank_png/Radiant_Rank.png'),
  ];

  static const List<RankOption> pubgRankOptions = <RankOption>[
    RankOption(name: 'Bronze', imageUrl: 'assets/pubg/bronze.png'),
    RankOption(name: 'Silver', imageUrl: 'assets/pubg/silver.png'),
    RankOption(name: 'Gold', imageUrl: 'assets/pubg/gold.png'),
    RankOption(name: 'Platinum', imageUrl: 'assets/pubg/platinum.png'),
    RankOption(name: 'Diamond', imageUrl: 'assets/pubg/diamond.png'),
    RankOption(name: 'Crown', imageUrl: 'assets/pubg/crown.png'),
    RankOption(name: 'Ace', imageUrl: 'assets/pubg/ace.png'),
    RankOption(name: 'Conqueror', imageUrl: 'assets/pubg/conquorer.png'),
  ];

  static const List<RankOption> freeFireRankOptions = <RankOption>[
    RankOption(
      name: 'Bronze',
      imageUrl: 'assets/freefire/bronze.jpg',
    ),
    RankOption(
      name: 'Silver',
      imageUrl: 'assets/freefire/silver.png',
    ),
    RankOption(
      name: 'Gold',
      imageUrl: 'assets/freefire/gold.png',
    ),
    RankOption(
      name: 'Platinum',
      imageUrl: 'assets/freefire/platinum.png',
    ),
    RankOption(
      name: 'Diamond',
      imageUrl: 'assets/freefire/diamond.png',
    ),
    RankOption(
      name: 'Heroic',
      imageUrl: 'assets/freefire/heroic.png',
    ),
    RankOption(
      name: 'Grandmaster',
      imageUrl: 'assets/freefire/grandmaster.png',
    ),
  ];

  static const List<String> languageOptions = <String>[
    'English',
    'Hindi',
    'Bengali',
    'Marathi',
    'Telugu',
    'Tamil',
    'Gujarati',
    'Urdu',
    'Kannada',
    'Odia',
    'Malayalam',
    'Punjabi',
    'Assamese',
    'Maithili',
    'Sanskrit',
    'Konkani',
    'Kashmiri',
    'Nepali',
    'Sindhi',
    'Dogri',
    'Manipuri',
    'Bodo',
    'Santali',
  ];

  static const List<String> profileAvatarOptions = <String>[
    AppImages.avatarHost,
    AppImages.avatarThree,
    AppImages.avatarOne,
    AppImages.avatarFour,
    AppImages.avatarTwo,
    AppImages.avatarFive,
  ];

  static List<RankOption> rankOptionsByGame(String gameId) {
    if (gameId == pubgId) {
      return pubgRankOptions;
    }
    if (gameId == freeFireId) {
      return freeFireRankOptions;
    }
    return valorantRankOptions;
  }

  static RankOption defaultRankForGame(String gameId) {
    return rankOptionsByGame(gameId).first;
  }

  static bool isRankValidForGame({required String gameId, String? rankName}) {
    if (rankName == null || rankName.trim().isEmpty) {
      return false;
    }

    return rankOptionsByGame(
      gameId,
    ).any((RankOption rank) => rank.name == rankName);
  }

  static String gameNameById(String gameId) {
    return gameOptions
        .firstWhere(
          (GameOption game) => game.id == gameId,
          orElse: () => gameOptions.first,
        )
        .name;
  }

  static RankOption? rankOptionByName({
    required String rankName,
    String? gameId,
  }) {
    final normalized = rankName.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final rankedLists = <List<RankOption>>[
      if (gameId != null) rankOptionsByGame(gameId),
      if (gameId == null) ...<List<RankOption>>[
        valorantRankOptions,
        pubgRankOptions,
        freeFireRankOptions,
      ],
    ];

    for (final options in rankedLists) {
      for (final option in options) {
        if (option.name.toLowerCase() == normalized) {
          return option;
        }
      }
    }
    return null;
  }

  static String? rankImageByName({required String rankName, String? gameId}) {
    return rankOptionByName(rankName: rankName, gameId: gameId)?.imageUrl;
  }
}
