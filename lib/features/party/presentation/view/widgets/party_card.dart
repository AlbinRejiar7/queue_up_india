import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../../../core/widgets/rank_tag_chip.dart';
import '../../../../../core/widgets/tag_chip.dart';
import '../../../models/party_model.dart';

class PartyCard extends StatelessWidget {
  const PartyCard({
    required this.party,
    required this.onJoin,
    super.key,
    this.isJoining = false,
  });

  final PartyModel party;
  final VoidCallback onJoin;
  final bool isJoining;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 30.r,
      padding: EdgeInsets.all(10.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: SizedBox(
              height: 132.h,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  party.coverImageUrl.startsWith('http')
                      ? Image.network(party.coverImageUrl, fit: BoxFit.cover)
                      : Image.asset(party.coverImageUrl, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.transparent, Color(0xBE101422)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10.h,
                    left: 10.w,
                    child: RankTagChip(
                      rankName: party.rank,
                      gameId: party.gameId,
                      backgroundColor:
                          AppColors.navSurface.withValues(alpha: 0.9),
                      textColor: AppColors.textPrimary,
                      compact: true,
                    ),
                  ),
                  Positioned(
                    bottom: 10.h,
                    left: 10.w,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.group_rounded,
                          size: 14.sp,
                          color: AppColors.electricBlue,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${party.playerCount}/${party.maxPlayers} ${AppStrings.players}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ),
      SizedBox(height: 12.h),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  party.name,
                  style: AppTextStyles.pageTitle.copyWith(
                    fontSize: 24.sp / 1.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _createdLabel(party.createdAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: <Widget>[
                    TagChip(label: party.language, compact: true),
                        ...party.tags.map(
                          (tag) => TagChip(label: tag, compact: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              if (party.isFull)
                const TagChip(
                  label: AppStrings.full,
                  backgroundColor: AppColors.danger,
                  textColor: Colors.white,
                )
              else
                SizedBox(
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: isJoining ? null : onJoin,
                    child: Text(
                      AppStrings.join,
                      style: AppTextStyles.buttonText.copyWith(fontSize: 14.sp),
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

String _createdLabel(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) {
    return AppStrings.createdTimeLabel(AppStrings.justNow);
  }
  if (diff.inHours < 1) {
    return AppStrings.createdTimeLabel(AppStrings.minutesAgo(diff.inMinutes));
  }
  if (diff.inDays < 1) {
    return AppStrings.createdTimeLabel(AppStrings.hoursAgo(diff.inHours));
  }
  return AppStrings.createdTimeLabel(AppStrings.daysAgo(diff.inDays));
}
