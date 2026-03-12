import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_values.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppValues.radiusLarge,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.blurSigma = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white.withValues(alpha: 0.035),
                border: Border.all(
                  color: borderColor ?? Colors.white.withValues(alpha: 0.12),
                ),
                borderRadius: radius,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.electricBlue.withValues(alpha: 0.08),
                    blurRadius: 24,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
