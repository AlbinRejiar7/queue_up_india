import 'package:equatable/equatable.dart';

class SoloMatchmakingMetadataModel extends Equatable {
  const SoloMatchmakingMetadataModel({
    required this.bucketId,
    required this.activeUsers,
    required this.recentJoins,
    this.updatedAt,
  });

  final String bucketId;
  final int activeUsers;
  final int recentJoins;
  final DateTime? updatedAt;

  factory SoloMatchmakingMetadataModel.fromMap({
    required String bucketId,
    required Map<String, dynamic> data,
  }) {
    return SoloMatchmakingMetadataModel(
      bucketId: bucketId,
      activeUsers: (data['activeUsers'] as num?)?.toInt() ?? 0,
      recentJoins: (data['recentJoins'] as num?)?.toInt() ?? 0,
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    bucketId,
    activeUsers,
    recentJoins,
    updatedAt,
  ];
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  final dynamic timestampDate = value.toDate?.call();
  if (timestampDate is DateTime) {
    return timestampDate;
  }
  return null;
}
