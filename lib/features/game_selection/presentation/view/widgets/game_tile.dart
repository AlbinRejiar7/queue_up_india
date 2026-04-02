import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../../core/widgets/glass_container.dart';
import '../../../models/game_model.dart';

class GameTile extends StatelessWidget {
  const GameTile({required this.game, required this.onTap, super.key});

  final GameModel game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      borderRadius: 34.r,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 180.h,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(34.r),
              child: game.coverUrl.startsWith('http')
                  ? AppNetworkImage(imageUrl: game.coverUrl, fit: BoxFit.cover)
                  : Image.asset(game.coverUrl, fit: BoxFit.cover),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34.r),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Color(0xC0101422)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(18.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    game.name,
                    style: AppTextStyles.pageTitle.copyWith(
                      fontSize: 32.sp / 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        game.activePartiesLabel,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
