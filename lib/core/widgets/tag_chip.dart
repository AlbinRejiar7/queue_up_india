import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../theme/app_text_styles.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    required this.label,
    super.key,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10.w : 12.w,
        vertical: compact ? 4.h : 6.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: compact ? 12.sp : 14.sp,
              color: textColor ?? AppColors.textSecondary,
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: AppTextStyles.chipLabel.copyWith(
              color: textColor ?? AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
