import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class BlockListHelper {
  const BlockListHelper._();

  static Future<Set<String>> fetchBlockedUserIds({
    required FirebaseFirestore firestore,
    required String uid,
  }) async {
    final snapshot = await _blocksDoc(firestore, uid).get();
    return extractBlockedUserIds(snapshot.data());
  }

  static Stream<Set<String>> watchBlockedUserIds({
    required FirebaseFirestore firestore,
    required String uid,
  }) {
    return _blocksDoc(
      firestore,
      uid,
    ).snapshots().map((snapshot) => extractBlockedUserIds(snapshot.data()));
  }

  static Stream<T> combineWithBlockedIds<S, T>({
    required FirebaseFirestore firestore,
    required String uid,
    required Stream<S> source,
    required FutureOr<T> Function(S value, Set<String> blockedUserIds) builder,
  }) {
    late final StreamController<T> controller;
    StreamSubscription<S>? sourceSubscription;
    StreamSubscription<Set<String>>? blocksSubscription;
    Set<String> blockedUserIds = <String>{};
    S? latestValue;
    int version = 0;

    Future<void> emitLatest() async {
      final value = latestValue;
      if (value == null || controller.isClosed) {
        return;
      }
      final currentVersion = ++version;
      final built = await builder(value, blockedUserIds);
      if (!controller.isClosed && currentVersion == version) {
        controller.add(built);
      }
    }

    controller = StreamController<T>(
      onListen: () {
        blocksSubscription = watchBlockedUserIds(firestore: firestore, uid: uid)
            .listen((ids) {
              blockedUserIds = ids;
              emitLatest();
            }, onError: controller.addError);

        sourceSubscription = source.listen((value) {
          latestValue = value;
          emitLatest();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await sourceSubscription?.cancel();
        await blocksSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  static Set<String> extractBlockedUserIds(Map<String, dynamic>? data) {
    return ((data?['blockedUserIds'] as List?) ?? const <dynamic>[])
        .whereType<String>()
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  static DocumentReference<Map<String, dynamic>> _blocksDoc(
    FirebaseFirestore firestore,
    String uid,
  ) {
    return firestore
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('blocks');
  }
}
