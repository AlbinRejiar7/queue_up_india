import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:queue_up_india/core/constants/app_colors.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_dialog.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../models/party_player_model.dart';

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    required this.player,
    super.key,
    this.showKick = false,
    this.onKick,
  });

  final PartyPlayerModel player;
  final bool showKick;
  final VoidCallback? onKick;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 22.r,
      backgroundColor: AppColors.navSurface.withValues(alpha: 0.56),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 23.r,
            backgroundImage: NetworkImage(player.avatarUrl),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  player.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  player.status,
                  style: AppTextStyles.caption.copyWith(
                    color: player.isHost
                        ? AppColors.electricBlue
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          if (showKick && !player.isHost) ...<Widget>[
            SizedBox(width: 6.w),
            IconButton(
              onPressed: () async {
                if (onKick == null) {
                  return;
                }
                final confirm = await AppDialog.showConfirm(
                  context,
                  title: AppStrings.confirmKickTitle,
                  message: AppStrings.confirmKickMessage,
                  confirmLabel: AppStrings.kickPlayer,
                  cancelLabel: AppStrings.cancelAction,
                  confirmIsDestructive: true,
                );
                if (!confirm) {
                  return;
                }
                onKick!();
              },
              icon: const Icon(Icons.person_remove_alt_1_rounded),
              color: AppColors.danger,
              iconSize: 20.sp,
              tooltip: AppStrings.kickPlayer,
            ),
          ],
        ],
      ),
    );
  }
}
