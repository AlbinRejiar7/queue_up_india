import 'package:equatable/equatable.dart';

import 'party_player_model.dart';

class PartyModel extends Equatable {
  const PartyModel({
    required this.id,
    required this.name,
    required this.gameId,
    required this.rank,
    required this.language,
    required this.maxPlayers,
    required this.players,
    required this.partyCode,
    required this.createdAt,
    required this.coverImageUrl,
    required this.hostId,
    this.tags = const <String>[],
    this.logoImageUrl,
  });

  final String id;
  final String name;
  final String gameId;
  final String rank;
  final String language;
  final int maxPlayers;
  final List<PartyPlayerModel> players;
  final String partyCode;
  final DateTime createdAt;
  final String coverImageUrl;
  final String hostId;
  final List<String> tags;
  final String? logoImageUrl;

  int get playerCount => players.length;
  bool get isFull => playerCount >= maxPlayers;

  PartyModel copyWith({
    String? id,
    String? name,
    String? gameId,
    String? rank,
    String? language,
    int? maxPlayers,
    List<PartyPlayerModel>? players,
    String? partyCode,
    DateTime? createdAt,
    String? coverImageUrl,
    String? hostId,
    List<String>? tags,
    String? logoImageUrl,
  }) {
    return PartyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gameId: gameId ?? this.gameId,
      rank: rank ?? this.rank,
      language: language ?? this.language,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      players: players ?? this.players,
      partyCode: partyCode ?? this.partyCode,
      createdAt: createdAt ?? this.createdAt,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      hostId: hostId ?? this.hostId,
      tags: tags ?? this.tags,
      logoImageUrl: logoImageUrl ?? this.logoImageUrl,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    gameId,
    rank,
    language,
    maxPlayers,
    players,
    partyCode,
    createdAt,
    coverImageUrl,
    hostId,
    tags,
    logoImageUrl,
  ];
}
