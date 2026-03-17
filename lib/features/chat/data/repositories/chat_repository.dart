import '../../models/chat_message.dart';
import '../../models/chat_thread.dart';
import '../../../../core/utils/paged_result.dart';

abstract class ChatRepository {
  Stream<PagedResult<ChatMessage>> watchLatestPartyMessages({
    required String partyId,
    int limit = 10,
  });

  Stream<PagedResult<ChatMessage>> watchLatestDirectMessages({
    required String peerId,
    int limit = 10,
  });

  Future<PagedResult<ChatMessage>> fetchOlderPartyMessages({
    required String partyId,
    Object? cursor,
    int limit = 10,
  });

  Future<PagedResult<ChatMessage>> fetchOlderDirectMessages({
    required String peerId,
    Object? cursor,
    int limit = 10,
  });

  Stream<PagedResult<ChatThread>> watchDirectThreadsPage({int limit = 10});

  Future<PagedResult<ChatThread>> fetchDirectThreadsPage({
    Object? cursor,
    int limit = 10,
  });

  Future<bool> hasDirectChat({required String peerId});

  Future<void> sendPartyMessage({
    required String partyId,
    required String message,
  });

  Future<void> sendDirectMessage({
    required String peerId,
    required String message,
  });

  Future<void> markDirectChatRead({required String peerId});
}
