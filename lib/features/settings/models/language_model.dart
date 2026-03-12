import 'package:equatable/equatable.dart';

class LanguageModel extends Equatable {
  const LanguageModel({
    required this.code,
    required this.nativeLabel,
    required this.englishLabel,
    required this.subtitle,
  });

  final String code;
  final String nativeLabel;
  final String englishLabel;
  final String subtitle;

  LanguageModel copyWith({
    String? code,
    String? nativeLabel,
    String? englishLabel,
    String? subtitle,
  }) {
    return LanguageModel(
      code: code ?? this.code,
      nativeLabel: nativeLabel ?? this.nativeLabel,
      englishLabel: englishLabel ?? this.englishLabel,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    code,
    nativeLabel,
    englishLabel,
    subtitle,
  ];
}
