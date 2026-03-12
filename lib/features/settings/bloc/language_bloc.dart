import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../models/language_model.dart';
import '../viewmodel/language_view_model.dart';
import 'language_event.dart';
import 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc({required LanguageViewModel languageViewModel})
    : _languageViewModel = languageViewModel,
      super(const LanguageInitial()) {
    on<LanguageBootstrapRequested>(_onBootstrapRequested);
    on<LanguageSelected>(_onLanguageSelected);
    on<LanguageContinuePressed>(_onContinuePressed);
  }

  final LanguageViewModel _languageViewModel;

  Future<void> _onBootstrapRequested(
    LanguageBootstrapRequested event,
    Emitter<LanguageState> emit,
  ) async {
    emit(LanguageLoading(data: state.data));
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _languageViewModel.loadLanguages(),
        _languageViewModel.loadSelectedLanguageCode(),
        _languageViewModel.isFirstLaunch(),
      ]);

      emit(
        LanguageSuccess(
          data: state.data.copyWith(
            languages: List<LanguageModel>.from(results[0] as List<dynamic>),
            selectedCode: results[1] as String?,
            isFirstLaunch: results[2] as bool,
            didCompleteSelection: false,
          ),
        ),
      );
    } catch (_) {
      emit(
        LanguageError(data: state.data, message: AppStrings.saveLanguageFailed),
      );
    }
  }

  void _onLanguageSelected(
    LanguageSelected event,
    Emitter<LanguageState> emit,
  ) {
    emit(
      LanguageSuccess(
        data: state.data.copyWith(
          selectedCode: event.code,
          didCompleteSelection: false,
        ),
      ),
    );
  }

  Future<void> _onContinuePressed(
    LanguageContinuePressed event,
    Emitter<LanguageState> emit,
  ) async {
    final selectedCode = state.data.selectedCode;
    if (selectedCode == null) {
      return;
    }

    emit(LanguageLoading(data: state.data));
    try {
      await _languageViewModel.persistLanguageSelection(selectedCode);
      emit(
        LanguageSuccess(
          data: state.data.copyWith(
            isFirstLaunch: false,
            didCompleteSelection: true,
          ),
        ),
      );
    } catch (_) {
      emit(
        LanguageError(data: state.data, message: AppStrings.saveLanguageFailed),
      );
    }
  }
}
