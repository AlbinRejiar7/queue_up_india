import '../../../core/constants/app_options.dart';

abstract final class RankMapper {
  static int skillLevelFor({
    required String gameId,
    required String rankId,
  }) {
    final normalizedRank = rankId.trim().toLowerCase();
    if (gameId == AppOptions.pubgId) {
      if (normalizedRank.startsWith('bronze')) {
        return 2;
      }
      if (normalizedRank.startsWith('silver')) {
        return 3;
      }
      if (normalizedRank.startsWith('gold')) {
        return 4;
      }
      if (normalizedRank.startsWith('platinum')) {
        return 5;
      }
      if (normalizedRank.startsWith('diamond')) {
        return 6;
      }
      if (normalizedRank.startsWith('crown')) {
        return 7;
      }
      if (normalizedRank.startsWith('ace')) {
        return 8;
      }
      if (normalizedRank.startsWith('conqueror')) {
        return 10;
      }
      return 4;
    }

    if (gameId == AppOptions.freeFireId) {
      if (normalizedRank.startsWith('bronze')) {
        return 2;
      }
      if (normalizedRank.startsWith('silver')) {
        return 3;
      }
      if (normalizedRank.startsWith('gold')) {
        return 4;
      }
      if (normalizedRank.startsWith('platinum')) {
        return 5;
      }
      if (normalizedRank.startsWith('diamond')) {
        return 6;
      }
      if (normalizedRank.startsWith('heroic')) {
        return 8;
      }
      if (normalizedRank.startsWith('grandmaster')) {
        return 10;
      }
      return 4;
    }

    if (normalizedRank.startsWith('iron')) {
      return 1;
    }
    if (normalizedRank.startsWith('bronze')) {
      return 2;
    }
    if (normalizedRank.startsWith('silver')) {
      return 3;
    }
    if (normalizedRank.startsWith('gold')) {
      return 5;
    }
    if (normalizedRank.startsWith('platinum')) {
      return 6;
    }
    if (normalizedRank.startsWith('diamond')) {
      return 7;
    }
    if (normalizedRank.startsWith('ascendant')) {
      return 8;
    }
    if (normalizedRank.startsWith('immortal')) {
      return 9;
    }
    if (normalizedRank.startsWith('radiant')) {
      return 10;
    }
    return 4;
  }

  static String skillGroupForLevel(int skillLevel) {
    if (skillLevel <= 3) {
      return 'beginner';
    }
    if (skillLevel <= 6) {
      return 'intermediate';
    }
    return 'pro';
  }
}
