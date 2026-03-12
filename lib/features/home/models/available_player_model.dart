import 'package:equatable/equatable.dart';

class AvailablePlayerModel extends Equatable {
  const AvailablePlayerModel({
    required this.id,
    required this.name,
    required this.gameId,
    required this.rank,
    required this.language,
  });

  final String id;
  final String name;
  final String gameId;
  final String rank;
  final String language;

  AvailablePlayerModel copyWith({
    String? id,
    String? name,
    String? gameId,
    String? rank,
    String? language,
  }) {
    return AvailablePlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gameId: gameId ?? this.gameId,
      rank: rank ?? this.rank,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, gameId, rank, language];
}
