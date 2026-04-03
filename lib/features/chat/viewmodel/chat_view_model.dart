import '../data/repositories/chat_repository.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../../../core/utils/paged_result.dart';

enum ChatScope { party, direct }

class ChatViewModel {
  ChatViewModel({required ChatRepository repository})
    : _repository = repository;

  final ChatRepository _repository;

  Stream<List<ChatMessage>> watchMessages({
    required ChatScope scope,
    required String targetId,
  }) {
    if (scope == ChatScope.party) {
      return _repository
          .watchLatestPartyMessages(partyId: targetId)
          .map((page) => page.items);
    }
    return _repository
        .watchLatestDirectMessages(peerId: targetId)
        .map((page) => page.items);
  }

  Stream<PagedResult<ChatMessage>> watchLatestMessages({
    required ChatScope scope,
    required String targetId,
    int limit = 10,
  }) {
    if (scope == ChatScope.party) {
      return _repository.watchLatestPartyMessages(
        partyId: targetId,
        limit: limit,
      );
    }
    return _repository.watchLatestDirectMessages(
      peerId: targetId,
      limit: limit,
    );
  }

  Future<PagedResult<ChatMessage>> fetchOlderMessages({
    required ChatScope scope,
    required String targetId,
    Object? cursor,
    int limit = 10,
  }) {
    if (scope == ChatScope.party) {
      return _repository.fetchOlderPartyMessages(
        partyId: targetId,
        cursor: cursor,
        limit: limit,
      );
    }
    return _repository.fetchOlderDirectMessages(
      peerId: targetId,
      cursor: cursor,
      limit: limit,
    );
  }

  Stream<PagedResult<ChatThread>> watchDirectThreadsPage({int limit = 10}) {
    return _repository.watchDirectThreadsPage(limit: limit);
  }

  Stream<bool> watchHasUnreadDirectThreads({int limit = 20}) {
    return _repository.watchHasUnreadDirectThreads(limit: limit);
  }

  Future<PagedResult<ChatThread>> fetchDirectThreadsPage({
    Object? cursor,
    int limit = 10,
  }) {
    return _repository.fetchDirectThreadsPage(cursor: cursor, limit: limit);
  }

  Future<bool> hasDirectChat({required String peerId}) {
    return _repository.hasDirectChat(peerId: peerId);
  }

  Future<void> sendMessage({
    required ChatScope scope,
    required String targetId,
    required String message,
  }) {
    if (scope == ChatScope.party) {
      return _repository.sendPartyMessage(partyId: targetId, message: message);
    }
    return _repository.sendDirectMessage(peerId: targetId, message: message);
  }

  Future<void> markDirectChatRead({required String peerId}) {
    return _repository.markDirectChatRead(peerId: peerId);
  }
}
