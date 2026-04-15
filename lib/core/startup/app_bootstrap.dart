import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../app.dart';
import '../../firebase_options.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../di/injection_container.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../utils/app_preferences.dart';
import '../widgets/startup_loading_view.dart';
import '../../features/chat/data/local/direct_chat_cache_store.dart';
import '../../features/party/viewmodel/party_view_model.dart';
import '../../features/settings/viewmodel/profile_view_model.dart';
import '../services/availability_session_manager.dart';
import '../services/push_notification_service.dart';
import '../ads/ad_helper.dart';
import '../ads/app_open_ad_manager.dart';
import '../ads/interstitial_ad_manager.dart';
import '../ads/rewarded_ad_manager.dart';
import 'app_startup_controller.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap>
    with WidgetsBindingObserver {
  static const Duration _minimumStartupDisplay = Duration(milliseconds: 2600);

  bool _showApp = false;
  Object? _bootError;
  bool _hasShownColdStartAd = false;
  late final Future<void> _minimumDisplay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppStartupController.begin();
    _minimumDisplay = Future<void>.delayed(_minimumStartupDisplay);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AppOpenAdManager.instance.onAppBackgrounded();
    }
    if (state == AppLifecycleState.resumed) {
      AppOpenAdManager.instance.tryShowOnResume();
    }
  }

  Future<void> _bootstrap() async {
    AppStartupController.begin();
    if (mounted) {
      setState(() {
        _bootError = null;
      });
    }
    try {
      await Hive.initFlutter();
      await dotenv.load(fileName: '.env');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Initialise ads SDK and pre-load ads.
      await AdHelper.initialise();
      AppOpenAdManager.instance.loadAd();
      InterstitialAdManager.instance.loadAd();
      RewardedAdManager.instance.loadAd();

      final bool hasAuthSession = FirebaseAuth.instance.currentUser != null;
      registerRouter(
        initialLocation: hasAuthSession ? AppRoutes.home : AppRoutes.login,
      );

      await Future.wait<void>(<Future<void>>[
        _runBackgroundStartup(),
        _minimumDisplay,
      ]);

      final bool savedLoggedIn = await AppPreferences.isLoggedIn();
      if (savedLoggedIn != hasAuthSession) {
        await AppPreferences.setLoggedIn(hasAuthSession);
      }
      await AppPreferences.markFirstLaunchComplete();

      if (!mounted) {
        return;
      }

      setState(() {
        _showApp = true;
        _bootError = null;
      });

      // Show App Open ad on cold start (once).
      if (!_hasShownColdStartAd) {
        _hasShownColdStartAd = true;
        AppOpenAdManager.instance.showAdIfAvailable();
      }
    } catch (error, stack) {
      debugPrint('[Startup] bootstrap failed: $error');
      debugPrintStack(stackTrace: stack);
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stack,
          reason: 'App bootstrap failed',
          fatal: false,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _bootError = error;
      });
      AppStartupController.markReady();
    }
  }

  Future<void> _runBackgroundStartup() async {
    try {
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
      await _runDeferredStartupMaintenance();
    } catch (error, stack) {
      debugPrint('[Startup] background startup failed: $error');
      debugPrintStack(stackTrace: stack);
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'Background startup failed',
        fatal: false,
      );
    } finally {
      AppStartupController.markReady();
    }
  }

  Future<void> _runDeferredStartupMaintenance() async {
    try {
      await sl<PartyViewModel>().cleanupExpiredPartiesOnAppOpen();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_showApp) {
      return const QueueUpApp();
    }
    return _StartupShell(bootError: _bootError, onRetry: _bootstrap);
  }
}

class _StartupShell extends StatelessWidget {
  const _StartupShell({required this.bootError, required this.onRetry});

  final Object? bootError;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'QueueUp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: bootError == null
              ? const StartupLoadingView()
              : _StartupErrorView(onRetry: onRetry),
        );
      },
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'We hit a startup issue.',
                style: AppTextStyles.sectionTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please try again. The app could not finish loading.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  unawaited(onRetry());
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
