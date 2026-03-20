import 'package:equatable/equatable.dart';

import 'matchmaking_status.dart';

class SoloSquadParticipantModel extends Equatable {
  const SoloSquadParticipantModel({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.gameId,
    required this.rankId,
    required this.languageId,
    required this.skillLevel,
  });

  final String uid;
  final String displayName;
  final String avatarUrl;
  final String gameId;
  final String rankId;
  final String languageId;
  final int skillLevel;

  factory SoloSquadParticipantModel.fromMap(Map<String, dynamic> data) {
    return SoloSquadParticipantModel(
      uid: (data['uid'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? 'QueuePlayer',
      avatarUrl: (data['avatarUrl'] as String?) ?? '',
      gameId: (data['gameId'] as String?) ?? '',
      rankId: (data['rankId'] as String?) ?? '',
      languageId: (data['languageId'] as String?) ?? '',
      skillLevel: (data['skillLevel'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    uid,
    displayName,
    avatarUrl,
    gameId,
    rankId,
    languageId,
    skillLevel,
  ];
}

class SoloSquadModel extends Equatable {
  const SoloSquadModel({
    required this.id,
    required this.status,
    required this.bucketId,
    required this.gameId,
    required this.languageId,
    required this.requiredPlayers,
    required this.retryCount,
    required this.acceptedPlayerIds,
    required this.participants,
    this.createdAt,
    this.acceptDeadlineAt,
  });

  final String id;
  final MatchmakingStatus status;
  final String bucketId;
  final String gameId;
  final String languageId;
  final int requiredPlayers;
  final int retryCount;
  final List<String> acceptedPlayerIds;
  final List<SoloSquadParticipantModel> participants;
  final DateTime? createdAt;
  final DateTime? acceptDeadlineAt;

  int get acceptedCount => acceptedPlayerIds.length;

  bool isAcceptedBy(String userId) => acceptedPlayerIds.contains(userId);

  factory SoloSquadModel.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final rawParticipants = (data['participants'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((item) {
          return SoloSquadParticipantModel.fromMap(
            Map<String, dynamic>.from(item),
          );
        })
        .toList();

    return SoloSquadModel(
      id: id,
      status: matchmakingStatusFromValue(data['status'] as String?),
      bucketId: (data['bucketId'] as String?) ?? '',
      gameId: (data['gameId'] as String?) ?? '',
      languageId: (data['languageId'] as String?) ?? '',
      requiredPlayers: (data['requiredPlayers'] as num?)?.toInt() ?? 4,
      retryCount: (data['retryCount'] as num?)?.toInt() ?? 0,
      acceptedPlayerIds: (data['acceptedPlayerIds'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
      participants: rawParticipants,
      createdAt: _parseDate(data['createdAt']),
      acceptDeadlineAt: _parseDate(data['acceptDeadlineAt']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    status,
    bucketId,
    gameId,
    languageId,
    requiredPlayers,
    retryCount,
    acceptedPlayerIds,
    participants,
    createdAt,
    acceptDeadlineAt,
  ];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  final dynamic timestampDate = value.toDate?.call();
  if (timestampDate is DateTime) {
    return timestampDate;
  }
  return null;
}
