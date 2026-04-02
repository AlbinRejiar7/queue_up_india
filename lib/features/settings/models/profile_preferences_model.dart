import 'package:equatable/equatable.dart';

class ProfilePreferencesModel extends Equatable {
  const ProfilePreferencesModel({
    required this.queueName,
    required this.preferredLanguageCode,
    required this.avatarUrl,
    this.recoveryEmail = '',
    this.authEmail = '',
    this.pendingAuthEmail = '',
    this.hasLinkedEmail = false,
  });

  final String queueName;
  final String preferredLanguageCode;
  final String avatarUrl;
  final String recoveryEmail;
  final String authEmail;
  final String pendingAuthEmail;
  final bool hasLinkedEmail;

  ProfilePreferencesModel copyWith({
    String? queueName,
    String? preferredLanguageCode,
    String? avatarUrl,
    String? recoveryEmail,
    String? authEmail,
    String? pendingAuthEmail,
    bool? hasLinkedEmail,
  }) {
    return ProfilePreferencesModel(
      queueName: queueName ?? this.queueName,
      preferredLanguageCode:
          preferredLanguageCode ?? this.preferredLanguageCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      authEmail: authEmail ?? this.authEmail,
      pendingAuthEmail: pendingAuthEmail ?? this.pendingAuthEmail,
      hasLinkedEmail: hasLinkedEmail ?? this.hasLinkedEmail,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    queueName,
    preferredLanguageCode,
    avatarUrl,
    recoveryEmail,
    authEmail,
    pendingAuthEmail,
    hasLinkedEmail,
  ];
}
