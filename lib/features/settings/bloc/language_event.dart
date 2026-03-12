import 'package:equatable/equatable.dart';

abstract class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class LanguageBootstrapRequested extends LanguageEvent {
  const LanguageBootstrapRequested();
}

class LanguageSelected extends LanguageEvent {
  const LanguageSelected({required this.code});

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}

class LanguageContinuePressed extends LanguageEvent {
  const LanguageContinuePressed();
}
