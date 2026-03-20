import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/utils/paged_result.dart';
import '../../../auth/models/user_model.dart';
import '../../models/create_party_form_model.dart';
import '../../models/party_model.dart';
import '../../models/party_player_model.dart';
import 'party_repository.dart';

class FirestorePartyRepository implements PartyRepository {
  FirestorePartyRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  @override
  Future<String?> fetchCurrentPartyId() async {
    final uid = _requireUserId();
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return data == null ? null : data['currentPartyId'] as String?;
  }

  @override
  Future<List<PartyModel>> fetchParties({required String gameId}) async {
    final page = await fetchPartiesPage(gameId: gameId, limit: 50);
    return page.items;
  }

  @override
  Future<PagedResult<PartyModel>> fetchPartiesPage({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
    Object? cursor,
    int limit = 10,
  }) async {
    Query<Map<String, dynamic>> query = _basePartyQuery(
      gameId: gameId,
      rankFilter: rankFilter,
      languageFilter: languageFilter,
    ).limit(limit);

    if (cursor is QueryDocumentSnapshot<Map<String, dynamic>>) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final baseParties = snapshot.docs.map((doc) {
      final data = doc.data();
      return _mapPartyDoc(doc.id, data);
    }).toList();
    final parties = await _enrichHostNames(baseParties);

    final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    final hasMore = snapshot.docs.length == limit;

    return PagedResult<PartyModel>(
      items: parties,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Stream<PagedResult<PartyModel>> watchPartiesPage({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
    int limit = 10,
  }) {
    final query = _basePartyQuery(
      gameId: gameId,
      rankFilter: rankFilter,
      languageFilter: languageFilter,
    ).limit(limit);

    return query.snapshots().asyncMap((snapshot) async {
      final baseParties = snapshot.docs.map((doc) {
        final data = doc.data();
        return _mapPartyDoc(doc.id, data);
      }).toList();
      final parties = await _enrichHostNames(baseParties);
      final nextCursor = snapshot.docs.isEmpty ? null : snapshot.docs.last;
      final hasMore = snapshot.docs.length == limit;

      return PagedResult<PartyModel>(
        items: parties,
        hasMore: hasMore,
        nextCursor: nextCursor,
      );
    });
  }

  @override
  Future<List<PartyModel>> fetchCreatedParties() async {
    final uid = _requireUserId();
    final rooms = await _db
        .collection('users')
        .doc(uid)
        .collection('rooms')
        .where('role', isEqualTo: 'host')
        .where('status', isEqualTo: 'active')
        .get();
    return _loadPartiesFromRooms(rooms.docs);
  }

  @override
  Future<List<PartyModel>> fetchJoinedParties() async {
    final uid = _requireUserId();
    final rooms = await _db
        .collection('users')
        .doc(uid)
        .collection('rooms')
        .where('role', isEqualTo: 'member')
        .where('status', isEqualTo: 'active')
        .get();
    return _loadPartiesFromRooms(rooms.docs);
  }

  @override
  Future<PartyModel> fetchPartyDetails({required String partyId}) async {
    final partyDoc = await _db.collection('parties').doc(partyId).get();
    if (!partyDoc.exists) {
      throw StateError('Party not found');
    }

    final data = partyDoc.data() ?? <String, dynamic>{};
    final hostId = data['hostId'] as String?;
    final membersSnapshot = await _db
        .collection('parties')
        .doc(partyId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .get();

    final players = membersSnapshot.docs.map((member) {
      final memberData = member.data();
      final isHost = memberData['role'] == 'host' || member.id == hostId;
      return PartyPlayerModel(
        id: member.id,
        name: (memberData['displayName'] as String?) ?? 'QueuePlayer',
        avatarUrl:
            (memberData['avatarUrl'] as String?) ?? AppImages.avatarHost,
        status: isHost ? 'Host' : 'Ready',
        isHost: isHost,
      );
    }).toList();

    final base = _mapPartyDoc(partyDoc.id, data);
    return base.copyWith(players: players);
  }

  @override
  Stream<List<PartyPlayerModel>> watchPartyMembers({
    required String partyId,
  }) {
    return _db
        .collection('parties')
        .doc(partyId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final players = snapshot.docs.map((member) {
            final memberData = member.data();
            final isHost = memberData['role'] == 'host';
            return PartyPlayerModel(
              id: member.id,
              name: (memberData['displayName'] as String?) ?? 'QueuePlayer',
              avatarUrl:
                  (memberData['avatarUrl'] as String?) ?? AppImages.avatarHost,
              status: isHost ? 'Host' : 'Ready',
              isHost: isHost,
            );
          }).toList();

          players.sort((a, b) {
            if (a.isHost == b.isHost) {
              return a.name.compareTo(b.name);
            }
            return a.isHost ? -1 : 1;
          });
          return players;
        });
  }

  @override
  Future<PartyModel> createParty({
    required String gameId,
    required CreatePartyFormModel form,
  }) async {
    final uid = _requireUserId();
    final displayName = await _resolveDisplayName(uid);
    final avatarUrl = await _resolveAvatarUrl(uid);
    final partyRef = _db.collection('parties').doc();
    final resolvedGameId = gameId.trim().isEmpty
        ? AppOptions.valorantId
        : gameId.trim();
    final partyCode = form.partyCode.trim();
    if (partyCode.isEmpty) {
      throw StateError('Party code is required');
    }

    await _db.runTransaction((tx) async {
      tx.set(partyRef, <String, dynamic>{
        'name': form.partyName.trim(),
        'hostId': uid,
        'hostDisplayName': displayName,
        'gameId': resolvedGameId,
        'rankId': form.rank,
        'languageId': form.language,
        'maxPlayers': form.maxPlayers,
        'neededPlayers': form.maxPlayers,
        'currentPlayers': 1,
        'partyCode': partyCode,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        partyRef.collection('members').doc(uid),
        <String, dynamic>{
          'uid': uid,
          'displayName': displayName,
          'avatarUrl': avatarUrl,
          'role': 'host',
          'status': 'active',
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      tx.set(
        _db.collection('users').doc(uid).collection('rooms').doc(partyRef.id),
        <String, dynamic>{
          'partyId': partyRef.id,
          'role': 'host',
          'gameId': resolvedGameId,
          'rankId': form.rank,
          'languageId': form.language,
          'status': 'active',
          'lastMessageAt': null,
        },
        SetOptions(merge: true),
      );

      tx.set(
        _db.collection('users').doc(uid),
        <String, dynamic>{
          'currentPartyId': partyRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    return fetchPartyDetails(partyId: partyRef.id);
  }

  @override
  Future<PartyModel> joinParty({
    required String partyId,
    required UserModel user,
  }) async {
    final uid = _requireUserId();
    final resolvedName = await _resolveDisplayName(uid);
    final resolvedAvatar = await _resolveAvatarUrl(uid);
    final callable = _functions.httpsCallable('joinParty');
    await callable.call(<String, dynamic>{
      'partyId': partyId,
      'displayName': resolvedName,
      'avatarUrl': resolvedAvatar,
    });

    await _db.collection('users').doc(uid).set(
      <String, dynamic>{
        'currentPartyId': partyId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return fetchPartyDetails(partyId: partyId);
  }

  @override
  Future<PartyModel> kickPlayer({
    required String partyId,
    required String playerId,
  }) async {
    final callable = _functions.httpsCallable('kickMember');
    await callable.call(<String, dynamic>{
      'partyId': partyId,
      'memberId': playerId,
    });
    return fetchPartyDetails(partyId: partyId);
  }

  @override
  Future<void> leaveParty({required String partyId}) async {
    final uid = _requireUserId();
    final callable = _functions.httpsCallable('leaveParty');
    await callable.call(<String, dynamic>{'partyId': partyId});
    await _db.collection('users').doc(uid).set(
      <String, dynamic>{
        'currentPartyId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
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

  Future<List<PartyModel>> _loadPartiesFromRooms(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
  ) async {
    if (rooms.isEmpty) {
      return <PartyModel>[];
    }

    final futures = rooms.map((doc) async {
      final partyId = doc.data()['partyId'] as String? ?? doc.id;
      final partyDoc = await _db.collection('parties').doc(partyId).get();
      if (!partyDoc.exists) {
        return null;
      }
      return _mapPartyDoc(partyDoc.id, partyDoc.data() ?? <String, dynamic>{});
    }).toList();

    final results = await Future.wait(futures);
    return _enrichHostNames(results.whereType<PartyModel>().toList());
  }

  PartyModel _mapPartyDoc(String id, Map<String, dynamic> data) {
    final gameId = (data['gameId'] as String?) ?? AppOptions.valorantId;
    final rank = (data['rankId'] as String?) ?? 'Unranked';
    final language = (data['languageId'] as String?) ?? 'English';
    final maxPlayers = (data['maxPlayers'] as int?) ??
        (data['neededPlayers'] as int?) ??
        4;
    final currentPlayers = (data['currentPlayers'] as int?) ?? 0;
    final createdAt = data['createdAt'];

    return PartyModel(
      id: id,
      name: (data['name'] as String?) ?? 'Queue Party',
      gameId: gameId,
      rank: rank,
      language: language,
      maxPlayers: maxPlayers,
      players: _placeholderPlayers(currentPlayers),
      partyCode: (data['partyCode'] as String?) ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
      coverImageUrl: _logoForGame(gameId),
      hostId: (data['hostId'] as String?) ?? '',
      hostDisplayName: data['hostDisplayName'] as String?,
      logoImageUrl: _logoForGame(gameId),
      tags: const <String>[],
    );
  }

  Future<List<PartyModel>> _enrichHostNames(List<PartyModel> parties) async {
    final missingHostIds = parties
        .where(
          (party) =>
              (party.hostDisplayName == null ||
                  party.hostDisplayName!.trim().isEmpty) &&
              party.hostId.trim().isNotEmpty,
        )
        .map((party) => party.hostId)
        .toSet()
        .toList();

    if (missingHostIds.isEmpty) {
      return parties;
    }

    final hostNames = <String, String>{};
    for (final chunk in _chunk(missingHostIds, 10)) {
      final snapshot = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        final displayName = (doc.data()['displayName'] as String?)?.trim();
        if (displayName != null && displayName.isNotEmpty) {
          hostNames[doc.id] = displayName;
        }
      }
    }

    return parties.map((party) {
      final resolvedHostName = party.hostDisplayName?.trim().isNotEmpty == true
          ? party.hostDisplayName
          : hostNames[party.hostId];
      return party.copyWith(hostDisplayName: resolvedHostName);
    }).toList();
  }

  List<List<String>> _chunk(List<String> values, int size) {
    final chunks = <List<String>>[];
    for (var index = 0; index < values.length; index += size) {
      final end = (index + size) > values.length ? values.length : index + size;
      chunks.add(values.sublist(index, end));
    }
    return chunks;
  }

  Query<Map<String, dynamic>> _basePartyQuery({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('parties')
        .where('gameId', isEqualTo: gameId)
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true);

    final normalizedRank = rankFilter?.trim();
    final normalizedLanguage = languageFilter?.trim();

    if (normalizedRank != null && normalizedRank.isNotEmpty) {
      query = query.where('rankId', isEqualTo: normalizedRank);
    }
    if (normalizedLanguage != null && normalizedLanguage.isNotEmpty) {
      query = query.where('languageId', isEqualTo: normalizedLanguage);
    }

    return query;
  }

  List<PartyPlayerModel> _placeholderPlayers(int count) {
    if (count <= 0) {
      return const <PartyPlayerModel>[];
    }
    return List<PartyPlayerModel>.generate(
      count,
      (index) => PartyPlayerModel(
        id: 'p_$index',
        name: 'Player',
        avatarUrl: AppImages.avatarHost,
        status: 'Ready',
      ),
    );
  }

  String _logoForGame(String gameId) {
    if (gameId == AppOptions.pubgId) {
      return AppImages.pubg;
    }
    if (gameId == AppOptions.freeFireId) {
      return AppImages.freeFire;
    }
    return AppImages.valorant;
  }
}
