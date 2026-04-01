import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_timeouts.dart';
import '../../../../core/utils/block_list_helper.dart';
import '../../models/available_player_model.dart';
import 'availability_repository.dart';
import '../../../../core/utils/paged_result.dart';

class FirestoreAvailabilityRepository implements AvailabilityRepository {
  FirestoreAvailabilityRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<void> setAvailability({
    required bool isAvailable,
    required String gameId,
    required String rank,
    required String language,
    bool startedNow = false,
  }) async {
    final uid = _requireUserId();
    final docRef = _db.collection('availability').doc(uid);

    if (!isAvailable) {
      await docRef.delete();
      return;
    }

    final displayName = await _resolveDisplayName(uid);
    final avatarUrl = await _resolveAvatarUrl(uid);

    final payload = <String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'gameId': gameId,
      'rankId': rank,
      'languageId': language,
      'isAvailable': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (startedNow) {
      payload['availableSince'] = FieldValue.serverTimestamp();
    }

    await docRef.set(payload, SetOptions(merge: true));
  }

  @override
  Stream<List<AvailablePlayerModel>> watchAvailablePlayers() {
    final uid = _requireUserId();
    final source = _db
        .collection('availability')
        .where('isAvailable', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots();
    return BlockListHelper.combineWithBlockedIds<
      QuerySnapshot<Map<String, dynamic>>,
      List<AvailablePlayerModel>
    >(
      firestore: _db,
      uid: uid,
      source: source,
      builder: (snapshot, blockedUserIds) {
        final now = DateTime.now();
        return snapshot.docs
            .map((doc) => _mapAvailablePlayer(doc.id, doc.data()))
            .where((player) => player.isFresh(now))
            .where((player) => !blockedUserIds.contains(player.id))
            .toList();
      },
    );
  }

  @override
  Stream<PagedResult<AvailablePlayerModel>> watchAvailablePlayersPage({
    String? gameId,
    String? rank,
    String? language,
    int limit = 10,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('availability')
        .where('isAvailable', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);

    if (gameId != null && gameId.isNotEmpty) {
      query = query.where('gameId', isEqualTo: gameId);
    }
    if (rank != null && rank.isNotEmpty) {
      query = query.where('rankId', isEqualTo: rank);
    }
    if (language != null && language.isNotEmpty) {
      query = query.where('languageId', isEqualTo: language);
    }

    final uid = _requireUserId();
    return BlockListHelper.combineWithBlockedIds<
      QuerySnapshot<Map<String, dynamic>>,
      PagedResult<AvailablePlayerModel>
    >(
      firestore: _db,
      uid: uid,
      source: query.snapshots(),
      builder: (snapshot, blockedUserIds) {
        final now = DateTime.now();
        final freshPlayers = snapshot.docs
            .map((doc) => _mapAvailablePlayer(doc.id, doc.data()))
            .where((player) => player.isFresh(now))
            .toList();
        final players = freshPlayers
            .where((player) => !blockedUserIds.contains(player.id))
            .toList();
        final hitStaleBoundary = freshPlayers.length != snapshot.docs.length;
        final hasMore = snapshot.docs.length == limit && !hitStaleBoundary;
        final nextCursor = hasMore && snapshot.docs.isNotEmpty
            ? snapshot.docs.last
            : null;

        return PagedResult<AvailablePlayerModel>(
          items: players,
          hasMore: hasMore,
          nextCursor: nextCursor,
        );
      },
    );
  }

  @override
  Future<AvailablePlayerModel?> fetchCurrentAvailability() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    final doc = await _db.collection('availability').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    final data = doc.data() ?? <String, dynamic>{};
    final isAvailable = data['isAvailable'] == true;
    if (!isAvailable) {
      return null;
    }
    final player = _mapAvailablePlayer(doc.id, data);
    if (!player.isFresh()) {
      await doc.reference.delete();
      return null;
    }
    return player;
  }

  @override
  Future<AvailablePlayerModel?> fetchAvailabilityById(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final currentUid = _auth.currentUser?.uid;
    if (currentUid != null) {
      final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
        firestore: _db,
        uid: currentUid,
      );
      if (blockedUserIds.contains(trimmed)) {
        return null;
      }
    }

    final doc = await _db.collection('availability').doc(trimmed).get();
    if (!doc.exists) {
      return null;
    }
    final data = doc.data() ?? <String, dynamic>{};
    final isAvailable = data['isAvailable'] == true;
    if (!isAvailable) {
      return null;
    }
    final player = _mapAvailablePlayer(doc.id, data);
    return player.isFresh() ? player : null;
  }

