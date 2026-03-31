import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_up_india/features/party/models/party_model.dart';

import '../../../core/constants/app_options.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/paged_result.dart';
import '../../auth/models/user_model.dart';
import '../models/create_party_form_model.dart';
import '../viewmodel/party_view_model.dart';
import '../models/party_player_model.dart';
import 'party_event.dart';
import 'party_state.dart';

class PartyBloc extends Bloc<PartyEvent, PartyState> {
  PartyBloc({required PartyViewModel partyViewModel})
    : _partyViewModel = partyViewModel,
      super(const PartyInitial()) {
    on<PartySessionChecked>(_onSessionChecked);
    on<PartyListRequested>(_onPartyListRequested);
    on<PartyListRefreshRequested>(_onPartyListRefreshRequested);
    on<PartyListLoadMoreRequested>(_onPartyListLoadMoreRequested);
    on<PartyListLivePageUpdated>(_onPartyListLivePageUpdated);
    on<PartyRoomsRequested>(_onPartyRoomsRequested);
    on<PartyDetailsRequested>(_onPartyDetailsRequested);
    on<PartyMembersLiveUpdated>(_onPartyMembersLiveUpdated);
    on<PartyJoinRequested>(_onPartyJoinRequested);
    on<PartyCreateStarted>(_onPartyCreateStarted);
    on<PartyFormNameChanged>(_onPartyFormNameChanged);
    on<PartyFormGameChanged>(_onPartyFormGameChanged);
    on<PartyFormRankChanged>(_onPartyFormRankChanged);
    on<PartyFormLanguageChanged>(_onPartyFormLanguageChanged);
    on<PartyFormMaxPlayersIncremented>(_onPartyFormMaxPlayersIncremented);
    on<PartyFormMaxPlayersDecremented>(_onPartyFormMaxPlayersDecremented);
    on<PartyFormCodeChanged>(_onPartyFormCodeChanged);
    on<PartyFilterRankChanged>(_onPartyFilterRankChanged);
    on<PartyFilterLanguageChanged>(_onPartyFilterLanguageChanged);
    on<PartyCreateSubmitted>(_onPartyCreateSubmitted);
    on<PartyLeaveRequested>(_onPartyLeaveRequested);
    on<PartyKickRequested>(_onPartyKickRequested);
    on<PartyNavigationConsumed>(_onPartyNavigationConsumed);
  }

  static const String _noPartyNavigationToken = 'none';
  static const int _partyPageSize = 10;

  final PartyViewModel _partyViewModel;
  StreamSubscription<PagedResult<PartyModel>>? _liveSubscription;
  StreamSubscription<List<PartyPlayerModel>>? _partyMembersSubscription;
  List<PartyModel> _liveParties = const <PartyModel>[];
  List<PartyModel> _olderParties = const <PartyModel>[];
  Object? _liveCursor;
  Object? _olderCursor;
  bool _liveHasMore = true;
  bool _olderHasMore = true;

