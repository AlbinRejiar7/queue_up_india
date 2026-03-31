import 'package:equatable/equatable.dart';

import '../../../core/constants/app_timeouts.dart';

class AvailablePlayerModel extends Equatable {
  const AvailablePlayerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.gameId,
    required this.rank,
    required this.language,
    required this.availableSince,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String gameId;
  final String rank;
  final String language;
  final DateTime availableSince;
  final DateTime updatedAt;

  DateTime get expiresAt => updatedAt.add(AppTimeouts.availabilityTtl);

  bool isFresh([DateTime? now]) {
    return expiresAt.isAfter(now ?? DateTime.now());
  }

  AvailablePlayerModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? gameId,
    String? rank,
    String? language,
    DateTime? availableSince,
    DateTime? updatedAt,
  }) {
    return AvailablePlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gameId: gameId ?? this.gameId,
      rank: rank ?? this.rank,
      language: language ?? this.language,
      availableSince: availableSince ?? this.availableSince,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    avatarUrl,
    gameId,
    rank,
    language,
    availableSince,
    updatedAt,
  ];
}
