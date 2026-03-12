import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_options.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../../../core/widgets/rank_tag_chip.dart';
import '../../../../../core/widgets/tag_chip.dart';
import '../../../models/available_player_model.dart';

class AvailablePlayerCard extends StatelessWidget {
  const AvailablePlayerCard({
    required this.player,
    required this.onTap,
    required this.onChatTap,
    super.key,
  });

  final AvailablePlayerModel player;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    final gameName = AppOptions.gameNameById(player.gameId);
    final displayGameName = gameName.toUpperCase();

    return GlassContainer(
      borderRadius: 24.r,
      padding: EdgeInsets.all(14.r),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22.r,
            backgroundColor: AppColors.electricBlue.withValues(alpha: 0.2),
            child: Text(
              player.name.substring(0, 1).toUpperCase(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.electricBlue,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: <Widget>[
                    TagChip(
                      label: displayGameName,
                      compact: true,
                      icon: Icons.videogame_asset_rounded,
                    ),
                    RankTagChip(
                      rankName: player.rank,
                      gameId: player.gameId,
                      compact: true,
                    ),
                    TagChip(label: player.language, compact: true),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            onPressed: onChatTap,
            icon: Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textSecondary,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }
}
