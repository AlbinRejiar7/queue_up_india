import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  setupDependencies();
  await PushNotificationService.instance.initialize();
  runApp(const QueueUpApp());
}
