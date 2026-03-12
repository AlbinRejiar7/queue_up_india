import 'package:equatable/equatable.dart';

class ProfilePreferencesModel extends Equatable {
  const ProfilePreferencesModel({
    required this.queueName,
    required this.preferredLanguageCode,
    required this.avatarUrl,
  });

  final String queueName;
  final String preferredLanguageCode;
  final String avatarUrl;

  ProfilePreferencesModel copyWith({
    String? queueName,
    String? preferredLanguageCode,
    String? avatarUrl,
  }) {
    return ProfilePreferencesModel(
      queueName: queueName ?? this.queueName,
      preferredLanguageCode:
          preferredLanguageCode ?? this.preferredLanguageCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    queueName,
    preferredLanguageCode,
    avatarUrl,
  ];
}
