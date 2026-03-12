import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/notification_item.dart';
import 'notifications_repository.dart';

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  @override
  Stream<List<NotificationItem>> watchNotifications() {
    final uid = _requireUserId();
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final createdAt = data['createdAt'];
            final readAt = data['readAt'];
            return NotificationItem(
              id: doc.id,
              title: (data['title'] as String?) ?? 'Notification',
              body: (data['body'] as String?) ?? '',
              type: data['type'] as String?,
              createdAt: createdAt is Timestamp
                  ? createdAt.toDate()
                  : DateTime.now(),
              readAt: readAt is Timestamp ? readAt.toDate() : null,
            );
          }).toList(),
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
        .set(
          <String, dynamic>{
            'readAt': FieldValue.serverTimestamp(),
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
}
