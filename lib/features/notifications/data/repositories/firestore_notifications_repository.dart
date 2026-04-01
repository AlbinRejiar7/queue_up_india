import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_images.dart';
import '../../../../core/utils/block_list_helper.dart';
import '../../models/notification_item.dart';
import 'notifications_repository.dart';

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  static const int _defaultLimit = 50;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Stream<List<NotificationItem>> watchNotifications() {
    final uid = _requireUserId();
    final source = _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(_defaultLimit)
        .snapshots();
    return BlockListHelper.combineWithBlockedIds<
      QuerySnapshot<Map<String, dynamic>>,
      List<NotificationItem>
    >(
      firestore: _db,
      uid: uid,
      source: source,
      builder: (snapshot, blockedUserIds) {
        return snapshot.docs
            .map((doc) {
              final data = doc.data();
              final createdAt = data['createdAt'];
              final readAt = data['readAt'];
              return NotificationItem(
                id: doc.id,
                title: (data['title'] as String?) ?? 'Notification',
                body: (data['body'] as String?) ?? '',
                type: data['type'] as String?,
                status: data['status'] as String?,
                fromUserId: data['fromUserId'] as String?,
                fromUserName: data['fromUserName'] as String?,
                fromUserAvatar: data['fromUserAvatar'] as String?,
                gameId: data['gameId'] as String?,
                rank: data['rankId'] as String?,
                language: data['languageId'] as String?,
                createdAt: createdAt is Timestamp
                    ? createdAt.toDate()
                    : DateTime.now(),
                readAt: readAt is Timestamp ? readAt.toDate() : null,
              );
            })
            .where(
              (notification) =>
                  notification.fromUserId == null ||
                  !blockedUserIds.contains(notification.fromUserId),
            )
            .toList();
      },
    );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final uid = _requireUserId();
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .set(<String, dynamic>{
          'readAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  Future<void> markAllAsRead() async {
    final uid = _requireUserId();
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('readAt', isNull: true)
        .get();
    if (snapshot.docs.isEmpty) {
      return;
    }
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, <String, dynamic>{
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    final uid = _requireUserId();
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  @override
  Future<void> clearNotifications() async {
    final uid = _requireUserId();
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();
    if (snapshot.docs.isEmpty) {
      return;
    }
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> sendChatRequest({
    required String targetUserId,
    required String gameId,
    required String rank,
    required String language,
    required String title,
    required String body,
  }) async {
    await _ensurePeerNotBlocked(targetUserId);
    final fromUserId = _requireUserId();
    final senderName = await _resolveDisplayName(fromUserId);
    final senderAvatar = await _resolveAvatarUrl(fromUserId);

    await _db
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .add(<String, dynamic>{
          'type': NotificationItem.typeChatRequest,
          'status': NotificationItem.statusPending,
          'title': title,
          'body': body,
          'fromUserId': fromUserId,
          'fromUserName': senderName,
          'fromUserAvatar': senderAvatar,
          'gameId': gameId,
          'rankId': rank,
          'languageId': language,
          'createdAt': FieldValue.serverTimestamp(),
          'readAt': null,
        });
  }

  @override
  Future<bool> hasPendingChatRequest({
    required String targetUserId,
    required String fromUserId,
  }) async {
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: _requireUserId(),
    );
    if (blockedUserIds.contains(targetUserId)) {
      return false;
    }
    final snapshot = await _db
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .where('type', isEqualTo: NotificationItem.typeChatRequest)
        .where('status', isEqualTo: NotificationItem.statusPending)
        .where('fromUserId', isEqualTo: fromUserId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<bool> hasIncomingChatRequest({
    required String targetUserId,
    required String fromUserId,
  }) async {
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: _requireUserId(),
    );
    if (blockedUserIds.contains(targetUserId)) {
      return false;
    }
    final snapshot = await _db
        .collection('users')
        .doc(fromUserId)
        .collection('notifications')
        .where('type', isEqualTo: NotificationItem.typeChatRequest)
        .where('status', isEqualTo: NotificationItem.statusPending)
        .where('fromUserId', isEqualTo: targetUserId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> sendChatRequestResponse({
    required String targetUserId,
    required String status,
    required String title,
    required String body,
    String? gameId,
    String? rank,
    String? language,
  }) async {
    await _ensurePeerNotBlocked(targetUserId);
    final fromUserId = _requireUserId();
    final senderName = await _resolveDisplayName(fromUserId);
    final senderAvatar = await _resolveAvatarUrl(fromUserId);

    await _db
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .add(<String, dynamic>{
          'type': NotificationItem.typeChatRequestResponse,
          'status': status,
          'title': title,
          'body': body,
          'fromUserId': fromUserId,
          'fromUserName': senderName,
          'fromUserAvatar': senderAvatar,
          'gameId': gameId,
          'rankId': rank,
          'languageId': language,
          'createdAt': FieldValue.serverTimestamp(),
          'readAt': null,
        });
  }

  @override
  Future<void> updateNotificationStatus({
    required String notificationId,
    required String status,
  }) async {
    final uid = _requireUserId();
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .set(<String, dynamic>{
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  String _requireUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Authentication required.');
    }
    return uid;
  }

  Future<void> _ensurePeerNotBlocked(String peerId) async {
    final blockedUserIds = await BlockListHelper.fetchBlockedUserIds(
      firestore: _db,
      uid: _requireUserId(),
    );
    if (blockedUserIds.contains(peerId)) {
      throw StateError('Blocked user');
    }
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
