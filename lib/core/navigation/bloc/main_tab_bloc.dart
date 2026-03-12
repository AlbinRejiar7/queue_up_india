import 'package:flutter_bloc/flutter_bloc.dart';

import 'main_tab_event.dart';
import 'main_tab_state.dart';

class MainTabBloc extends Bloc<MainTabEvent, MainTabState> {
  MainTabBloc() : super(const MainTabState(activeIndex: 0)) {
    on<MainTabInitialized>(_onInitialized);
    on<MainTabIndexChanged>(_onIndexChanged);
  }

  void _onInitialized(
    MainTabInitialized event,
    Emitter<MainTabState> emit,
  ) {
    if (event.index != state.activeIndex) {
      emit(state.copyWith(activeIndex: event.index));
    }
  }

  void _onIndexChanged(
    MainTabIndexChanged event,
    Emitter<MainTabState> emit,
  ) {
    if (event.index != state.activeIndex) {
      emit(state.copyWith(activeIndex: event.index));
    }
  }
}