  @override
  Future<PagedResult<AvailablePlayerModel>> fetchAvailablePlayersPage({
    String? gameId,
    String? rank,
    String? language,
    Object? cursor,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('availability')
        .where('isAvailable', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limit);

    if (gameId != null && gameId.isNotEmpty) {
      query = query.where('gameId', isEqualTo: gameId);
    }
    if (rank != null && rank.isNotEmpty) {
      query = query.where('rankId', isEqualTo: rank);
    }
    if (language != null && language.isNotEmpty) {
      query = query.where('languageId', isEqualTo: language);
    }
    if (cursor is QueryDocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: _requireUserId(),
    );
    final now = DateTime.now();
    final freshPlayers = snapshot.docs
        .map((doc) => _mapAvailablePlayer(doc.id, doc.data()))
        .where((player) => player.isFresh(now))
        .toList();
    final players = freshPlayers
        .where((player) => !blockedUserIds.contains(player.id))
        .toList();
    final hitStaleBoundary = freshPlayers.length != snapshot.docs.length;
    final hasMore = snapshot.docs.length == limit && !hitStaleBoundary;
    final nextCursor = hasMore && snapshot.docs.isNotEmpty
        ? snapshot.docs.last
        : null;

    return PagedResult<AvailablePlayerModel>(
      items: players,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
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
    final snapshot = await _db.collection('users').doc(uid).get();
    final data = snapshot.data();
    final name = data == null ? null : data['displayName'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return 'QueuePlayer';
  }

  Future<String> _resolveAvatarUrl(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();
    final data = snapshot.data();
    final avatarUrl = data == null ? null : data['avatarUrl'] as String?;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return avatarUrl;
    }
    final user = _auth.currentUser;
    if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      return user.photoURL!;
    }
    return AppImages.avatarHost;
  }

  AvailablePlayerModel _mapAvailablePlayer(
    String id,
    Map<String, dynamic> data,
  ) {
    return AvailablePlayerModel(
      id: id,
      name: (data['displayName'] as String?) ?? 'QueuePlayer',
      avatarUrl: (data['avatarUrl'] as String?) ?? AppImages.avatarHost,
      gameId: (data['gameId'] as String?) ?? '',
      rank: (data['rankId'] as String?) ?? '',
      language: (data['languageId'] as String?) ?? '',
      availableSince: _resolveAvailableSince(data),
      updatedAt: _resolveUpdatedAt(data),
    );
  }

  DateTime _resolveAvailableSince(Map<String, dynamic> data) {
    final availableSince = data['availableSince'];
    if (availableSince is Timestamp) {
      return availableSince.toDate();
    }
    if (availableSince is DateTime) {
      return availableSince;
    }
    final updatedAt = data['updatedAt'];
    if (updatedAt is Timestamp) {
      return updatedAt.toDate();
    }
    if (updatedAt is DateTime) {
      return updatedAt;
    }
    return DateTime.now();
  }

  DateTime _resolveUpdatedAt(Map<String, dynamic> data) {
    final updatedAt = data['updatedAt'];
    if (updatedAt is Timestamp) {
      return updatedAt.toDate();
    }
    if (updatedAt is DateTime) {
      return updatedAt;
    }
    final availableSince = data['availableSince'];
    if (availableSince is Timestamp) {
      return availableSince.toDate();
    }
    if (availableSince is DateTime) {
      return availableSince;
    }
    return DateTime.now().subtract(AppTimeouts.availabilityTtl);
  }
}
