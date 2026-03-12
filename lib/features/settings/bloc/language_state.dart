import 'package:equatable/equatable.dart';

import '../models/language_model.dart';

class LanguageViewData extends Equatable {
  const LanguageViewData({
    required this.languages,
    required this.isFirstLaunch,
    this.selectedCode,
    this.didCompleteSelection = false,
  });

  const LanguageViewData.initial()
    : languages = const <LanguageModel>[],
      selectedCode = null,
      isFirstLaunch = true,
      didCompleteSelection = false;

  final List<LanguageModel> languages;
  final String? selectedCode;
  final bool isFirstLaunch;
  final bool didCompleteSelection;

  bool get canContinue => selectedCode != null;

  LanguageViewData copyWith({
    List<LanguageModel>? languages,
    String? selectedCode,
    bool clearSelectedCode = false,
    bool? isFirstLaunch,
    bool? didCompleteSelection,
  }) {
    return LanguageViewData(
      languages: languages ?? this.languages,
      selectedCode: clearSelectedCode
          ? null
          : selectedCode ?? this.selectedCode,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      didCompleteSelection: didCompleteSelection ?? this.didCompleteSelection,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    languages,
    selectedCode,
    isFirstLaunch,
    didCompleteSelection,
  ];
}

abstract class LanguageState extends Equatable {
  const LanguageState({required this.data});

  final LanguageViewData data;

  @override
  List<Object?> get props => <Object?>[data];
}

class LanguageInitial extends LanguageState {
  const LanguageInitial() : super(data: const LanguageViewData.initial());
}

class LanguageLoading extends LanguageState {
  const LanguageLoading({required super.data});
}

class LanguageSuccess extends LanguageState {
  const LanguageSuccess({required super.data});
}

class LanguageError extends LanguageState {
  const LanguageError({required this.message, required super.data});

  final String message;

  @override
  List<Object?> get props => <Object?>[data, message];
}
