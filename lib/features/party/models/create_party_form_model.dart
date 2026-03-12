import 'package:equatable/equatable.dart';

class CreatePartyFormModel extends Equatable {
  const CreatePartyFormModel({
    this.gameId = '',
    this.partyName = '',
    this.useAutoName = true,
    this.rank,
    this.language,
    this.maxPlayers = 4,
    this.partyCode = '',
  });

  final String gameId;
  final String partyName;
  final bool useAutoName;
  final String? rank;
  final String? language;
  final int maxPlayers;
  final String partyCode;

  bool get isValid {
    return partyName.trim().isNotEmpty &&
        rank != null &&
        language != null &&
        partyCode.trim().isNotEmpty;
  }

  CreatePartyFormModel copyWith({
    String? gameId,
    String? partyName,
    bool? useAutoName,
    String? rank,
    bool clearRank = false,
    String? language,
    bool clearLanguage = false,
    int? maxPlayers,
    String? partyCode,
  }) {
    return CreatePartyFormModel(
      gameId: gameId ?? this.gameId,
      partyName: partyName ?? this.partyName,
      useAutoName: useAutoName ?? this.useAutoName,
      rank: clearRank ? null : rank ?? this.rank,
      language: clearLanguage ? null : language ?? this.language,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      partyCode: partyCode ?? this.partyCode,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    gameId,
    partyName,
    useAutoName,
    rank,
    language,
    maxPlayers,
    partyCode,
  ];
}
