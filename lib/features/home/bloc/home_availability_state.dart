import 'package:equatable/equatable.dart';

class HomeAvailabilityState extends Equatable {
  const HomeAvailabilityState({
    required this.selectedGameId,
    required this.selectedLanguage,
    required this.selectedRank,
    required this.isAvailable,
  });

  const HomeAvailabilityState.initial()
    : selectedGameId = null,
      selectedLanguage = null,
      selectedRank = null,
      isAvailable = false;

  final String? selectedGameId;
  final String? selectedLanguage;
  final String? selectedRank;
  final bool isAvailable;

  bool get canToggleAvailability =>
      selectedGameId != null &&
      selectedLanguage != null &&
      selectedRank != null;

  HomeAvailabilityState copyWith({
    String? selectedGameId,
    bool clearGameId = false,
    String? selectedLanguage,
    bool clearLanguage = false,
    String? selectedRank,
    bool clearRank = false,
    bool? isAvailable,
  }) {
    return HomeAvailabilityState(
      selectedGameId: clearGameId ? null : selectedGameId ?? this.selectedGameId,
      selectedLanguage: clearLanguage
          ? null
          : selectedLanguage ?? this.selectedLanguage,
      selectedRank: clearRank ? null : selectedRank ?? this.selectedRank,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    selectedGameId,
    selectedLanguage,
    selectedRank,
    isAvailable,
  ];
}
