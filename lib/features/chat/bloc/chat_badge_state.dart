import 'package:equatable/equatable.dart';

class ChatBadgeState extends Equatable {
  const ChatBadgeState({
    required this.hasUnread,
    required this.isLoading,
  });

  const ChatBadgeState.initial()
      : hasUnread = false,
        isLoading = true;

  final bool hasUnread;
  final bool isLoading;

  ChatBadgeState copyWith({
    bool? hasUnread,
    bool? isLoading,
  }) {
    return ChatBadgeState(
      hasUnread: hasUnread ?? this.hasUnread,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => <Object?>[hasUnread, isLoading];
}
