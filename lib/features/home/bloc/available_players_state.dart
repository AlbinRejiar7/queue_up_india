import 'package:equatable/equatable.dart';

import '../models/available_player_model.dart';

enum RequestMessageType { success, error, info }

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
    required this.isRequesting,
    required this.requestMessage,
    required this.requestSuccess,
    required this.requestMessageType,
    required this.requestActionPeerId,
  });

  const AvailablePlayersState.initial()
    : players = const <AvailablePlayerModel>[],
      selectedGameId = null,
      selectedRank = null,
      selectedLanguage = null,
      isLoading = false,
      isLoadingMore = false,
      hasMore = true,
      cursor = null,
      isRequesting = false,
      requestMessage = null,
      requestSuccess = null,
      requestMessageType = null,
      requestActionPeerId = null;

  final List<AvailablePlayerModel> players;
  final String? selectedGameId;
  final String? selectedRank;
  final String? selectedLanguage;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? cursor;
  final bool isRequesting;
  final String? requestMessage;
  final bool? requestSuccess;
  final RequestMessageType? requestMessageType;
  final String? requestActionPeerId;

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
    bool? isRequesting,
    String? requestMessage,
    bool clearRequestMessage = false,
    bool? requestSuccess,
    bool clearRequestSuccess = false,
    RequestMessageType? requestMessageType,
    bool clearRequestMessageType = false,
    String? requestActionPeerId,
    bool clearRequestActionPeerId = false,
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
      isRequesting: isRequesting ?? this.isRequesting,
      requestMessage:
          clearRequestMessage ? null : requestMessage ?? this.requestMessage,
      requestSuccess:
          clearRequestSuccess ? null : requestSuccess ?? this.requestSuccess,
      requestMessageType: clearRequestMessageType
          ? null
          : requestMessageType ?? this.requestMessageType,
      requestActionPeerId: clearRequestActionPeerId
          ? null
          : requestActionPeerId ?? this.requestActionPeerId,
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
    isRequesting,
    requestMessage,
    requestSuccess,
    requestMessageType,
    requestActionPeerId,
  ];
}
