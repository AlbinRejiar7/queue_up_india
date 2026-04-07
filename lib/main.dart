import 'package:flutter/material.dart';

import 'core/di/injection_container.dart';
import 'core/startup/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const AppBootstrap());
}
