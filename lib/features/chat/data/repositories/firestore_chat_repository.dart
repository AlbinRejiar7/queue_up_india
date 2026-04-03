import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_message.dart';
import '../../models/chat_thread.dart';
import '../local/direct_chat_cache_store.dart';
import '../../utils/direct_chat_firebase_debug.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/utils/block_list_helper.dart';
import 'chat_repository.dart';
import '../../../../core/utils/paged_result.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required DirectChatCacheStore directChatCacheStore,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _directChatCacheStore = directChatCacheStore;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final DirectChatCacheStore _directChatCacheStore;
  final Map<String, _PeerProfile> _peerProfileCache = <String, _PeerProfile>{};

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
          final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
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
  }) async* {
    final uid = _requireUserId();
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: uid,
      debugLabel: 'watchLatestDirectMessages.blockList',
    );
    if (blockedUserIds.contains(peerId)) {
      yield const PagedResult<ChatMessage>(
        items: <ChatMessage>[],
        hasMore: false,
        nextCursor: null,
      );
      return;
    }
    final chatId = _chatIdForPeer(peerId);
    final cachedMessages = _directChatCacheStore.loadMessages(
      userId: uid,
      chatId: chatId,
    );
    DirectChatFirebaseDebug.info(
      'watchLatestDirectMessages.cache',
      'chatId=$chatId cached=${cachedMessages.length}',
    );
    if (cachedMessages.isNotEmpty) {
      final latestCachedItems = cachedMessages.length > limit
          ? cachedMessages.sublist(cachedMessages.length - limit)
          : cachedMessages;
      yield PagedResult<ChatMessage>(
        items: latestCachedItems,
        hasMore: true,
        nextCursor: _cursorForMessage(latestCachedItems.first),
      );

      final newestCursor = _directChatCacheStore.newestCursor(
        userId: uid,
        chatId: chatId,
      );
      final source = _newDirectMessagesQuery(chatId, newestCursor).snapshots();
      final stream =
          BlockListHelper.combineWithBlockedIds<
            QuerySnapshot<Map<String, dynamic>>,
            PagedResult<ChatMessage>
          >(
            firestore: _db,
            uid: uid,
            debugLabel: 'watchLatestDirectMessages.newOnly.blockList',
            source: source,
            builder: (snapshot, blockedUserIds) async {
              final estimatedReads = snapshot.metadata.isFromCache
                  ? 0
                  : snapshot.docChanges.isEmpty
                  ? snapshot.docs.length
                  : snapshot.docChanges
                        .where(
                          (change) => change.type != DocumentChangeType.removed,
                        )
                        .length;
              DirectChatFirebaseDebug.read(
                source: 'watchLatestDirectMessages.newOnly',
                count: estimatedReads,
                detail:
                    'chatId=$chatId docs=${snapshot.docs.length} changes=${snapshot.docChanges.length}',
              );
              if (blockedUserIds.contains(peerId)) {
                return const PagedResult<ChatMessage>(
                  items: <ChatMessage>[],
                  hasMore: false,
                  nextCursor: null,
                );
              }
              final items = _mapMessages(snapshot.docs);
              await _directChatCacheStore.mergeMessages(
                userId: uid,
                chatId: chatId,
                messages: items,
              );
              return PagedResult<ChatMessage>(
                items: items,
                hasMore: true,
                nextCursor: null,
              );
            },
          );

      await for (final page in stream) {
        if (page.items.isEmpty) {
          continue;
        }
        yield page;
      }
      return;
    }

    final source = _db
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots();
    final stream =
        BlockListHelper.combineWithBlockedIds<
          QuerySnapshot<Map<String, dynamic>>,
          PagedResult<ChatMessage>
        >(
          firestore: _db,
          uid: uid,
          debugLabel: 'watchLatestDirectMessages.initial.blockList',
          source: source,
          builder: (snapshot, blockedUserIds) async {
            final estimatedReads = snapshot.metadata.isFromCache
                ? 0
                : snapshot.docChanges.isEmpty
                ? snapshot.docs.length
                : snapshot.docChanges
                      .where(
                        (change) => change.type != DocumentChangeType.removed,
                      )
                      .length;
            DirectChatFirebaseDebug.read(
              source: 'watchLatestDirectMessages.initial',
              count: estimatedReads,
              detail:
                  'chatId=$chatId docs=${snapshot.docs.length} changes=${snapshot.docChanges.length}',
            );
            if (blockedUserIds.contains(peerId)) {
              return const PagedResult<ChatMessage>(
                items: <ChatMessage>[],
                hasMore: false,
                nextCursor: null,
              );
            }
            final items = _mapMessages(snapshot.docs).reversed.toList();
            await _directChatCacheStore.mergeMessages(
              userId: uid,
              chatId: chatId,
              messages: items,
            );
            final nextCursor = snapshot.docs.isEmpty
                ? null
                : _cursorForDocument(snapshot.docs.last);
            final hasMore = snapshot.docs.length == limit;
            return PagedResult<ChatMessage>(
              items: items,
              hasMore: hasMore,
              nextCursor: nextCursor,
            );
          },
        );
    yield* stream;
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

    return BlockListHelper.combineWithBlockedIds<
      QuerySnapshot<Map<String, dynamic>>,
      PagedResult<ChatThread>
    >(
      firestore: _db,
      uid: uid,
      debugLabel: 'watchDirectThreadsPage.blockList',
      source: query.snapshots(),
      builder: (snapshot, blockedUserIds) async {
        final estimatedReads = snapshot.metadata.isFromCache
            ? 0
            : snapshot.docChanges.isEmpty
            ? snapshot.docs.length
            : snapshot.docChanges
                  .where((change) => change.type != DocumentChangeType.removed)
                  .length;
        DirectChatFirebaseDebug.read(
          source: 'watchDirectThreadsPage.snapshot',
          count: estimatedReads,
          detail:
              'docs=${snapshot.docs.length} changes=${snapshot.docChanges.length}',
        );
        final threads = await _mapThreads(snapshot.docs);
        final visibleThreads = threads
            .where((thread) => !blockedUserIds.contains(thread.peerId))
            .toList();
        final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
        final hasMore = snapshot.docs.length == limit;
        return PagedResult<ChatThread>(
          items: visibleThreads,
          hasMore: hasMore,
          nextCursor: nextCursor,
        );
      },
    );
  }

  @override
  Stream<bool> watchHasUnreadDirectThreads({int limit = 20}) {
    final uid = _requireUserId();
    return _db
        .collection('direct_chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final estimatedReads = snapshot.metadata.isFromCache
              ? 0
              : snapshot.docChanges.isEmpty
              ? snapshot.docs.length
              : snapshot.docChanges
                    .where(
                      (change) => change.type != DocumentChangeType.removed,
                    )
                    .length;
          DirectChatFirebaseDebug.read(
            source: 'watchHasUnreadDirectThreads',
            count: estimatedReads,
            detail:
                'docs=${snapshot.docs.length} changes=${snapshot.docChanges.length}',
          );
          for (final doc in snapshot.docs) {
            final unreadMap = doc.data()['unreadCounts'];
            if (unreadMap is Map) {
              final rawUnread = unreadMap[uid];
              final unreadCount = rawUnread is num ? rawUnread.toInt() : 0;
              if (unreadCount > 0) {
                return true;
              }
            }
          }
          return false;
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
    DirectChatFirebaseDebug.read(
      source: 'fetchDirectThreadsPage.query',
      count: snapshot.docs.length,
      detail: 'docs=${snapshot.docs.length} limit=$limit',
    );
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: uid,
      debugLabel: 'fetchDirectThreadsPage.blockList',
    );
    final threads = await _mapThreads(snapshot.docs);
    final visibleThreads = threads
        .where((thread) => !blockedUserIds.contains(thread.peerId))
        .toList();
    final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    final hasMore = snapshot.docs.length == limit;

    return PagedResult<ChatThread>(
      items: visibleThreads,
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
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: uid,
      debugLabel: 'hasDirectChat.blockList',
    );
    if (blockedUserIds.contains(peerId)) {
      return false;
    }
    final chatId = _chatIdForPeer(peerId);
    final snapshot = await _db.collection('direct_chats').doc(chatId).get();
    DirectChatFirebaseDebug.read(
      source: 'hasDirectChat.doc',
      count: snapshot.exists ? 1 : 0,
      detail: 'chatId=$chatId exists=${snapshot.exists}',
    );
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
    final uid = _requireUserId();
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: uid,
      debugLabel: 'fetchOlderDirectMessages.blockList',
    );
    if (blockedUserIds.contains(peerId)) {
      return const PagedResult<ChatMessage>(
        items: <ChatMessage>[],
        hasMore: false,
        nextCursor: null,
      );
    }
    final chatId = _chatIdForPeer(peerId);
    Query<Map<String, dynamic>> query = _db
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);

    if (cursor is ChatMessageCursor) {
      query = query.startAfter(<Object>[
        Timestamp.fromDate(cursor.timestamp),
        cursor.messageId,
      ]);
    } else if (cursor is QueryDocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    DirectChatFirebaseDebug.read(
      source: 'fetchOlderDirectMessages.query',
      count: snapshot.docs.length,
      detail: 'chatId=$chatId docs=${snapshot.docs.length} limit=$limit',
    );
    final items = _mapMessages(snapshot.docs).reversed.toList();
    await _directChatCacheStore.mergeMessages(
      userId: uid,
      chatId: chatId,
      messages: items,
    );
    final hasMore = snapshot.docs.length == limit;

    return PagedResult<ChatMessage>(
      items: items,
      hasMore: hasMore,
      nextCursor: snapshot.docs.isEmpty
          ? null
          : _cursorForDocument(snapshot.docs.last),
    );
  }

  @override
  Future<void> sendPartyMessage({
    required String partyId,
    required String message,
    String? partyName,
  }) async {
    final uid = _requireUserId();
    final senderName = await _resolveDisplayName(uid);
    final createdAt = Timestamp.now();

    await _db
        .collection('parties')
        .doc(partyId)
        .collection('messages')
        .add(<String, dynamic>{
          'senderId': uid,
          'senderName': senderName,
          if (partyName != null && partyName.trim().isNotEmpty)
            'partyName': partyName.trim(),
          'text': message,
          'createdAt': createdAt,
          'serverCreatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> sendDirectMessage({
    required String peerId,
    required String message,
  }) async {
    final uid = _requireUserId();
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: uid,
      debugLabel: 'sendDirectMessage.blockList',
    );
    if (blockedUserIds.contains(peerId)) {
      throw StateError('Blocked user');
    }
    final senderProfile = await _resolvePeerProfile(uid);
    final chatId = _chatIdForPeer(peerId);

    final chatRef = _db.collection('direct_chats').doc(chatId);
    final participants = <String>[uid, peerId]..sort();
    final messageRef = chatRef.collection('messages').doc();
    final batch = _db.batch();
    batch.set(chatRef, <String, dynamic>{
      'participants': participants,
      'lastMessage': message,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': uid,
      'unreadCounts': <String, dynamic>{
        uid: 0,
        peerId: FieldValue.increment(1),
      },
      'lastReadAt': <String, dynamic>{uid: FieldValue.serverTimestamp()},
      'participantProfiles': <String, dynamic>{
        uid: <String, dynamic>{
          'displayName': senderProfile.name,
          'avatarUrl': senderProfile.avatarUrl,
        },
      },
    }, SetOptions(merge: true));
    batch.set(messageRef, <String, dynamic>{
      'senderId': uid,
      'senderName': senderProfile.name,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
      'clientSynced': true,
    });
    await batch.commit();
    DirectChatFirebaseDebug.write(
      source: 'sendDirectMessage.batch',
      count: 2,
      detail: 'chatId=$chatId peerId=$peerId',
    );
  }

  @override
  Future<int> getDirectChatUnreadCount({required String peerId}) async {
    final uid = _requireUserId();
    final chatId = _chatIdForPeer(peerId);
    final snapshot = await _db.collection('direct_chats').doc(chatId).get();
    DirectChatFirebaseDebug.read(
      source: 'getDirectChatUnreadCount.doc',
      count: snapshot.exists ? 1 : 0,
      detail: 'chatId=$chatId exists=${snapshot.exists}',
    );
    if (!snapshot.exists) {
      return 0;
    }
    final data = snapshot.data();
    final unreadMap = data?['unreadCounts'];
    if (unreadMap is! Map) {
      return 0;
    }
    final rawUnread = unreadMap[uid];
    return rawUnread is num ? rawUnread.toInt() : 0;
  }

  @override
  Future<void> markDirectChatRead({required String peerId}) async {
    final uid = _requireUserId();
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: uid,
      debugLabel: 'markDirectChatRead.blockList',
    );
    if (blockedUserIds.contains(peerId)) {
      return;
    }
    final chatId = _chatIdForPeer(peerId);
    await _db.collection('direct_chats').doc(chatId).set(<String, dynamic>{
      'unreadCounts': <String, dynamic>{uid: 0},
      'lastReadAt': <String, dynamic>{uid: FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
    DirectChatFirebaseDebug.write(
      source: 'markDirectChatRead',
      count: 1,
      detail: 'chatId=$chatId',
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
        timestamp: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      );
    }).toList();
  }

  Query<Map<String, dynamic>> _newDirectMessagesQuery(
    String chatId,
    ChatMessageCursor? cursor,
  ) {
    Query<Map<String, dynamic>> query = _db
        .collection('direct_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .orderBy(FieldPath.documentId);
    if (cursor != null) {
      query = query.startAfter(<Object>[
        Timestamp.fromDate(cursor.timestamp),
        cursor.messageId,
      ]);
    }
    return query.limit(50);
  }

  ChatMessageCursor _cursorForMessage(ChatMessage message) {
    return ChatMessageCursor(
      messageId: message.id,
      timestamp: message.timestamp,
    );
  }

  ChatMessageCursor _cursorForDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final createdAt = doc.data()['createdAt'];
    return ChatMessageCursor(
      messageId: doc.id,
      timestamp: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
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
    final profile = await _resolvePeerProfile(uid);
    return profile.name;
  }

  Future<_PeerProfile> _resolvePeerProfile(String uid) async {
    final cached = _peerProfileCache[uid];
    if (cached != null) {
      DirectChatFirebaseDebug.info('_resolvePeerProfile', 'cache hit uid=$uid');
      return cached;
    }

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      final authName = currentUser.displayName?.trim();
      final authAvatar = currentUser.photoURL?.trim();
      if (authName != null &&
          authName.isNotEmpty &&
          authAvatar != null &&
          authAvatar.isNotEmpty) {
        final profile = _PeerProfile(name: authName, avatarUrl: authAvatar);
        _peerProfileCache[uid] = profile;
        return profile;
      }
    }

    final snapshot = await _db.collection('users').doc(uid).get();
    DirectChatFirebaseDebug.read(
      source: '_resolvePeerProfile.userDoc',
      count: snapshot.exists ? 1 : 0,
      detail: 'uid=$uid exists=${snapshot.exists}',
    );
    final data = snapshot.data();
    final displayName = (data?['displayName'] as String?)?.trim();
    final avatarUrl = (data?['avatarUrl'] as String?)?.trim();
    final fallbackCurrentUser = _auth.currentUser;
    final fallbackName = fallbackCurrentUser?.uid == uid
        ? (fallbackCurrentUser?.displayName?.trim() ?? '')
        : '';
    final fallbackAvatar = fallbackCurrentUser?.uid == uid
        ? (fallbackCurrentUser?.photoURL?.trim() ?? '')
        : '';
    final profile = _PeerProfile(
      name: (displayName == null || displayName.isEmpty)
          ? (fallbackName.isEmpty ? 'QueuePlayer' : fallbackName)
          : displayName,
      avatarUrl: (avatarUrl == null || avatarUrl.isEmpty)
          ? (fallbackAvatar.isEmpty ? AppImages.avatarHost : fallbackAvatar)
          : avatarUrl,
    );
    _peerProfileCache[uid] = profile;
    return profile;
  }

  Future<List<ChatThread>> _mapThreads(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) {
      return const <ChatThread>[];
    }
    final uid = _auth.currentUser?.uid;
    final missingPeerIds = <String>{};
    for (final doc in docs) {
      final participants =
          (doc.data()['participants'] as List?)?.whereType<String>().toList() ??
          const <String>[];
      final peerId = participants.firstWhere(
        (id) => uid == null || id != uid,
        orElse: () => '',
      );
      if (peerId.isEmpty) {
        continue;
      }
      final rawParticipantProfiles = doc.data()['participantProfiles'];
      final participantProfiles = rawParticipantProfiles is Map
          ? rawParticipantProfiles
          : const <String, dynamic>{};
      final rawPeerProfile = participantProfiles[peerId];
      final inlineName = rawPeerProfile is Map
          ? (rawPeerProfile['displayName'] as String?)?.trim()
          : null;
      if (inlineName == null || inlineName.isEmpty) {
        missingPeerIds.add(peerId);
      }
    }
    final peerProfiles = await _resolvePeerProfiles(missingPeerIds);

    final futures = docs.map((doc) async {
      final data = doc.data();
      final participants =
          (data['participants'] as List?)?.whereType<String>().toList() ??
          const <String>[];
      final peerId = participants.firstWhere(
        (id) => uid == null || id != uid,
        orElse: () => '',
      );
      final lastMessage = (data['lastMessage'] as String?) ?? '';
      final rawTime = data['lastMessageAt'] ?? data['createdAt'];
      final lastMessageAt = rawTime is Timestamp
          ? rawTime.toDate()
          : DateTime.now();
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

      final rawParticipantProfiles = data['participantProfiles'];
      final participantProfiles = rawParticipantProfiles is Map
          ? rawParticipantProfiles
          : const <String, dynamic>{};
      final rawPeerProfile = participantProfiles[peerId];
      final inlineName = rawPeerProfile is Map
          ? (rawPeerProfile['displayName'] as String?)?.trim()
          : null;
      final inlineAvatar = rawPeerProfile is Map
          ? (rawPeerProfile['avatarUrl'] as String?)?.trim()
          : null;
      final profile = (inlineName != null && inlineName.isNotEmpty)
          ? _PeerProfile(
              name: inlineName,
              avatarUrl: (inlineAvatar == null || inlineAvatar.isEmpty)
                  ? AppImages.avatarHost
                  : inlineAvatar,
            )
          : peerProfiles[peerId] ??
                const _PeerProfile(
                  name: 'Player',
                  avatarUrl: AppImages.avatarHost,
                );

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

  Future<Map<String, _PeerProfile>> _resolvePeerProfiles(
    Set<String> peerIds,
  ) async {
    if (peerIds.isEmpty) {
      return const <String, _PeerProfile>{};
    }

    final resolved = <String, _PeerProfile>{};
    final missingIds = <String>[];

    for (final peerId in peerIds) {
      final cached = _peerProfileCache[peerId];
      if (cached != null) {
        resolved[peerId] = cached;
      } else {
        missingIds.add(peerId);
      }
    }

    for (var index = 0; index < missingIds.length; index += 10) {
      final end = (index + 10) > missingIds.length
          ? missingIds.length
          : index + 10;
      final chunk = missingIds.sublist(index, end);
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      DirectChatFirebaseDebug.read(
        source: '_resolvePeerProfiles.batch',
        count: snapshot.docs.length,
        detail: 'requested=${chunk.length} returned=${snapshot.docs.length}',
      );

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['displayName'] as String?)?.trim();
        final avatarUrl = (data['avatarUrl'] as String?)?.trim();
        final profile = _PeerProfile(
          name: (name == null || name.isEmpty) ? 'Player' : name,
          avatarUrl: (avatarUrl == null || avatarUrl.isEmpty)
              ? AppImages.avatarHost
              : avatarUrl,
        );
        _peerProfileCache[doc.id] = profile;
        resolved[doc.id] = profile;
      }
    }

    for (final peerId in peerIds) {
      resolved.putIfAbsent(
        peerId,
        () =>
            const _PeerProfile(name: 'Player', avatarUrl: AppImages.avatarHost),
      );
    }

    return resolved;
  }
}

class _PeerProfile {
  const _PeerProfile({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;
}
