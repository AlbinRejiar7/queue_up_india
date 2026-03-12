import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_options.dart';
import '../theme/app_text_styles.dart';
import 'glass_container.dart';

class AvatarSelectionGrid extends StatelessWidget {
  const AvatarSelectionGrid({
    required this.selectedAvatarUrl,
    required this.onAvatarSelected,
    super.key,
    this.title,
    this.subtitle,
  });

  final String? selectedAvatarUrl;
  final ValueChanged<String> onAvatarSelected;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 28.r,
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Text(
              title!,
              style: AppTextStyles.pageTitle.copyWith(fontSize: 18.sp),
            ),
            SizedBox(height: 4.h),
          ],
          if (subtitle != null) ...<Widget>[
            Text(
              subtitle!,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 12.sp),
            ),
            SizedBox(height: 14.h),
          ] else
            SizedBox(height: 10.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
        children: AppOptions.profileAvatarOptions.map((String avatar) {
              final isSelected = avatar == (selectedAvatarUrl ?? '');
              return _AvatarOption(
                avatarUrl: avatar,
                isSelected: isSelected,
                onTap: () => onAvatarSelected(avatar),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.avatarUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String avatarUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.all(isSelected ? 3.r : 1.5.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? AppColors.electricBlue
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: <BoxShadow>[
            if (isSelected)
              BoxShadow(
                color: AppColors.electricBlue.withValues(alpha: 0.35),
                blurRadius: 18.r,
                spreadRadius: -6.r,
              ),
          ],
        ),
        child: CircleAvatar(
          radius: 26.r,
          backgroundImage: avatarUrl.startsWith('http')
              ? NetworkImage(avatarUrl)
              : AssetImage(avatarUrl) as ImageProvider,
          backgroundColor: AppColors.surface,
        ),
      ),
    );
  }
}
