import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

enum AppUpdatePromptKind { available, readyToInstall }

class AppUpdatePromptData {
  const AppUpdatePromptData({
    required this.info,
    required this.kind,
  });

  final AppUpdateInfo info;
  final AppUpdatePromptKind kind;
}

class AppUpdateService {
  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<AppUpdatePromptData?> checkForPrompt() async {
    if (!isSupportedPlatform) {
      return null;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.installStatus == InstallStatus.downloaded) {
        return AppUpdatePromptData(
          info: info,
          kind: AppUpdatePromptKind.readyToInstall,
        );
      }
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return null;
      }
      if (!info.immediateUpdateAllowed && !info.flexibleUpdateAllowed) {
        return null;
      }
      return AppUpdatePromptData(
        info: info,
        kind: AppUpdatePromptKind.available,
      );
    } catch (error, stackTrace) {
      debugPrint('[AppUpdate] check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  Future<bool> startUpdate(AppUpdatePromptData prompt) async {
    if (!isSupportedPlatform) {
      return false;
    }

    try {
      if (prompt.kind == AppUpdatePromptKind.readyToInstall) {
        await InAppUpdate.completeFlexibleUpdate();
        return true;
      }
      if (prompt.info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return true;
      }
      if (prompt.info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        return true;
      }
    } catch (error, stackTrace) {
      debugPrint('[AppUpdate] update start failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return false;
  }
}
