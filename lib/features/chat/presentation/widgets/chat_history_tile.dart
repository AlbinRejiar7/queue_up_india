import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../models/chat_thread.dart';

class ChatHistoryTile extends StatelessWidget {
  const ChatHistoryTile({
    required this.thread,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final ChatThread thread;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22.r),
      child: GlassContainer(
        borderRadius: 22.r,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AppColors.navSurface,
                  backgroundImage: _avatarProvider(thread.peerAvatarUrl),
                ),
                if (thread.unreadCount > 0)
                  Positioned(
                    right: -1.r,
                    top: -1.r,
                    child: Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.navSurface,
                          width: 2.r,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    thread.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              _formatTime(context, thread.lastMessageAt),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ImageProvider _avatarProvider(String url) {
  if (url.trim().isEmpty) {
    return const AssetImage(AppImages.avatarHost);
  }
  if (url.startsWith('http')) {
    return NetworkImage(url);
  }
  return AssetImage(url);
}

String _formatTime(BuildContext context, DateTime value) {
  final now = DateTime.now();
  final isSameDay = now.year == value.year &&
      now.month == value.month &&
      now.day == value.day;
  if (isSameDay) {
    return TimeOfDay.fromDateTime(value).format(context);
  }
  return '${value.day}/${value.month}';
}
