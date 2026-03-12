import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.electricBlueBright,
        secondary: AppColors.softPurple,
        error: AppColors.danger,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    final overlayColor = MaterialStateProperty.resolveWith<Color?>(
      (states) {
        if (states.contains(MaterialState.pressed)) {
          return AppColors.softPurple.withValues(alpha: 0.22);
        }
        if (states.contains(MaterialState.hovered)) {
          return AppColors.softPurple.withValues(alpha: 0.12);
        }
        return null;
      },
    );

    return base.copyWith(
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.pageTitle.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        hintStyle: AppTextStyles.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(
            color: AppColors.electricBlue,
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlueBright,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor:
              AppColors.electricBlueBright.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.textPrimary.withValues(alpha: 0.6),
          shape: buttonShape,
          elevation: 14,
          shadowColor: AppColors.softPurple.withValues(alpha: 0.65),
        ).copyWith(overlayColor: overlayColor),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.electricBlueBright,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor:
              AppColors.electricBlueBright.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.textPrimary.withValues(alpha: 0.6),
          shape: buttonShape,
        ).copyWith(overlayColor: overlayColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricBlueBright,
          side: BorderSide(
            color: AppColors.electricBlueBright.withValues(alpha: 0.95),
            width: 1.4,
          ),
          shape: buttonShape,
        ).copyWith(overlayColor: overlayColor),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.electricBlueBright,
        ).copyWith(overlayColor: overlayColor),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.electricBlueBright,
        ).copyWith(overlayColor: overlayColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        selectedColor: AppColors.electricBlue.withValues(alpha: 0.25),
        labelStyle: AppTextStyles.chipLabel,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
