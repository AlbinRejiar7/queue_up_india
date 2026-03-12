import 'package:equatable/equatable.dart';

abstract class MainTabEvent extends Equatable {
  const MainTabEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class MainTabInitialized extends MainTabEvent {
  const MainTabInitialized({required this.index});

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

class MainTabIndexChanged extends MainTabEvent {
  const MainTabIndexChanged({required this.index});

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}
