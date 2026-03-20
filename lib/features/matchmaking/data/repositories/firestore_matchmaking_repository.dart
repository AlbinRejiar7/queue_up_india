import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/solo_matchmaking_metadata_model.dart';
import '../../models/solo_matchmaking_session_model.dart';
import '../../models/solo_squad_model.dart';
import 'matchmaking_repository.dart';

class FirestoreMatchmakingRepository implements MatchmakingRepository {
  FirestoreMatchmakingRepository({
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
  Future<SoloMatchmakingSessionModel?> getCurrentSession() async {
    final uid = _requireUserId();
    final snapshot = await _sessionRef(uid).get();
    final data = snapshot.data();
    if (data == null || data.isEmpty) {
      return null;
    }
    final session = SoloMatchmakingSessionModel.fromMap(data);
    return session.isActive ? session : null;
  }

  @override
  Stream<SoloMatchmakingSessionModel?> watchCurrentSession() {
    final uid = _requireUserId();
    return _sessionRef(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null || data.isEmpty) {
        return null;
      }
      final session = SoloMatchmakingSessionModel.fromMap(data);
      return session.isActive ? session : null;
    });
  }

  @override
  Stream<SoloMatchmakingMetadataModel?> watchBucketMetadata(String bucketId) {
    return _db
        .collection('match_pool')
        .doc(bucketId)
        .collection('metadata')
        .doc('stats')
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          if (data == null || data.isEmpty) {
            return null;
          }
          return SoloMatchmakingMetadataModel.fromMap(
            bucketId: bucketId,
            data: data,
          );
        });
  }

  @override
  Stream<SoloSquadModel?> watchSquad(String squadId) {
    return _db.collection('solo_squads').doc(squadId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null || data.isEmpty) {
        return null;
      }
      return SoloSquadModel.fromMap(id: snapshot.id, data: data);
    });
  }

  @override
  Future<void> startSoloQueue({
    required String gameId,
    required String rankId,
    required String languageId,
  }) async {
    final callable = _functions.httpsCallable('startSoloMatchmaking');
    await callable.call(<String, dynamic>{
      'gameId': gameId,
      'rankId': rankId,
      'languageId': languageId,
    });
  }

  @override
  Future<void> cancelSoloQueue() async {
    final callable = _functions.httpsCallable('cancelSoloMatchmaking');
    await callable.call();
  }

  @override
  Future<void> acceptSquad({required String squadId}) async {
    final callable = _functions.httpsCallable('acceptSoloMatchmaking');
    await callable.call(<String, dynamic>{'squadId': squadId});
  }

  @override
  Future<void> rejectSquad({required String squadId}) async {
    final callable = _functions.httpsCallable('rejectSoloMatchmaking');
    await callable.call(<String, dynamic>{'squadId': squadId});
  }

  DocumentReference<Map<String, dynamic>> _sessionRef(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('solo_matchmaking');
  }

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Authentication required.');
    }
    return uid;
  }
}
