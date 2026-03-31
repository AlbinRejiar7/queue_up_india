import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../firebase_options.dart';
import '../constants/app_routes.dart';
import '../di/injection_container.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const bool _registerBackgroundHandlerInDebug = false;

  static const String _backgroundChannelId = 'queueup_alerts_default_v1';
  static const String _backgroundChannelName = 'QueueUp Alerts';
  static const String _backgroundChannelDescription =
      'Notifications when the app is closed or in the background';
  static const String _foregroundChannelId = 'queueup_alerts_custom_v1';
  static const String _foregroundChannelName = 'QueueUp In-App Alerts';
  static const String _foregroundChannelDescription =
      'Notifications shown while the app is open';
  static const String _androidSound = 'queueup_notification';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _activeDirectChatId;
  String? _activePartyId;
  bool _isPartyChatExpanded = false;
  bool _initialized = false;
  String? _currentUid;
  String? _lastSyncedToken;
  DateTime? _lastSyncAt;
  bool _tokenSyncInFlight = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!kDebugMode || _registerBackgroundHandlerInDebug) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    await _initLocalNotifications();
    await _requestPermissions();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });

    _auth.authStateChanges().listen((user) async {
      final newUid = user?.uid;
      if (_currentUid != null && _currentUid != newUid) {
        final token = await _messaging.getToken();
        if (token != null) {
          await _deleteToken(_currentUid!, token);
        }
      }
      _currentUid = newUid;
      if (newUid != null) {
        await _syncToken(newUid);
      }
    });

    _messaging.onTokenRefresh.listen((token) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        _saveToken(uid, token);
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }
  }

  void setActiveDirectChatId(String? peerId) {
    if (_activeDirectChatId == peerId) {
      return;
    }
    _activeDirectChatId = peerId;
  }

  void setPartyChatState({required String partyId, required bool isExpanded}) {
    if (_activePartyId == partyId && _isPartyChatExpanded == isExpanded) {
      return;
    }
    _isPartyChatExpanded = isExpanded;
    _activePartyId = isExpanded ? partyId : null;
  }

  Future<void> _syncToken(String uid) async {
    if (_tokenSyncInFlight) {
      return;
    }
    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint('[Push] FCM token not available yet.');
      return;
    }
    final now = DateTime.now();
    if (_lastSyncedToken == token &&
        _lastSyncAt != null &&
        now.difference(_lastSyncAt!) < const Duration(minutes: 5)) {
      debugPrint('[Push] token already synced recently.');
      return;
    }
    _tokenSyncInFlight = true;
    try {
      debugPrint('[Push] syncing token for $uid');
      await _saveToken(uid, token);
      _lastSyncedToken = token;
      _lastSyncAt = now;
    } finally {
      _tokenSyncInFlight = false;
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    debugPrint('[Push] saving token for $uid');
    await _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set(<String, dynamic>{
          'token': token,
          'platform': Platform.operatingSystem,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _deleteToken(String uid, String token) async {
    debugPrint('[Push] deleting token for $uid');
    await _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .delete();
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    if (!kIsWeb && Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTapPayload(response.payload);
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      const backgroundChannel = AndroidNotificationChannel(
        _backgroundChannelId,
        _backgroundChannelName,
        description: _backgroundChannelDescription,
        importance: Importance.high,
        playSound: true,
      );
      const foregroundChannel = AndroidNotificationChannel(
        _foregroundChannelId,
        _foregroundChannelName,
        description: _foregroundChannelDescription,
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_androidSound),
      );
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(backgroundChannel);
      await androidPlugin?.createNotificationChannel(foregroundChannel);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint(
      '[Push] foreground message: ${message.messageId} data=${message.data}',
    );
    if (!_shouldShowNotification(message)) {
      debugPrint('[Push] suppressed notification in foreground');
      return;
    }
    await _showLocalNotification(message);
  }

  bool _shouldShowNotification(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    if (type == 'direct_message') {
      final senderId = data['senderId'] as String?;
      if (senderId != null &&
          _activeDirectChatId != null &&
          _activeDirectChatId == senderId) {
        return false;
      }
    }

    if (type == 'party_message') {
      final partyId = data['partyId'] as String?;
      if (_isPartyChatExpanded &&
          _activePartyId != null &&
          _activePartyId == partyId) {
        return false;
      }
    }

    return true;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title'] as String? ?? 'QueueUp';
    final body = notification?.body ?? message.data['body'] as String? ?? '';
    final payload = jsonEncode(message.data);

    if (title.isEmpty && body.isEmpty) {
      return;
    }

    debugPrint('[Push] show local notification: $title');
    const androidDetails = AndroidNotificationDetails(
      _foregroundChannelId,
      _foregroundChannelName,
      channelDescription: _foregroundChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_androidSound),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } on PlatformException catch (error) {
      debugPrint(
        '[Push] local notification failed: ${error.code} ${error.message}',
      );
      const fallbackDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _foregroundChannelId,
          _foregroundChannelName,
          channelDescription: _foregroundChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: fallbackDetails,
        payload: payload,
      );
    }
  }

  void _handleNotificationTapPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _handleNotificationTap(decoded);
      }
    } catch (_) {
      // Ignore payload parsing errors.
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final partyId = data['partyId']?.toString();
    final senderId = data['senderId']?.toString();
    final fromUserId = data['fromUserId']?.toString();
    final status = data['status']?.toString();

    String? route;
    if (type == 'chat_request') {
      route = AppRoutes.notifications;
    } else if (type == 'chat_request_response') {
      if (status == 'accepted' && fromUserId != null && fromUserId.isNotEmpty) {
        route = AppRoutes.playerChatPath(fromUserId);
      } else {
        route = AppRoutes.notifications;
      }
    } else if (type == 'direct_message') {
      if (senderId != null && senderId.isNotEmpty) {
        route = AppRoutes.playerChatPath(senderId);
      } else {
        route = AppRoutes.chatHistory;
      }
    } else if (type == 'party_message' || type == 'party_joined') {
      if (partyId != null && partyId.isNotEmpty) {
        route = AppRoutes.partyDetailsPath(partyId);
      } else {
        route = AppRoutes.rooms;
      }
    } else if (type == 'party_kicked') {
      route = AppRoutes.rooms;
    }

    route ??= AppRoutes.notifications;

    _navigateToRoute(route);
  }

  void _navigateToRoute(String route) {
    final router = sl<GoRouter>();
    final currentLocation = router.routeInformationProvider.value.uri
        .toString();
    if (currentLocation == route) {
      return;
    }

    final baseRoute = _auth.currentUser == null
        ? AppRoutes.login
        : AppRoutes.home;
    final needsBase =
        currentLocation == AppRoutes.splash || currentLocation == '/';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (needsBase) {
        router.go(baseRoute);
      }
      router.push(route);
    });
  }
}
