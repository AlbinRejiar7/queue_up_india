import 'package:equatable/equatable.dart';

abstract class HomeAvailabilityEvent extends Equatable {
  const HomeAvailabilityEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class HomeAvailabilityInitialized extends HomeAvailabilityEvent {
  const HomeAvailabilityInitialized({this.gameId});

  final String? gameId;

  @override
  List<Object?> get props => <Object?>[gameId];
}

class HomeAvailabilityGameChanged extends HomeAvailabilityEvent {
  const HomeAvailabilityGameChanged({required this.gameId});

  final String gameId;

  @override
  List<Object?> get props => <Object?>[gameId];
}

class HomeAvailabilityRankChanged extends HomeAvailabilityEvent {
  const HomeAvailabilityRankChanged({this.rank});

  final String? rank;

  @override
  List<Object?> get props => <Object?>[rank];
}

class HomeAvailabilityLanguageChanged extends HomeAvailabilityEvent {
  const HomeAvailabilityLanguageChanged({this.language});

  final String? language;

  @override
  List<Object?> get props => <Object?>[language];
}

class HomeAvailabilityToggled extends HomeAvailabilityEvent {
  const HomeAvailabilityToggled();
}
