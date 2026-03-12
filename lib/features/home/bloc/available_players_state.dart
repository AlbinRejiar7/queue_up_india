import 'package:equatable/equatable.dart';

import '../models/available_player_model.dart';

class AvailablePlayersState extends Equatable {
  const AvailablePlayersState({
    required this.players,
    required this.selectedGameId,
    required this.selectedRank,
    required this.selectedLanguage,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.cursor,
  });

  const AvailablePlayersState.initial()
    : players = const <AvailablePlayerModel>[],
      selectedGameId = null,
      selectedRank = null,
      selectedLanguage = null,
      isLoading = false,
      isLoadingMore = false,
      hasMore = true,
      cursor = null;

  final List<AvailablePlayerModel> players;
  final String? selectedGameId;
  final String? selectedRank;
  final String? selectedLanguage;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? cursor;

  AvailablePlayersState copyWith({
    List<AvailablePlayerModel>? players,
    String? selectedGameId,
    bool clearGameId = false,
    String? selectedRank,
    bool clearRank = false,
    String? selectedLanguage,
    bool clearLanguage = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? cursor,
    bool clearCursor = false,
  }) {
    return AvailablePlayersState(
      players: players ?? this.players,
      selectedGameId: clearGameId ? null : selectedGameId ?? this.selectedGameId,
      selectedRank: clearRank ? null : selectedRank ?? this.selectedRank,
      selectedLanguage: clearLanguage
          ? null
          : selectedLanguage ?? this.selectedLanguage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      cursor: clearCursor ? null : cursor ?? this.cursor,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    players,
    selectedGameId,
    selectedRank,
    selectedLanguage,
    isLoading,
    isLoadingMore,
    hasMore,
    cursor,
  ];
}
