import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_message.dart';
import '../../models/chat_thread.dart';
import '../../../../core/constants/app_images.dart';
import 'chat_repository.dart';
import '../../../../core/utils/paged_result.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Stream<PagedResult<ChatMessage>> watchLatestPartyMessages({
    required String partyId,
    int limit = 10,
  }) {
    return _db
        .collection('parties')
        .doc(partyId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final items = _mapMessages(snapshot.docs).reversed.toList();
          final nextCursor =
              snapshot.docs.isEmpty ? null : snapshot.docs.last;
          final hasMore = snapshot.docs.length == limit;
          return PagedResult<ChatMessage>(
            items: items,
            hasMore: hasMore,
            nextCursor: nextCursor,
          );
        });
  }

  @override
  Stream<PagedResult<ChatMessage>> watchLatestDirectMessages({
    required String peerId,
    int limit = 10,
  }) {
    final chatId = _chatIdForPeer(peerId);
    return _db
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final items = _mapMessages(snapshot.docs).reversed.toList();
          final nextCursor =
              snapshot.docs.isEmpty ? null : snapshot.docs.last;
          final hasMore = snapshot.docs.length == limit;
          return PagedResult<ChatMessage>(
            items: items,
            hasMore: hasMore,
            nextCursor: nextCursor,
          );
        });
  }

  @override
  Stream<PagedResult<ChatThread>> watchDirectThreadsPage({int limit = 10}) {
    final uid = _requireUserId();
    Query<Map<String, dynamic>> query = _db
        .collection('direct_chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);

    return query.snapshots().asyncMap((snapshot) async {
      final threads = await _mapThreads(snapshot.docs);
      final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
      final hasMore = snapshot.docs.length == limit;
      return PagedResult<ChatThread>(
        items: threads,
        hasMore: hasMore,
        nextCursor: nextCursor,
      );
    });
  }

  @override
  Future<PagedResult<ChatMessage>> fetchOlderPartyMessages({
    required String partyId,
    Object? cursor,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('parties')
        .doc(partyId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);

    if (cursor is QueryDocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final items = _mapMessages(snapshot.docs).reversed.toList();
    final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    final hasMore = snapshot.docs.length == limit;

    return PagedResult<ChatMessage>(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<PagedResult<ChatThread>> fetchDirectThreadsPage({
    Object? cursor,
    int limit = 10,
  }) async {
    final uid = _requireUserId();
    Query<Map<String, dynamic>> query = _db
        .collection('direct_chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);

    if (cursor is QueryDocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final threads = await _mapThreads(snapshot.docs);
    final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    final hasMore = snapshot.docs.length == limit;

    return PagedResult<ChatThread>(
      items: threads,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<bool> hasDirectChat({required String peerId}) async {
    final uid = _requireUserId();
    if (peerId.trim().isEmpty) {
      return false;
    }
    final chatId = _chatIdForPeer(peerId);
    final snapshot = await _db.collection('direct_chats').doc(chatId).get();
    if (!snapshot.exists) {
      return false;
    }
    final data = snapshot.data();
    final participants =
        (data?['participants'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    return participants.contains(uid) && participants.contains(peerId);
  }

  @override
  Future<PagedResult<ChatMessage>> fetchOlderDirectMessages({
    required String peerId,
    Object? cursor,
    int limit = 10,
  }) async {
    final chatId = _chatIdForPeer(peerId);
    Query<Map<String, dynamic>> query = _db
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);

    if (cursor is QueryDocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final items = _mapMessages(snapshot.docs).reversed.toList();
    final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    final hasMore = snapshot.docs.length == limit;

    return PagedResult<ChatMessage>(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<void> sendPartyMessage({
    required String partyId,
    required String message,
  }) async {
    final uid = _requireUserId();
    final senderName = await _resolveDisplayName(uid);

    await _db
        .collection('parties')
        .doc(partyId)
        .collection('messages')
        .add(<String, dynamic>{
          'senderId': uid,
          'senderName': senderName,
          'text': message,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> sendDirectMessage({
    required String peerId,
    required String message,
  }) async {
    final uid = _requireUserId();
    final senderName = await _resolveDisplayName(uid);
    final chatId = _chatIdForPeer(peerId);

    final chatRef = _db.collection('direct_chats').doc(chatId);
    await chatRef.set(<String, dynamic>{
      'participants': <String>[uid, peerId]..sort(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add(<String, dynamic>{
      'senderId': uid,
      'senderName': senderName,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markDirectChatRead({required String peerId}) async {
    final uid = _requireUserId();
    final chatId = _chatIdForPeer(peerId);
    await _db.collection('direct_chats').doc(chatId).set(
      <String, dynamic>{
        'unreadCounts.$uid': 0,
        'lastReadAt.$uid': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  List<ChatMessage> _mapMessages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final uid = _auth.currentUser?.uid;
    return docs.map((doc) {
      final data = doc.data();
      final createdAt = data['createdAt'];
      final senderId = data['senderId'] as String?;
      return ChatMessage(
        id: doc.id,
        senderName: (data['senderName'] as String?) ?? 'Player',
        message: (data['text'] as String?) ?? '',
        isMe: senderId != null && senderId == uid,
        timestamp:
            createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      );
    }).toList();
  }

  String _chatIdForPeer(String peerId) {
    final uid = _requireUserId();
    final sorted = <String>[uid, peerId]..sort();
    return '${sorted.first}_${sorted.last}';
  }

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Authentication required.');
    }
    return uid;
  }

  Future<String> _resolveDisplayName(String uid) async {
    final user = _auth.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    final snapshot = await _db.collection('users').doc(uid).get();
    final data = snapshot.data();
    final name = data == null ? null : data['displayName'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    return 'QueuePlayer';
  }

  Future<List<ChatThread>> _mapThreads(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) {
      return const <ChatThread>[];
    }
    final uid = _auth.currentUser?.uid;

    final futures = docs.map((doc) async {
      final data = doc.data();
      final participants = (data['participants'] as List?)
              ?.whereType<String>()
              .toList() ??
          const <String>[];
      final peerId = participants.firstWhere(
        (id) => uid == null || id != uid,
        orElse: () => '',
      );
      final lastMessage = (data['lastMessage'] as String?) ?? '';
      final rawTime = data['lastMessageAt'] ?? data['createdAt'];
      final lastMessageAt =
          rawTime is Timestamp ? rawTime.toDate() : DateTime.now();
      int unreadCount = 0;
      final unreadMap = data['unreadCounts'];
      if (uid != null && unreadMap is Map) {
        final rawUnread = unreadMap[uid];
        if (rawUnread is int) {
          unreadCount = rawUnread;
        } else if (rawUnread is num) {
          unreadCount = rawUnread.toInt();
        }
      }

      final profile = await _resolvePeerProfile(peerId);

      return ChatThread(
        id: doc.id,
        peerId: peerId,
        peerName: profile.name,
        peerAvatarUrl: profile.avatarUrl,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
      );
    }).toList();

    return Future.wait(futures);
  }

  Future<_PeerProfile> _resolvePeerProfile(String peerId) async {
    if (peerId.isEmpty) {
      return const _PeerProfile(
        name: 'Player',
        avatarUrl: AppImages.avatarHost,
      );
    }
    final snapshot = await _db.collection('users').doc(peerId).get();
    final data = snapshot.data();
    final name = (data?['displayName'] as String?)?.trim();
    final avatarUrl = (data?['avatarUrl'] as String?)?.trim();
    return _PeerProfile(
      name: (name == null || name.isEmpty) ? 'Player' : name,
      avatarUrl: (avatarUrl == null || avatarUrl.isEmpty)
          ? AppImages.avatarHost
          : avatarUrl,
    );
  }
}

class _PeerProfile {
  const _PeerProfile({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;
}
