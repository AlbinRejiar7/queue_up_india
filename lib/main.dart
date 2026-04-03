import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/services/availability_session_manager.dart';
import 'core/services/push_notification_service.dart';
import 'features/chat/data/local/direct_chat_cache_store.dart';
import 'features/party/viewmodel/party_view_model.dart';
import 'features/settings/viewmodel/profile_view_model.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  setupDependencies();
  await sl<DirectChatCacheStore>().initialize();
  if (FirebaseAuth.instance.currentUser != null) {
    try {
      await AvailabilitySessionManager.clearAvailabilityOnStartup();
    } catch (_) {}
    try {
      await sl<ProfileViewModel>().loadPreferences();
    } catch (_) {}
  }
  await PushNotificationService.instance.initialize();
  runApp(const QueueUpApp());
  unawaited(_runDeferredStartupMaintenance());
}

Future<void> _runDeferredStartupMaintenance() async {
  try {
    await sl<PartyViewModel>().cleanupExpiredPartiesOnAppOpen();
  } catch (_) {}
}
