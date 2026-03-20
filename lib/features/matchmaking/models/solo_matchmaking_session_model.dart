import 'package:equatable/equatable.dart';

import 'matchmaking_status.dart';

class SoloMatchmakingSessionModel extends Equatable {
  const SoloMatchmakingSessionModel({
    required this.status,
    required this.gameId,
    required this.rankId,
    required this.languageId,
    this.bucketId,
    this.ticketId,
    this.squadId,
    this.skillLevel,
    this.queueSize = 0,
    this.estimatedSeconds = 0,
    this.joinedAt,
    this.updatedAt,
  });

  final MatchmakingStatus status;
  final String gameId;
  final String rankId;
  final String languageId;
  final String? bucketId;
  final String? ticketId;
  final String? squadId;
  final int? skillLevel;
  final int queueSize;
  final int estimatedSeconds;
  final DateTime? joinedAt;
  final DateTime? updatedAt;

  bool get isActive => status.isQueueActive;

  factory SoloMatchmakingSessionModel.fromMap(Map<String, dynamic> data) {
    return SoloMatchmakingSessionModel(
      status: matchmakingStatusFromValue(data['status'] as String?),
      gameId: (data['gameId'] as String?) ?? '',
      rankId: (data['rankId'] as String?) ?? '',
      languageId: (data['languageId'] as String?) ?? '',
      bucketId: data['bucketId'] as String?,
      ticketId: data['ticketId'] as String?,
      squadId: data['squadId'] as String?,
      skillLevel: (data['skillLevel'] as num?)?.toInt(),
      queueSize: (data['queueSize'] as num?)?.toInt() ?? 0,
      estimatedSeconds: (data['estimatedSeconds'] as num?)?.toInt() ?? 0,
      joinedAt: _parseDate(data['joinedAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    gameId,
    rankId,
    languageId,
    bucketId,
    ticketId,
    squadId,
    skillLevel,
    queueSize,
    estimatedSeconds,
    joinedAt,
    updatedAt,
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
