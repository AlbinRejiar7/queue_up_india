import 'package:equatable/equatable.dart';

import '../../../core/constants/app_options.dart';
import '../models/create_party_form_model.dart';
import '../models/party_model.dart';

class PartyViewData extends Equatable {
  const PartyViewData({
    required this.activeGameId,
    required this.parties,
    required this.createdParties,
    required this.joinedParties,
    required this.form,
    this.selectedParty,
    this.currentPartyId,
    this.navigationPartyId,
    this.didLeaveParty = false,
    this.isCreateCompleted = false,
  });

  const PartyViewData.initial()
    : activeGameId = AppOptions.valorantId,
      parties = const <PartyModel>[],
      createdParties = const <PartyModel>[],
      joinedParties = const <PartyModel>[],
      form = const CreatePartyFormModel(),
      selectedParty = null,
      currentPartyId = null,
      navigationPartyId = null,
      didLeaveParty = false,
      isCreateCompleted = false;

  final String activeGameId;
  final List<PartyModel> parties;
  final List<PartyModel> createdParties;
  final List<PartyModel> joinedParties;
  final PartyModel? selectedParty;
  final CreatePartyFormModel form;
  final String? currentPartyId;
  final String? navigationPartyId;
  final bool didLeaveParty;
  final bool isCreateCompleted;

  PartyViewData copyWith({
    String? activeGameId,
    List<PartyModel>? parties,
    List<PartyModel>? createdParties,
    List<PartyModel>? joinedParties,
    PartyModel? selectedParty,
    bool clearSelectedParty = false,
    CreatePartyFormModel? form,
    String? currentPartyId,
    bool clearCurrentPartyId = false,
    String? navigationPartyId,
    bool clearNavigationPartyId = false,
    bool? didLeaveParty,
    bool? isCreateCompleted,
  }) {
    return PartyViewData(
      activeGameId: activeGameId ?? this.activeGameId,
      parties: parties ?? this.parties,
      createdParties: createdParties ?? this.createdParties,
      joinedParties: joinedParties ?? this.joinedParties,
      selectedParty: clearSelectedParty
          ? null
          : selectedParty ?? this.selectedParty,
      form: form ?? this.form,
      currentPartyId: clearCurrentPartyId
          ? null
          : currentPartyId ?? this.currentPartyId,
      navigationPartyId: clearNavigationPartyId
          ? null
          : navigationPartyId ?? this.navigationPartyId,
      didLeaveParty: didLeaveParty ?? this.didLeaveParty,
      isCreateCompleted: isCreateCompleted ?? this.isCreateCompleted,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    activeGameId,
    parties,
    createdParties,
    joinedParties,
    selectedParty,
    form,
    currentPartyId,
    navigationPartyId,
    didLeaveParty,
    isCreateCompleted,
  ];
}

abstract class PartyState extends Equatable {
  const PartyState({required this.data});

  final PartyViewData data;

  @override
  List<Object?> get props => <Object?>[data];
}

class PartyInitial extends PartyState {
  const PartyInitial() : super(data: const PartyViewData.initial());
}

class PartyLoading extends PartyState {
  const PartyLoading({required super.data});
}

class PartySuccess extends PartyState {
  const PartySuccess({required super.data});
}

class PartyError extends PartyState {
  const PartyError({required this.message, required super.data});

  final String message;

  @override
  List<Object?> get props => <Object?>[data, message];
}
