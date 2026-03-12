import 'package:equatable/equatable.dart';

class GameModel extends Equatable {
  const GameModel({
    required this.id,
    required this.name,
    required this.activePartiesLabel,
    required this.coverUrl,
  });

  final String id;
  final String name;
  final String activePartiesLabel;
  final String coverUrl;

  GameModel copyWith({
    String? id,
    String? name,
    String? activePartiesLabel,
    String? coverUrl,
  }) {
    return GameModel(
      id: id ?? this.id,
      name: name ?? this.name,
      activePartiesLabel: activePartiesLabel ?? this.activePartiesLabel,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, activePartiesLabel, coverUrl];
}
