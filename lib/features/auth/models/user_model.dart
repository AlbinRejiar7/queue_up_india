import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.displayName,
    required this.isGuest,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final bool isGuest;
  final String? avatarUrl;

  UserModel copyWith({
    String? id,
    String? displayName,
    bool? isGuest,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      isGuest: isGuest ?? this.isGuest,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, displayName, isGuest, avatarUrl];
}
