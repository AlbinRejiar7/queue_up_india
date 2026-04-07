import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../di/injection_container.dart';
import '../services/app_update_service.dart';
import 'app_snackbar.dart';

class AppUpdatePromptGate extends StatefulWidget {
  const AppUpdatePromptGate({required this.child, super.key});

  final Widget child;

  @override
  State<AppUpdatePromptGate> createState() => _AppUpdatePromptGateState();
}

class _AppUpdatePromptGateState extends State<AppUpdatePromptGate> {
  bool _hasCheckedThisSession = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdate());
    });
  }

  Future<void> _checkForUpdate() async {
    if (_hasCheckedThisSession || !mounted) {
      return;
    }
    _hasCheckedThisSession = true;
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) {
      return;
    }

    final prompt = await sl<AppUpdateService>().checkForPrompt();
    if (!mounted || prompt == null || _dialogVisible) {
      return;
    }
    _dialogVisible = true;
    final bool shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                prompt.kind == AppUpdatePromptKind.readyToInstall
                    ? AppStrings.updateReadyTitle
                    : AppStrings.updateAvailableTitle,
              ),
              content: Text(
                prompt.kind == AppUpdatePromptKind.readyToInstall
                    ? AppStrings.updateReadyMessage
                    : AppStrings.updateAvailableMessage,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(AppStrings.laterAction),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(AppStrings.updateAction),
                ),
              ],
            );
          },
        ) ??
        false;
    _dialogVisible = false;

    if (!mounted || !shouldUpdate) {
      return;
    }

    final bool started = await sl<AppUpdateService>().startUpdate(prompt);
    if (!mounted) {
      return;
    }
    if (!started) {
      AppSnackBar.showError(context, AppStrings.updateFailedMessage);
      return;
    }
    if (prompt.kind == AppUpdatePromptKind.available &&
        prompt.info.flexibleUpdateAllowed &&
        !prompt.info.immediateUpdateAllowed) {
      AppSnackBar.showInfo(context, AppStrings.updateStartedMessage);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
