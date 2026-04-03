import 'package:hive_flutter/hive_flutter.dart';

import '../../models/chat_message.dart';
import '../../utils/direct_chat_firebase_debug.dart';

class ChatMessageCursor {
  const ChatMessageCursor({required this.messageId, required this.timestamp});

  final String messageId;
  final DateTime timestamp;
}

class DirectChatCacheStore {
  DirectChatCacheStore();

  static const String _boxName = 'direct_chat_messages_v1';
  static const int _maxMessagesPerChat = 120;

  Box<dynamic>? _box;

  Future<void> initialize() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  List<ChatMessage> loadMessages({
    required String userId,
    required String chatId,
  }) {
    final payload = _box?.get(_cacheKey(userId, chatId));
    if (payload is! Map) {
      return const <ChatMessage>[];
    }
    final rawMessages = payload['messages'];
    if (rawMessages is! List) {
      return const <ChatMessage>[];
    }

    final messages = rawMessages
        .whereType<Map>()
        .map(_deserializeMessage)
        .whereType<ChatMessage>()
        .toList();
    messages.sort(_compareMessages);
    DirectChatFirebaseDebug.info(
      'DirectChatCacheStore.loadMessages',
      'chatId=$chatId cached=${messages.length}',
    );
    return messages;
  }

  ChatMessageCursor? newestCursor({
    required String userId,
    required String chatId,
  }) {
    final messages = loadMessages(userId: userId, chatId: chatId);
    if (messages.isEmpty) {
      return null;
    }
    final newest = messages.last;
    return ChatMessageCursor(messageId: newest.id, timestamp: newest.timestamp);
  }

  ChatMessageCursor? oldestCursor({
    required String userId,
    required String chatId,
    int? limit,
  }) {
    final messages = loadMessages(userId: userId, chatId: chatId);
    if (messages.isEmpty) {
      return null;
    }
    final visibleMessages = limit != null && messages.length > limit
        ? messages.sublist(messages.length - limit)
        : messages;
    final oldest = visibleMessages.first;
    return ChatMessageCursor(messageId: oldest.id, timestamp: oldest.timestamp);
  }

  Future<void> mergeMessages({
    required String userId,
    required String chatId,
    required List<ChatMessage> messages,
  }) async {
    if (messages.isEmpty) {
      return;
    }

    final merged = <String, ChatMessage>{
      for (final message in loadMessages(userId: userId, chatId: chatId))
        message.id: message,
    };
    for (final message in messages) {
      merged[message.id] = message;
    }

    final sorted = merged.values.toList()..sort(_compareMessages);
    final trimmed = sorted.length > _maxMessagesPerChat
        ? sorted.sublist(sorted.length - _maxMessagesPerChat)
        : sorted;
    DirectChatFirebaseDebug.info(
      'DirectChatCacheStore.mergeMessages',
      'chatId=$chatId incoming=${messages.length} stored=${trimmed.length}',
    );

    await _box?.put(_cacheKey(userId, chatId), <String, dynamic>{
      'messages': trimmed.map(_serializeMessage).toList(),
      'updatedAtMs': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> clearUser(String userId) async {
    final box = _box;
    if (box == null) {
      return;
    }
    final prefix = '$userId::';
    final keysToDelete = box.keys
        .whereType<String>()
        .where((key) => key.startsWith(prefix))
        .toList();
    if (keysToDelete.isEmpty) {
      return;
    }
    await box.deleteAll(keysToDelete);
  }

  static int _compareMessages(ChatMessage a, ChatMessage b) {
    final timeCompare = a.timestamp.compareTo(b.timestamp);
    if (timeCompare != 0) {
      return timeCompare;
    }
    return a.id.compareTo(b.id);
  }

  static Map<String, dynamic> _serializeMessage(ChatMessage message) {
    return <String, dynamic>{
      'id': message.id,
      'senderName': message.senderName,
      'message': message.message,
      'isMe': message.isMe,
      'timestampMs': message.timestamp.millisecondsSinceEpoch,
    };
  }

  static ChatMessage? _deserializeMessage(Map<dynamic, dynamic> raw) {
    final id = raw['id'];
    final senderName = raw['senderName'];
    final message = raw['message'];
    final isMe = raw['isMe'];
    final timestampMs = raw['timestampMs'];
    if (id is! String ||
        senderName is! String ||
        message is! String ||
        isMe is! bool ||
        timestampMs is! int) {
      return null;
    }

    return ChatMessage(
      id: id,
      senderName: senderName,
      message: message,
      isMe: isMe,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
  }

  static String _cacheKey(String userId, String chatId) => '$userId::$chatId';
}
