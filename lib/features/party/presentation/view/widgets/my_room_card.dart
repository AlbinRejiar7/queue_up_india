import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_options.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/app_timeouts.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../../../core/widgets/rank_tag_chip.dart';
import '../../../../../core/widgets/tag_chip.dart';
import '../../../models/party_model.dart';

class MyRoomCard extends StatelessWidget {
  static const Duration _partyLifetime = AppTimeouts.partyTtl;

  const MyRoomCard({
    required this.party,
    required this.isCreatedRoom,
    required this.onOpen,
    this.onDelete,
    super.key,
  });

  final PartyModel party;
  final bool isCreatedRoom;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final statusLabel = isCreatedRoom
        ? AppStrings.roomCreated
        : AppStrings.roomJoined;
    final statusColor = isCreatedRoom
        ? AppColors.electricBlue
        : AppColors.softPurple;
    final expiryLabel = isCreatedRoom
        ? AppStrings.partyAutoDeletesIn(
            _formatTimeLeft(_timeLeftUntilExpiry(party.createdAt)),
          )
        : null;

    return GlassContainer(
      borderRadius: 26.r,
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  party.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              TagChip(
                label: statusLabel,
                compact: true,
                backgroundColor: statusColor.withValues(alpha: 0.18),
                textColor: statusColor,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: <Widget>[
              TagChip(
                label: AppOptions.gameNameById(party.gameId),
                compact: true,
                icon: Icons.videogame_asset_rounded,
              ),
              RankTagChip(
                rankName: party.rank,
                gameId: party.gameId,
                compact: true,
              ),
              TagChip(label: party.language, compact: true),
            ],
          ),
          if (expiryLabel != null) ...<Widget>[
            SizedBox(height: 10.h),
            Row(
              children: <Widget>[
                Icon(
                  Icons.schedule_rounded,
                  color: AppColors.textSecondary,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    expiryLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          Row(
            children: <Widget>[
              Icon(
                Icons.group_rounded,
                color: AppColors.electricBlue,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                '${party.playerCount}/${party.maxPlayers}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 14.w),
              Icon(
                Icons.key_rounded,
                color: AppColors.textSecondary,
                size: 17.sp,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  party.partyCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              if (isCreatedRoom && onDelete != null) ...<Widget>[
                SizedBox(
                  height: 36.h,
                  child: OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.6),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                    ),
                    child: Text(
                      AppStrings.deleteParty,
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              SizedBox(
                height: 36.h,
                child: ElevatedButton(
                  onPressed: onOpen,
                  child: Text(
                    AppStrings.openRoom,
                    style: AppTextStyles.buttonText.copyWith(fontSize: 13.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Duration _timeLeftUntilExpiry(DateTime createdAt) {
  final expiresAt = createdAt.add(MyRoomCard._partyLifetime);
  final difference = expiresAt.difference(DateTime.now());
  if (difference.isNegative) {
    return Duration.zero;
  }
  return difference;
}

String _formatTimeLeft(Duration duration) {
  if (duration.inMinutes <= 0) {
    return '< 1m';
  }
  if (duration.inHours >= 1) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }
  return '${duration.inMinutes}m';
}
