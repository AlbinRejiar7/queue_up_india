import 'package:equatable/equatable.dart';

abstract class PartyEvent extends Equatable {
  const PartyEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class PartySessionChecked extends PartyEvent {
  const PartySessionChecked();
}

class PartyListRequested extends PartyEvent {
  const PartyListRequested({required this.gameId});

  final String gameId;

  @override
  List<Object?> get props => <Object?>[gameId];
}

class PartyRoomsRequested extends PartyEvent {
  const PartyRoomsRequested();
}

class PartyDetailsRequested extends PartyEvent {
  const PartyDetailsRequested({required this.partyId});

  final String partyId;

  @override
  List<Object?> get props => <Object?>[partyId];
}

class PartyJoinRequested extends PartyEvent {
  const PartyJoinRequested({required this.partyId});

  final String partyId;

  @override
  List<Object?> get props => <Object?>[partyId];
}

class PartyCreateStarted extends PartyEvent {
  const PartyCreateStarted({required this.gameId});

  final String gameId;

  @override
  List<Object?> get props => <Object?>[gameId];
}

class PartyFormNameChanged extends PartyEvent {
  const PartyFormNameChanged({required this.value});

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

class PartyFormAutoNameToggled extends PartyEvent {
  const PartyFormAutoNameToggled({required this.useAutoName});

  final bool useAutoName;

  @override
  List<Object?> get props => <Object?>[useAutoName];
}

class PartyFormGameChanged extends PartyEvent {
  const PartyFormGameChanged({required this.value});

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

class PartyFormRankChanged extends PartyEvent {
  const PartyFormRankChanged({required this.value});

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

class PartyFormLanguageChanged extends PartyEvent {
  const PartyFormLanguageChanged({required this.value});

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

class PartyFormMaxPlayersIncremented extends PartyEvent {
  const PartyFormMaxPlayersIncremented();
}

class PartyFormMaxPlayersDecremented extends PartyEvent {
  const PartyFormMaxPlayersDecremented();
}

class PartyFormCodeChanged extends PartyEvent {
  const PartyFormCodeChanged({required this.value});

  final String value;

  @override
  List<Object?> get props => <Object?>[value];
}

class PartyFormCodeGenerated extends PartyEvent {
  const PartyFormCodeGenerated();
}

class PartyCreateSubmitted extends PartyEvent {
  const PartyCreateSubmitted();
}

class PartyLeaveRequested extends PartyEvent {
  const PartyLeaveRequested({required this.partyId});

  final String partyId;

  @override
  List<Object?> get props => <Object?>[partyId];
}

class PartyKickRequested extends PartyEvent {
  const PartyKickRequested({required this.partyId, required this.playerId});

  final String partyId;
  final String playerId;

  @override
  List<Object?> get props => <Object?>[partyId, playerId];
}

class PartyNavigationConsumed extends PartyEvent {
  const PartyNavigationConsumed();
}
