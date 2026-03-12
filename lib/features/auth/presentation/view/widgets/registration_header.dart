import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';

class RegistrationHeader extends StatelessWidget {
  const RegistrationHeader({
    super.key,
    this.title,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? AppStrings.createAccountTitle;
    final resolvedSubtitle = subtitle ?? AppStrings.createAccountSubtitle;
    final parts = resolvedTitle.split(' ');
    if (parts.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            resolvedTitle,
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 32.sp,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            resolvedSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
          ),
        ],
      );
    }

    final headline = parts.first;
    final highlight = parts.sublist(1).join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          TextSpan(
            text: '$headline ',
            children: <InlineSpan>[
              TextSpan(
                text: highlight,
                style: TextStyle(
                  color: AppColors.electricBlue,
                  fontSize: 32.sp,
                ),
              ),
            ],
          ),
          style: AppTextStyles.sectionTitle.copyWith(
            fontSize: 32.sp,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          resolvedSubtitle,
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp),
        ),
      ],
    );
  }
}
