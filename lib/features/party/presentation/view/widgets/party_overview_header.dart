import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/rank_tag_chip.dart';
import '../../../../../core/widgets/tag_chip.dart';
import '../../../models/party_model.dart';

class PartyOverviewHeader extends StatelessWidget {
  const PartyOverviewHeader({
    required this.party,
    super.key,
    this.opacity = 1,
  });

  final PartyModel party;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      opacity: opacity,
      child: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                width: 86.w,
                height: 86.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.electricBlue.withValues(alpha: 0.35),
                    width: 2.w,
                  ),
                  image: DecorationImage(
                    image: (party.logoImageUrl ?? party.coverImageUrl)
                            .startsWith('http')
                        ? NetworkImage(
                            party.logoImageUrl ?? party.coverImageUrl,
                          )
                        : AssetImage(
                              party.logoImageUrl ?? party.coverImageUrl,
                            )
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 2.w,
                bottom: 2.h,
                child: Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 2.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            party.name,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 24.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            '${AppStrings.createdBy} ${_resolveHostName(party)}',
            style: AppTextStyles.bodyMedium,
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: <Widget>[
              RankTagChip(
                rankName: party.rank,
                gameId: party.gameId,
                backgroundColor: AppColors.navSurface.withValues(alpha: 0.9),
                textColor: AppColors.textPrimary,
              ),
              TagChip(label: party.language),
              TagChip(
                label:
                    '${AppStrings.players} ${party.playerCount}/${party.maxPlayers}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _resolveHostName(PartyModel party) {
  if (party.players.isNotEmpty) {
    return party.players.first.name;
  }
  return 'Host';
}
