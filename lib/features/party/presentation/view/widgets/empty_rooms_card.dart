import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/glass_container.dart';

class EmptyRoomsCard extends StatelessWidget {
  const EmptyRoomsCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24.r,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
