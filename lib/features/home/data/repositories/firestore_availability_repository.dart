import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_images.dart';
import '../../models/available_player_model.dart';
import 'availability_repository.dart';
import '../../../../core/utils/paged_result.dart';

class FirestoreAvailabilityRepository implements AvailabilityRepository {
  FirestoreAvailabilityRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Future<void> setAvailability({
    required bool isAvailable,
    required String gameId,
    required String rank,
    required String language,
  }) async {
    final uid = _requireUserId();
    final docRef = _db.collection('availability').doc(uid);

    if (!isAvailable) {
      await docRef.delete();
      return;
    }

    final displayName = await _resolveDisplayName(uid);
    final avatarUrl = await _resolveAvatarUrl(uid);

    await docRef.set(<String, dynamic>{
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'gameId': gameId,
      'rankId': rank,
      'languageId': language,
      'isAvailable': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AvailablePlayerModel>> watchAvailablePlayers() {
    return _db
        .collection('availability')
        .where('isAvailable', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return AvailablePlayerModel(
              id: doc.id,
              name: (data['displayName'] as String?) ?? 'QueuePlayer',
              avatarUrl:
                  (data['avatarUrl'] as String?) ?? AppImages.avatarHost,
              gameId: (data['gameId'] as String?) ?? '',
              rank: (data['rankId'] as String?) ?? '',
              language: (data['languageId'] as String?) ?? '',
            );
          }).toList(),
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

    return query.snapshots().map((snapshot) {
      final players = snapshot.docs.map((doc) {
        final data = doc.data();
        return AvailablePlayerModel(
          id: doc.id,
          name: (data['displayName'] as String?) ?? 'QueuePlayer',
          avatarUrl: (data['avatarUrl'] as String?) ?? AppImages.avatarHost,
          gameId: (data['gameId'] as String?) ?? '',
          rank: (data['rankId'] as String?) ?? '',
          language: (data['languageId'] as String?) ?? '',
        );
      }).toList();

      final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
      final hasMore = snapshot.docs.length == limit;

      return PagedResult<AvailablePlayerModel>(
        items: players,
        hasMore: hasMore,
        nextCursor: nextCursor,
      );
    });
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

    return AvailablePlayerModel(
      id: doc.id,
      name: (data['displayName'] as String?) ?? 'QueuePlayer',
      avatarUrl: (data['avatarUrl'] as String?) ?? AppImages.avatarHost,
      gameId: (data['gameId'] as String?) ?? '',
      rank: (data['rankId'] as String?) ?? '',
      language: (data['languageId'] as String?) ?? '',
    );
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
    final players = snapshot.docs.map((doc) {
      final data = doc.data();
      return AvailablePlayerModel(
        id: doc.id,
        name: (data['displayName'] as String?) ?? 'QueuePlayer',
        avatarUrl: (data['avatarUrl'] as String?) ?? AppImages.avatarHost,
        gameId: (data['gameId'] as String?) ?? '',
        rank: (data['rankId'] as String?) ?? '',
        language: (data['languageId'] as String?) ?? '',
      );
    }).toList();

    final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    final hasMore = snapshot.docs.length == limit;

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
}
