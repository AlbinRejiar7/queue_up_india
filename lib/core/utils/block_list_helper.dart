import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/chat/utils/direct_chat_firebase_debug.dart';

class BlockListHelper {
  const BlockListHelper._();

  static const Duration _cacheTtl = Duration(seconds: 45);
  static final Map<String, _BlockedIdsCacheEntry> _cache =
      <String, _BlockedIdsCacheEntry>{};

  static Future<Set<String>> fetchBlockedUserIds({
    required FirebaseFirestore firestore,
    required String uid,
    String? debugLabel,
  }) async {
    final cached = _cache[uid];
    if (cached != null && !cached.isExpired) {
      if (debugLabel != null) {
        DirectChatFirebaseDebug.info(
          debugLabel,
          'block-list cache hit uid=$uid blocked=${cached.ids.length}',
        );
      }
      return cached.ids;
    }
    final snapshot = await _blocksDoc(firestore, uid).get();
    final ids = extractBlockedUserIds(snapshot.data());
    _cache[uid] = _BlockedIdsCacheEntry(ids);
    if (debugLabel != null) {
      DirectChatFirebaseDebug.read(
        source: debugLabel,
        count: snapshot.exists ? 1 : 0,
        detail: 'block-list doc fetch uid=$uid blocked=${ids.length}',
      );
    }
    return ids;
  }

  static Stream<Set<String>> watchBlockedUserIds({
    required FirebaseFirestore firestore,
    required String uid,
    String? debugLabel,
  }) {
    return _blocksDoc(firestore, uid).snapshots().map((snapshot) {
      final ids = extractBlockedUserIds(snapshot.data());
      _cache[uid] = _BlockedIdsCacheEntry(ids);
      if (debugLabel != null) {
        final readCount = snapshot.metadata.isFromCache
            ? 0
            : (snapshot.exists ? 1 : 0);
        DirectChatFirebaseDebug.read(
          source: debugLabel,
          count: readCount,
          detail:
              'block-list stream exists=${snapshot.exists} blocked=${ids.length}',
        );
      }
      return ids;
    });
  }

  static Stream<T> combineWithBlockedIds<S, T>({
    required FirebaseFirestore firestore,
    required String uid,
    required Stream<S> source,
    required FutureOr<T> Function(S value, Set<String> blockedUserIds) builder,
    String? debugLabel,
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
        blocksSubscription =
            watchBlockedUserIds(
              firestore: firestore,
              uid: uid,
              debugLabel: debugLabel,
            ).listen((ids) {
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

class _BlockedIdsCacheEntry {
  _BlockedIdsCacheEntry(Set<String> ids)
    : ids = Set<String>.unmodifiable(ids),
      cachedAt = DateTime.now();

  final Set<String> ids;
  final DateTime cachedAt;

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > BlockListHelper._cacheTtl;
}
