import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/chat/utils/direct_chat_firebase_debug.dart';
import 'in_app_alert_service.dart';

class DirectChatMonitorService {
  DirectChatMonitorService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const int _queryLimit = 20;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StreamController<bool> _hasUnreadController =
      StreamController<bool>.broadcast();
  final Map<String, DateTime> _lastSeenByChatId = <String, DateTime>{};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _isPrimed = false;
  bool _hasUnread = false;
  bool _alertsEnabled = false;

  Stream<bool> get hasUnreadStream => _hasUnreadController.stream;
  bool get currentHasUnread => _hasUnread;

  void start() {
    if (_subscription != null) {
      DirectChatFirebaseDebug.info(
        'DirectChatMonitorService.start',
        'already active',
      );
      return;
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _updateHasUnread(false);
      DirectChatFirebaseDebug.info(
        'DirectChatMonitorService.start',
        'skipped: no current user',
      );
      return;
    }
    DirectChatFirebaseDebug.info(
      'DirectChatMonitorService.start',
      'listen top=$_queryLimit uid=$uid',
    );

    _subscription = _firestore
        .collection('direct_chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .limit(_queryLimit)
        .snapshots()
        .listen((snapshot) => _handleSnapshot(uid, snapshot));
  }

  void setAlertsEnabled(bool enabled) {
    _alertsEnabled = enabled;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _isPrimed = false;
    _lastSeenByChatId.clear();
    _updateHasUnread(false);
    DirectChatFirebaseDebug.info(
      'DirectChatMonitorService.stop',
      'listener stopped',
    );
  }

  void _handleSnapshot(
    String uid,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final estimatedReads = snapshot.metadata.isFromCache
        ? 0
        : snapshot.docChanges.isEmpty
        ? snapshot.docs.length
        : snapshot.docChanges
              .where((change) => change.type != DocumentChangeType.removed)
              .length;
    DirectChatFirebaseDebug.read(
      source: 'DirectChatMonitorService.snapshot',
      count: estimatedReads,
      detail:
          'docs=${snapshot.docs.length} changes=${snapshot.docChanges.length} alerts=$_alertsEnabled',
    );
    final docs = snapshot.docs;
    final hasUnread = docs.any((doc) {
      final unreadMap = doc.data()['unreadCounts'];
      if (unreadMap is! Map) {
        return false;
      }
      final rawUnread = unreadMap[uid];
      final unreadCount = rawUnread is num ? rawUnread.toInt() : 0;
      return unreadCount > 0;
    });
    _updateHasUnread(hasUnread);

    if (!_isPrimed) {
      for (final doc in docs) {
        final data = doc.data();
        final rawTime = data['lastMessageAt'];
        _lastSeenByChatId[doc.id] = rawTime is Timestamp
            ? rawTime.toDate()
            : DateTime.now();
      }
      _isPrimed = true;
      return;
    }

    for (final doc in docs) {
      final data = doc.data();
      final senderId = data['lastMessageSenderId'] as String?;
      if (!_alertsEnabled || senderId == null || senderId == uid) {
        continue;
      }

      final rawTime = data['lastMessageAt'];
      final lastMessageAt = rawTime is Timestamp
          ? rawTime.toDate()
          : DateTime.now();
      final previous = _lastSeenByChatId[doc.id];
      _lastSeenByChatId[doc.id] = lastMessageAt;
      if (previous == null || lastMessageAt.isAfter(previous)) {
        InAppAlertService.notify();
      }
    }
  }

  void _updateHasUnread(bool hasUnread) {
    if (_hasUnread == hasUnread && _hasUnreadController.hasListener) {
      return;
    }
    _hasUnread = hasUnread;
    if (!_hasUnreadController.isClosed) {
      _hasUnreadController.add(hasUnread);
    }
  }
}
