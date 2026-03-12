import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../constants/app_options.dart';
import '../theme/app_text_styles.dart';

class RankTagChip extends StatelessWidget {
  const RankTagChip({
    required this.rankName,
    super.key,
    this.gameId,
    this.compact = false,
    this.backgroundColor,
    this.textColor,
  });

  final String rankName;
  final String? gameId;
  final bool compact;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final imagePath = AppOptions.rankImageByName(
      rankName: rankName,
      gameId: gameId,
    );
    final resolvedTextColor = textColor ?? AppColors.textSecondary;
    final imageSize = compact ? 14.w : 16.w;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10.w : 12.w,
        vertical: compact ? 4.h : 6.h,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (imagePath != null) ...<Widget>[
            _RankImage(path: imagePath, size: imageSize),
            SizedBox(width: 5.w),
          ],
          Text(
            rankName,
            style: AppTextStyles.chipLabel.copyWith(color: resolvedTextColor),
          ),
        ],
      ),
    );
  }
}

class _RankImage extends StatelessWidget {
  const _RankImage({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Icon(Icons.workspace_premium, size: size, color: AppColors.textSecondary);
  }
}
