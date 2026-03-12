import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:queue_up_india/features/party/models/party_model.dart';

import '../../../core/constants/app_options.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/models/user_model.dart';
import '../models/create_party_form_model.dart';
import '../viewmodel/party_view_model.dart';
import 'party_event.dart';
import 'party_state.dart';

class PartyBloc extends Bloc<PartyEvent, PartyState> {
  PartyBloc({required PartyViewModel partyViewModel})
    : _partyViewModel = partyViewModel,
      super(const PartyInitial()) {
    on<PartySessionChecked>(_onSessionChecked);
    on<PartyListRequested>(_onPartyListRequested);
    on<PartyRoomsRequested>(_onPartyRoomsRequested);
    on<PartyDetailsRequested>(_onPartyDetailsRequested);
    on<PartyJoinRequested>(_onPartyJoinRequested);
    on<PartyCreateStarted>(_onPartyCreateStarted);
    on<PartyFormNameChanged>(_onPartyFormNameChanged);
    on<PartyFormAutoNameToggled>(_onPartyFormAutoNameToggled);
    on<PartyFormGameChanged>(_onPartyFormGameChanged);
    on<PartyFormRankChanged>(_onPartyFormRankChanged);
    on<PartyFormLanguageChanged>(_onPartyFormLanguageChanged);
    on<PartyFormMaxPlayersIncremented>(_onPartyFormMaxPlayersIncremented);
    on<PartyFormMaxPlayersDecremented>(_onPartyFormMaxPlayersDecremented);
    on<PartyFormCodeChanged>(_onPartyFormCodeChanged);
    on<PartyFormCodeGenerated>(_onPartyFormCodeGenerated);
    on<PartyCreateSubmitted>(_onPartyCreateSubmitted);
    on<PartyLeaveRequested>(_onPartyLeaveRequested);
    on<PartyKickRequested>(_onPartyKickRequested);
    on<PartyNavigationConsumed>(_onPartyNavigationConsumed);
  }

  static const String _noPartyNavigationToken = 'none';

  final PartyViewModel _partyViewModel;

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
    } catch (_) {
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  Future<void> _onPartyListRequested(
    PartyListRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data.copyWith(activeGameId: event.gameId)));

    try {
      final parties = await _partyViewModel.loadParties(event.gameId);
      emit(
        PartySuccess(
          data: state.data.copyWith(
            activeGameId: event.gameId,
            parties: parties,
            clearNavigationPartyId: true,
            didLeaveParty: false,
            isCreateCompleted: false,
          ),
        ),
      );
    } catch (_) {
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  Future<void> _onPartyRoomsRequested(
    PartyRoomsRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data));

    try {
      final createdParties = await _partyViewModel.loadCreatedParties();
      final joinedParties = await _partyViewModel.loadJoinedParties();

      emit(
        PartySuccess(
          data: state.data.copyWith(
            createdParties: createdParties,
            joinedParties: joinedParties,
            clearNavigationPartyId: true,
            didLeaveParty: false,
            isCreateCompleted: false,
          ),
        ),
      );
    } catch (_) {
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  Future<void> _onPartyDetailsRequested(
    PartyDetailsRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data));

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
    } catch (_) {
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  Future<void> _onPartyJoinRequested(
    PartyJoinRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data));

    try {
      final joinedParty = await _partyViewModel.joinParty(
        partyId: event.partyId,
        user: const UserModel(
          id: 'u_guest_join',
          displayName: 'GuestPlayer',
          isGuest: true,
        ),
      );
      final createdParties = await _partyViewModel.loadCreatedParties();
      final joinedParties = await _partyViewModel.loadJoinedParties();

      emit(
        PartySuccess(
          data: state.data.copyWith(
            selectedParty: joinedParty,
            currentPartyId: joinedParty.id,
            navigationPartyId: joinedParty.id,
            createdParties: createdParties,
            joinedParties: joinedParties,
            didLeaveParty: false,
          ),
        ),
      );
    } catch (_) {
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
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
            partyCode: _generatePartyCode(),
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
    if (state.data.form.useAutoName) {
      return;
    }

    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: state.data.form.copyWith(partyName: event.value),
          isCreateCompleted: false,
        ),
      ),
    );
  }

  void _onPartyFormAutoNameToggled(
    PartyFormAutoNameToggled event,
    Emitter<PartyState> emit,
  ) {
    final form = state.data.form;
    final gameId = _normalizeGameId(
      form.gameId.isEmpty ? state.data.activeGameId : form.gameId,
    );
    final partyName = event.useAutoName
        ? _buildAutoPartyName(gameId: gameId, maxPlayers: form.maxPlayers)
        : form.partyName;

    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: form.copyWith(
            useAutoName: event.useAutoName,
            partyName: partyName,
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

  void _onPartyFormCodeGenerated(
    PartyFormCodeGenerated event,
    Emitter<PartyState> emit,
  ) {
    emit(
      PartySuccess(
        data: state.data.copyWith(
          form: state.data.form.copyWith(partyCode: _generatePartyCode()),
          isCreateCompleted: false,
        ),
      ),
    );
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
      final party = await _partyViewModel.createParty(
        gameId: _normalizeGameId(
          form.gameId.isEmpty ? state.data.activeGameId : form.gameId,
        ),
        form: form,
      );
      final createdParties = await _partyViewModel.loadCreatedParties();
      final joinedParties = await _partyViewModel.loadJoinedParties();

      emit(
        PartySuccess(
          data: state.data.copyWith(
            selectedParty: party,
            currentPartyId: party.id,
            navigationPartyId: party.id,
            createdParties: createdParties,
            joinedParties: joinedParties,
            isCreateCompleted: true,
          ),
        ),
      );
    } catch (_) {
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
    }
  }

  Future<void> _onPartyLeaveRequested(
    PartyLeaveRequested event,
    Emitter<PartyState> emit,
  ) async {
    emit(PartyLoading(data: state.data));
    try {
      await _partyViewModel.leaveParty(event.partyId);
      final createdParties = await _partyViewModel.loadCreatedParties();
      final joinedParties = await _partyViewModel.loadJoinedParties();
      emit(
        PartySuccess(
          data: state.data.copyWith(
            clearCurrentPartyId: true,
            clearSelectedParty: true,
            navigationPartyId: _noPartyNavigationToken,
            createdParties: createdParties,
            joinedParties: joinedParties,
            didLeaveParty: true,
          ),
        ),
      );
    } catch (_) {
      emit(PartyError(message: AppStrings.partyLoadFailed, data: state.data));
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
    } catch (_) {
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

  String _generatePartyCode() {
    final random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final prefix = String.fromCharCodes(
      List<int>.generate(
        4,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
    final suffix = 1000 + random.nextInt(9000);
    return '$prefix-$suffix';
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
}
