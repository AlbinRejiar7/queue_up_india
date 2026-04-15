import 'dart:async';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service responsible for managing the Google Play Core In-App Update flow.
/// 
/// Integrates with Firebase Remote Config to determine if an update is 
/// "critical" (force update) or "flexible" (optional).
class PlayCoreUpdateService {
  PlayCoreUpdateService();

  static const String _remoteConfigKey = 'min_required_build_number';

  /// Notifies listeners when the update info changes (e.g. downloaded).
  final ValueNotifier<AppUpdateInfo?> updateInfo = ValueNotifier<AppUpdateInfo?>(null);

  /// Whether the current platform supports Google Play Core updates.
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Main entry point to check and handle the update flow.
  /// 
  /// This should be called during app startup (e.g., in Splash Screen).
  Future<void> handleUpdateFlow() async {
    if (!isSupported) {
      debugPrint('[PlayCoreUpdate] Platform not supported (Android only).');
      return;
    }

    try {
      debugPrint('[PlayCoreUpdate] Checking for updates...');
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      updateInfo.value = info;

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        final bool isCritical = await _isUpdateCritical();

        if (isCritical) {
          debugPrint('[PlayCoreUpdate] Critical update detected. Starting Immediate flow.');
          await _performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          debugPrint('[PlayCoreUpdate] Flexible update available. Starting background download.');
          await InAppUpdate.startFlexibleUpdate();
          _monitorFlexibleUpdate();
        }
      } else if (info.installStatus == InstallStatus.downloaded) {
        debugPrint('[PlayCoreUpdate] Update already downloaded and ready to install.');
      }
    } catch (e) {
      debugPrint('[PlayCoreUpdate] Error during update check: $e');
    }
  }

  /// Monitors the status of a flexible update download.
  void _monitorFlexibleUpdate() {
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      final info = await InAppUpdate.checkForUpdate();
      updateInfo.value = info;
      
      if (info.installStatus == InstallStatus.downloaded) {
        timer.cancel();
      }
      if (info.updateAvailability == UpdateAvailability.updateNotAvailable && info.installStatus != InstallStatus.downloaded) {
        timer.cancel();
      }
    });
  }

  /// Determines if the available update is critical based on Remote Config.
  Future<bool> _isUpdateCritical() async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      
      // Ensure we have fresh config
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.fetchAndActivate();

      final int minRequiredBuild = remoteConfig.getInt(_remoteConfigKey);
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final int currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint('[PlayCoreUpdate] Current Build: $currentBuild, Min Required: $minRequiredBuild');
      
      return currentBuild < minRequiredBuild;
    } catch (e) {
      debugPrint('[PlayCoreUpdate] Remote Config check failed: $e');
      return false;
    }
  }

  /// Triggers the full-screen blocking immediate update flow.
  Future<void> _performImmediateUpdate() async {
    try {
      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.success) {
        debugPrint('[PlayCoreUpdate] Immediate update successful.');
      } else {
        debugPrint('[PlayCoreUpdate] Immediate update result: $result');
      }
    } catch (e) {
      debugPrint('[PlayCoreUpdate] Immediate update failed: $e');
    }
  }

  /// Completes the flexible update process by restarting the app.
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('[PlayCoreUpdate] Failed to complete flexible update: $e');
    }
  }
}
