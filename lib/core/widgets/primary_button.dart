import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_values.dart';
import '../theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.isDanger = false,
    this.onDisabledPressed,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;
  final bool isDanger;
  final VoidCallback? onDisabledPressed;

  @override
  Widget build(BuildContext context) {
    final Color background = isDanger
        ? AppColors.danger
        : AppColors.electricBlueBright;
    final bool isEnabled = enabled && !isLoading;
    final bool canHandleDisabled = !isLoading && onDisabledPressed != null;
    final VoidCallback? resolvedOnPressed = isEnabled
        ? onPressed
        : canHandleDisabled
        ? onDisabledPressed
        : null;
    final Color resolvedBackground = isEnabled
        ? background
        : background.withValues(alpha: 0.35);

    return SizedBox(
      height: 56.h,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: resolvedOnPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppValues.radiusLarge),
          ),
          backgroundColor: resolvedBackground,
          disabledBackgroundColor: resolvedBackground,
          shadowColor: background.withValues(alpha: isEnabled ? 0.65 : 0.2),
          elevation: isEnabled ? 14 : 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 20.sp),
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
