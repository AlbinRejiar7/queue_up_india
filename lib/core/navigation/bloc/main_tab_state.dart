import 'package:equatable/equatable.dart';

class MainTabState extends Equatable {
  const MainTabState({required this.activeIndex});

  final int activeIndex;

  MainTabState copyWith({int? activeIndex}) {
    return MainTabState(activeIndex: activeIndex ?? this.activeIndex);
  }

  @override
  List<Object?> get props => <Object?>[activeIndex];
}
