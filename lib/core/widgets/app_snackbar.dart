import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppSnackBarType { error, success, info }

abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    AppSnackBarType type = AppSnackBarType.error,
  }) {
    if (message.trim().isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final theme = _themeFor(type);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.background,
        elevation: 10,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding + 56),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Row(
          children: <Widget>[
            Icon(theme.icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
    AppSnackBarType type = AppSnackBarType.info,
  }) {
    if (message.trim().isEmpty) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final theme = _themeFor(type);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.background,
        elevation: 10,
        margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding + 56),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
        content: Row(
          children: <Widget>[
            Icon(theme.icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    show(context, message, type: AppSnackBarType.error);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, type: AppSnackBarType.success);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message, type: AppSnackBarType.info);
  }

  static _SnackBarTheme _themeFor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return const _SnackBarTheme(
          background: AppColors.success,
          icon: Icons.check_circle,
        );
      case AppSnackBarType.info:
        return const _SnackBarTheme(
          background: AppColors.electricBlue,
          icon: Icons.info_rounded,
        );
      case AppSnackBarType.error:
        return const _SnackBarTheme(
          background: AppColors.danger,
          icon: Icons.error_rounded,
        );
    }
  }
}

class _SnackBarTheme {
  const _SnackBarTheme({required this.background, required this.icon});

  final Color background;
  final IconData icon;
}
