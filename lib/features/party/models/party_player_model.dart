import 'package:equatable/equatable.dart';

class PartyPlayerModel extends Equatable {
  const PartyPlayerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.status,
    this.isHost = false,
    this.isMuted = false,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final String status;
  final bool isHost;
  final bool isMuted;

  PartyPlayerModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? status,
    bool? isHost,
    bool? isMuted,
  }) {
    return PartyPlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      isHost: isHost ?? this.isHost,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    avatarUrl,
    status,
    isHost,
    isMuted,
  ];
}
