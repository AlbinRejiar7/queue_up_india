import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/startup/app_startup_controller.dart';
import '../../../../core/utils/app_preferences.dart';
import '../../../../core/widgets/startup_loading_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _navigationDelay = Duration(milliseconds: 2600);

  bool _hasNavigated = false;
  late final Future<void> _minimumDelay;

  @override
  void initState() {
    super.initState();
    _minimumDelay = Future<void>.delayed(_navigationDelay);
    unawaited(_navigateNext());
  }

  Future<void> _navigateNext() async {
    if (_hasNavigated || !mounted) {
      return;
    }
    await Future.wait<void>(<Future<void>>[
      _minimumDelay,
      AppStartupController.ready,
    ]);
    if (_hasNavigated || !mounted) {
      return;
    }
    _hasNavigated = true;
    final bool savedLoggedIn = await AppPreferences.isLoggedIn();
    final bool hasAuthSession = FirebaseAuth.instance.currentUser != null;
    if (savedLoggedIn != hasAuthSession) {
      await AppPreferences.setLoggedIn(hasAuthSession);
    }
    await AppPreferences.markFirstLaunchComplete();
    if (!mounted) {
      return;
    }
    context.go(hasAuthSession ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return StartupLoadingView(
      allowSkip: true,
      onSkip: () {
        unawaited(_navigateNext());
      },
    );
  }
}