  Future<void> _onSessionChecked(
    PartySessionChecked event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data));

    try {
      final currentPartyId = await _partyViewModel.getCurrentPartyId();
      emit(
        PartySuccess(
          data: state.data.copyWith(
            currentPartyId: currentPartyId,
            navigationPartyId: currentPartyId ?? _noPartyNavigationToken,
            didLeaveParty: false,
            isCreateCompleted: false,
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('[PartyBloc] Party load failed in session check: $e');
      debugPrintStack(stackTrace: s);
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  Future<void> _onPartyListRequested(
    PartyListRequested event,
    Emitter<PartyState> emit,
  ) async {
    final nextData = state.data.copyWith(
      activeGameId: event.gameId,
      parties: const <PartyModel>[],
      clearPartiesCursor: true,
      hasMoreParties: true,
      isLoadingMoreParties: false,
      clearSelectedRankFilter: true,
      clearSelectedLanguageFilter: true,
    );
    emit(PartyLoading(data: nextData));
    await _reloadPartiesWithFilters(nextData, emit);
  }

  Future<void> _onPartyListLoadMoreRequested(
    PartyListLoadMoreRequested event,
    Emitter<PartyState> emit,
  ) async {
    if (state.data.isLoadingMoreParties ||
        !state.data.hasMoreParties ||
        state.data.parties.isEmpty) {
      return;
    }

    final cursor = _olderParties.isEmpty ? _liveCursor : _olderCursor;
    if (cursor == null) {
      emit(
        PartySuccess(
          data: state.data.copyWith(
            hasMoreParties: false,
            isLoadingMoreParties: false,
          ),
        ),
      );
      return;
    }

    emit(PartySuccess(data: state.data.copyWith(isLoadingMoreParties: true)));

    try {
      final page = await _partyViewModel.loadPartiesPage(
        gameId: state.data.activeGameId,
        rankFilter: state.data.selectedRankFilter,
        languageFilter: state.data.selectedLanguageFilter,
        cursor: cursor,
        limit: _partyPageSize,
      );
      emit(
        PartySuccess(
          data: state.data.copyWith(
            parties: _mergeParties(_liveParties, <PartyModel>[
              ..._olderParties,
              ...page.items,
            ]),
            partiesCursor: page.nextCursor,
            hasMoreParties: page.hasMore,
            isLoadingMoreParties: false,
          ),
        ),
      );
      _olderParties = <PartyModel>[..._olderParties, ...page.items];
      _olderCursor = page.nextCursor;
      _olderHasMore = page.hasMore;
    } catch (e, s) {
      debugPrint('[PartyBloc] Party load failed in list load more: $e');
      debugPrintStack(stackTrace: s);
      emit(
        PartyError(
          message: AppStrings.partyLoadFailed,
          data: state.data.copyWith(isLoadingMoreParties: false),
        ),
      );
    }
  }

  Future<void> _onPartyListRefreshRequested(
    PartyListRefreshRequested event,
    Emitter<PartyState> emit,
  ) async {
    final activeGameId = state.data.activeGameId;
    if (activeGameId.isEmpty) {
      return;
    }
    final nextData = state.data.copyWith(
      parties: const <PartyModel>[],
      clearPartiesCursor: true,
      hasMoreParties: true,
      isLoadingMoreParties: false,
    );
    emit(PartyLoading(data: nextData));
    await _reloadPartiesWithFilters(nextData, emit);
  }

  void _onPartyListLivePageUpdated(
    PartyListLivePageUpdated event,
    Emitter<PartyState> emit,
  ) {
    _liveParties = event.page.items;
    _liveCursor = event.page.nextCursor;
    _liveHasMore = event.page.hasMore;

    if (_liveParties.isNotEmpty && _olderParties.isNotEmpty) {
      final liveIds = _liveParties.map((party) => party.id).toSet();
      _olderParties = _olderParties
          .where((party) => !liveIds.contains(party.id))
          .toList();
    }

    final combined = _mergeParties(_liveParties, _olderParties);
    final effectiveCursor = _olderParties.isEmpty ? _liveCursor : _olderCursor;
    final effectiveHasMore = _olderParties.isEmpty
        ? _liveHasMore
        : _olderHasMore;

    emit(
      PartySuccess(
        data: state.data.copyWith(
          parties: combined,
          partiesCursor: effectiveCursor,
          hasMoreParties: effectiveHasMore,
          isLoadingMoreParties: false,
        ),
      ),
    );
  }

  Future<void> _onPartyRoomsRequested(
    PartyRoomsRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data));

    try {
      final createdParties = await _partyViewModel.loadCreatedParties();

      emit(
        PartySuccess(
          data: state.data.copyWith(
            createdParties: createdParties,
            clearNavigationPartyId: true,
            didLeaveParty: false,
            isCreateCompleted: false,
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('[PartyBloc] Party load failed in rooms request: $e');
      debugPrintStack(stackTrace: s);
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  Future<void> _onPartyDetailsRequested(
    PartyDetailsRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data));
    await _partyMembersSubscription?.cancel();
    _partyMembersSubscription = _partyViewModel
        .watchPartyMembers(event.partyId)
        .listen((players) {
          add(
            PartyMembersLiveUpdated(partyId: event.partyId, players: players),
          );
        });

    try {
      final party = await _partyViewModel.loadPartyDetails(event.partyId);
      emit(
        PartySuccess(
          data: state.data.copyWith(
            selectedParty: party,
            currentPartyId: party.id,
            clearNavigationPartyId: true,
            didLeaveParty: false,
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('[PartyBloc] Party load failed in details request: $e');
      debugPrintStack(stackTrace: s);
      await _partyMembersSubscription?.cancel();
      _partyMembersSubscription = null;
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  void _onPartyMembersLiveUpdated(
    PartyMembersLiveUpdated event,
    Emitter<PartyState> emit,
  ) {
    final selected = state.data.selectedParty;
    if (selected == null || selected.id != event.partyId) {
      return;
    }
    final updatedParty = selected.copyWith(players: event.players);
    emit(
      PartySuccess(
        data: state.data.copyWith(
          selectedParty: updatedParty,
          parties: _replacePartyInList(state.data.parties, updatedParty),
          createdParties: _replacePartyInList(
            state.data.createdParties,
            updatedParty,
          ),
          joinedParties: _replacePartyInList(
            state.data.joinedParties,
            updatedParty,
          ),
        ),
      ),
    );
  }

  Future<void> _onPartyJoinRequested(
    PartyJoinRequested event,
    Emitter<PartyState> emit,
  ) async {
    final rollbackData = state.data;
    final optimisticParty = _findPartyById(state.data.parties, event.partyId);
    if (optimisticParty != null) {
      emit(
        PartySuccess(
          data: state.data.copyWith(
            selectedParty: optimisticParty,
            currentPartyId: optimisticParty.id,
            navigationPartyId: optimisticParty.id,
          ),
        ),
      );
    } else {
      emit(PartyLoading(data: state.data));
    }

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        debugPrint('[PartyBloc] joinParty auth: no currentUser');
        emit(PartyError(message: AppStrings.authFailed, data: rollbackData));
        return;
      } else {
        final providers = authUser.providerData
            .map((provider) => provider.providerId)
            .join(',');
        debugPrint(
          '[PartyBloc] joinParty auth: uid=${authUser.uid} '
          'isAnonymous=${authUser.isAnonymous} providers=[$providers]',
        );
        try {
          final token = await authUser.getIdToken(true);
          debugPrint(
            '[PartyBloc] joinParty auth: idToken=${token == null || token.isEmpty ? 'missing' : 'ok'}',
          );
        } catch (e, s) {
          debugPrint('[PartyBloc] joinParty auth: getIdToken failed: $e');
          debugPrintStack(stackTrace: s);
        }
      }
      final joinedParty = await _partyViewModel.joinParty(
        partyId: event.partyId,
        user: UserModel(
          id: authUser.uid,
          displayName: authUser.displayName?.trim().isNotEmpty == true
              ? authUser.displayName!.trim()
              : 'QueuePlayer',
          avatarUrl: authUser.photoURL,
        ),
      );
      final updatedParties = _replacePartyInList(
        state.data.parties,
        joinedParty,
      );
      final updatedJoined = _upsertParty(state.data.joinedParties, joinedParty);
      final updatedCreated = _replacePartyInList(
        state.data.createdParties,
        joinedParty,
      );

      debugPrint(
        '[PartyBloc] User joined party '
        'partyId=${joinedParty.id} userId=${authUser.uid}',
      );

      emit(
        PartySuccess(
          data: state.data.copyWith(
            selectedParty: joinedParty,
            currentPartyId: joinedParty.id,
            navigationPartyId: joinedParty.id,
            parties: updatedParties,
            createdParties: updatedCreated,
            joinedParties: updatedJoined,
            didLeaveParty: false,
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('[PartyBloc] Party load failed in join request: $e');
      debugPrintStack(stackTrace: s);
      emit(PartyError(message: AppStrings.partyLoadFailed, data: rollbackData));
    }
  }

  void _onPartyCreateStarted(
    PartyCreateStarted event,
    Emitter<PartyState> emit,
  ) {
    final requestedGameId = event.gameId.isEmpty
        ? AppOptions.valorantId
        : event.gameId;
    final gameId = _normalizeGameId(requestedGameId);
    final defaultRank = AppOptions.defaultRankForGame(gameId).name;

    emit(
      PartySuccess(
        data: state.data.copyWith(
          activeGameId: gameId,
          form: CreatePartyFormModel(
            gameId: gameId,
            partyName: _buildAutoPartyName(gameId: gameId, maxPlayers: 4),
            useAutoName: true,
            rank: defaultRank,
          ),
          clearNavigationPartyId: true,
          isCreateCompleted: false,
        ),
      ),
    );
  }

  void _onPartyFormNameChanged(
    PartyFormNameChanged event,
    Emitter<PartyState> emit,
  ) {
    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: state.data.form.copyWith(
            partyName: event.value,
            useAutoName: false,
          ),
          isCreateCompleted: false,
        ),
      ),
    );
  }

  void _onPartyFormGameChanged(
    PartyFormGameChanged event,
    Emitter<PartyState> emit,
  ) {
    final gameId = _normalizeGameId(event.value);
    final defaultRank = AppOptions.defaultRankForGame(gameId).name;
    final partyName = state.data.form.useAutoName
        ? _buildAutoPartyName(
            gameId: gameId,
            maxPlayers: state.data.form.maxPlayers,
          )
        : state.data.form.partyName;

    emit(
      PartySuccess(
        data: state.data.copyWith(
          activeGameId: gameId,
          form: state.data.form.copyWith(
            gameId: gameId,
            partyName: partyName,
            rank: defaultRank,
          ),
          isCreateCompleted: false,
        ),
      ),
    );
  }

  void _onPartyFormRankChanged(
    PartyFormRankChanged event,
    Emitter<PartyState> emit,
  ) {
    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: state.data.form.copyWith(rank: event.value),
          isCreateCompleted: false,
        ),
      ),
    );
  }

  void _onPartyFormLanguageChanged(
    PartyFormLanguageChanged event,
    Emitter<PartyState> emit,
  ) {
    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: state.data.form.copyWith(language: event.value),
          isCreateCompleted: false,
        ),
      ),
    );
  }

  void _onPartyFormMaxPlayersIncremented(
    PartyFormMaxPlayersIncremented event,
    Emitter<PartyState> emit,
  ) {
    final next = min(5, state.data.form.maxPlayers + 1);
    final form = state.data.form;
    final gameId = _normalizeGameId(
      form.gameId.isEmpty ? state.data.activeGameId : form.gameId,
    );

    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: form.copyWith(
            maxPlayers: next,
            partyName: form.useAutoName
                ? _buildAutoPartyName(gameId: gameId, maxPlayers: next)
                : form.partyName,
          ),
          isCreateCompleted: false,
        ),
      ),
    );
  }

  void _onPartyFormMaxPlayersDecremented(
    PartyFormMaxPlayersDecremented event,
    Emitter<PartyState> emit,
  ) {
    final next = max(2, state.data.form.maxPlayers - 1);
    final form = state.data.form;
    final gameId = _normalizeGameId(
      form.gameId.isEmpty ? state.data.activeGameId : form.gameId,
    );

    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: form.copyWith(
            maxPlayers: next,
            partyName: form.useAutoName
                ? _buildAutoPartyName(gameId: gameId, maxPlayers: next)
                : form.partyName,
          ),
          isCreateCompleted: false,
        ),
      ),
    );
  }

  void _onPartyFormCodeChanged(
    PartyFormCodeChanged event,
    Emitter<PartyState> emit,
  ) {
    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: state.data.form.copyWith(partyCode: event.value),
          isCreateCompleted: false,
        ),
      ),
    );
  }

  Future<void> _onPartyFilterRankChanged(
    PartyFilterRankChanged event,
    Emitter<PartyState> emit,
  ) async {
    final nextData = state.data.copyWith(
      selectedRankFilter: event.value,
      clearSelectedRankFilter: event.value == null,
      parties: const <PartyModel>[],
      clearPartiesCursor: true,
      hasMoreParties: true,
      isLoadingMoreParties: false,
    );
    emit(PartyLoading(data: nextData));
    await _reloadPartiesWithFilters(nextData, emit);
  }

  Future<void> _onPartyFilterLanguageChanged(
    PartyFilterLanguageChanged event,
    Emitter<PartyState> emit,
  ) async {
    final nextData = state.data.copyWith(
      selectedLanguageFilter: event.value,
      clearSelectedLanguageFilter: event.value == null,
      parties: const <PartyModel>[],
      clearPartiesCursor: true,
      hasMoreParties: true,
      isLoadingMoreParties: false,
    );
    emit(PartyLoading(data: nextData));
    await _reloadPartiesWithFilters(nextData, emit);
  }

  Future<void> _onPartyCreateSubmitted(
    PartyCreateSubmitted event,
    Emitter<PartyState> emit,
  ) async {
    final form = state.data.form;
    if (!form.isValid) {
      return;
    }

    emit(PartyLoading(data: state.data));

    try {
      final resolvedGameId = _normalizeGameId(
        form.gameId.isEmpty ? state.data.activeGameId : form.gameId,
      );
      final createdParties = await _partyViewModel.loadCreatedParties();
      final alreadyHasRoom = createdParties.any(
        (party) => party.gameId == resolvedGameId,
      );
      if (alreadyHasRoom) {
        emit(
          PartyError(
            message: AppStrings.oneRoomPerGameMessage,
            data: state.data,
          ),
        );
        return;
      }

      final party = await _partyViewModel.createParty(
        gameId: resolvedGameId,
        form: form,
      );
      final updatedCreatedParties = await _partyViewModel.loadCreatedParties();
      final joinedParties = await _partyViewModel.loadJoinedParties();

      emit(
        PartySuccess(
          data: state.data.copyWith(
            selectedParty: party,
            currentPartyId: party.id,
            navigationPartyId: party.id,
            createdParties: updatedCreatedParties,
            joinedParties: joinedParties,
            isCreateCompleted: true,
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('[PartyBloc] Party load failed in create request: $e');
      debugPrintStack(stackTrace: s);
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  Future<void> _onPartyLeaveRequested(
    PartyLeaveRequested event,
    Emitter<PartyState> emit,
  ) async {
    final previousData = state.data;
    final isHostLeaving = state.data.createdParties.any(
      (party) => party.id == event.partyId,
    );
    final filteredCreated = state.data.createdParties
        .where((party) => !isHostLeaving || party.id != event.partyId)
        .toList();
    final filteredJoined = state.data.joinedParties
        .where((party) => party.id != event.partyId)
        .toList();
    final filteredParties = state.data.parties
        .where((party) => !isHostLeaving || party.id != event.partyId)
        .toList();

    final optimisticData = state.data.copyWith(
      parties: filteredParties,
      createdParties: filteredCreated,
      joinedParties: filteredJoined,
      clearCurrentPartyId: true,
      clearSelectedParty: true,
      navigationPartyId: _noPartyNavigationToken,
      didLeaveParty: false,
    );
    emit(PartySuccess(data: optimisticData));
    try {
      await _partyViewModel.leaveParty(event.partyId);
      await _partyMembersSubscription?.cancel();
      _partyMembersSubscription = null;
      emit(PartySuccess(data: optimisticData.copyWith(didLeaveParty: true)));
    } catch (e, s) {
      debugPrint('[PartyBloc] Party load failed in leave request: $e');
      debugPrintStack(stackTrace: s);
      emit(PartyError(message: AppStrings.partyLoadFailed, data: previousData));
    }
  }

  Future<void> _onPartyKickRequested(
    PartyKickRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data));
    try {
      final updatedParty = await _partyViewModel.kickPlayer(
        partyId: event.partyId,
        playerId: event.playerId,
      );

      emit(
        PartySuccess(
          data: state.data.copyWith(
            selectedParty: updatedParty,
            parties: _replacePartyInList(state.data.parties, updatedParty),
            createdParties: _replacePartyInList(
              state.data.createdParties,
              updatedParty,
            ),
            joinedParties: _replacePartyInList(
              state.data.joinedParties,
              updatedParty,
            ),
            clearNavigationPartyId: true,
            didLeaveParty: false,
          ),
        ),
      );
    } catch (e, s) {
      debugPrint('[PartyBloc] Party load failed in kick request: $e');
      debugPrintStack(stackTrace: s);
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  void _onPartyNavigationConsumed(
    PartyNavigationConsumed event,
    Emitter<PartyState> emit,
  ) {
    emit(
      PartySuccess(
        data: state.data.copyWith(
          clearNavigationPartyId: true,
          didLeaveParty: false,
          isCreateCompleted: false,
        ),
      ),
    );
  }

  Future<void> _reloadPartiesWithFilters(
    PartyViewData data,
    Emitter<PartyState> emit,
  ) async {
    await _liveSubscription?.cancel();
    _liveSubscription = null;
    _liveParties = const <PartyModel>[];
    _olderParties = const <PartyModel>[];
    _liveCursor = null;
    _olderCursor = null;
    _liveHasMore = true;
    _olderHasMore = true;

    emit(
      PartyLoading(
        data: data.copyWith(
          parties: const <PartyModel>[],
          clearPartiesCursor: true,
          hasMoreParties: true,
          isLoadingMoreParties: false,
        ),
      ),
    );

    _liveSubscription = _partyViewModel
        .watchPartiesPage(
          gameId: data.activeGameId,
          rankFilter: data.selectedRankFilter,
          languageFilter: data.selectedLanguageFilter,
          limit: _partyPageSize,
        )
        .listen((page) {
          add(PartyListLivePageUpdated(page: page));
        });
  }

  String _normalizeGameId(String gameId) {
    final hasGame = AppOptions.gameOptions.any(
      (GameOption game) => game.id == gameId,
    );
    return hasGame ? gameId : AppOptions.valorantId;
  }

  String _buildAutoPartyName({
    required String gameId,
    required int maxPlayers,
  }) {
    final gameName = AppOptions.gameNameById(gameId);
    final neededPlayers = max(1, maxPlayers - 1);
    return AppStrings.generatedPartyName(
      gameName: gameName,
      neededPlayers: neededPlayers,
    );
  }

  List<PartyModel> _replacePartyInList(
    List<PartyModel> list,
    PartyModel updated,
  ) {
    if (list.isEmpty) {
      return list;
    }
    return list
        .map((party) => party.id == updated.id ? updated : party)
        .toList();
  }

  List<PartyModel> _upsertParty(List<PartyModel> list, PartyModel party) {
    if (list.isEmpty) {
      return <PartyModel>[party];
    }
    final exists = list.any((item) => item.id == party.id);
    if (!exists) {
      return <PartyModel>[party, ...list];
    }
    return _replacePartyInList(list, party);
  }

  PartyModel? _findPartyById(List<PartyModel> list, String partyId) {
    if (list.isEmpty) {
      return null;
    }
    for (final party in list) {
      if (party.id == partyId) {
        return party;
      }
    }
    return null;
  }

  List<PartyModel> _mergeParties(
    List<PartyModel> live,
    List<PartyModel> older,
  ) {
    final byId = <String, PartyModel>{};
    for (final party in live) {
      byId[party.id] = party;
    }
    for (final party in older) {
      byId.putIfAbsent(party.id, () => party);
    }
    final combined = byId.values.toList();
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return combined;
  }

  @override
  Future<void> close() async {
    await _liveSubscription?.cancel();
    await _partyMembersSubscription?.cancel();
    return super.close();
  }
}
