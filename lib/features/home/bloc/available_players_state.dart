import 'package:equatable/equatable.dart';

import '../models/available_player_model.dart';

class AvailablePlayersState extends Equatable {
  const AvailablePlayersState({
    required this.allPlayers,
    required this.filteredPlayers,
    required this.selectedGameId,
    required this.selectedRank,
    required this.selectedLanguage,
  });

  const AvailablePlayersState.initial()
    : allPlayers = const <AvailablePlayerModel>[],
      filteredPlayers = const <AvailablePlayerModel>[],
      selectedGameId = null,
      selectedRank = null,
      selectedLanguage = null;

  final List<AvailablePlayerModel> allPlayers;
  final List<AvailablePlayerModel> filteredPlayers;
  final String? selectedGameId;
  final String? selectedRank;
  final String? selectedLanguage;

  AvailablePlayersState copyWith({
    List<AvailablePlayerModel>? allPlayers,
    List<AvailablePlayerModel>? filteredPlayers,
    String? selectedGameId,
    bool clearGameId = false,
    String? selectedRank,
    bool clearRank = false,
    String? selectedLanguage,
    bool clearLanguage = false,
  }) {
    return AvailablePlayersState(
      allPlayers: allPlayers ?? this.allPlayers,
      filteredPlayers: filteredPlayers ?? this.filteredPlayers,
      selectedGameId: clearGameId ? null : selectedGameId ?? this.selectedGameId,
      selectedRank: clearRank ? null : selectedRank ?? this.selectedRank,
      selectedLanguage: clearLanguage
          ? null
          : selectedLanguage ?? this.selectedLanguage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    allPlayers,
    filteredPlayers,
    selectedGameId,
    selectedRank,
    selectedLanguage,
  ];
}
