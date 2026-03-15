import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_options.dart';
import '../constants/app_routes.dart';
import '../constants/app_strings.dart';

enum AppBottomTab { home, games, create, rooms, profile }

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    required this.activeTab,
    super.key,
    this.selectedGameId,
    this.profileAvatarUrl,
    this.showCenterAction = true,
    this.onTabSelected,
    this.onCenterActionPressed,
  });

  final AppBottomTab activeTab;
  final String? selectedGameId;
  final String? profileAvatarUrl;
  final bool showCenterAction;
  final ValueChanged<AppBottomTab>? onTabSelected;
  final VoidCallback? onCenterActionPressed;

  @override
  Widget build(BuildContext context) {
    final gameId = selectedGameId ?? AppOptions.valorantId;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 16.h),
        decoration: BoxDecoration(
          color: AppColors.navSurface.withValues(alpha: 0.9),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _BottomItem(
                icon: Icons.home_rounded,
                label: AppStrings.home,
                active: activeTab == AppBottomTab.home,
                onTap: () {
                  if (onTabSelected != null) {
                    onTabSelected!(AppBottomTab.home);
                    return;
                  }
                  context.go(AppRoutes.home);
                },
              ),
            ),
            Expanded(
              child: _BottomItem(
                icon: Icons.videogame_asset_rounded,
                label: AppStrings.games,
                active: activeTab == AppBottomTab.games,
                onTap: () {
                  if (onTabSelected != null) {
                    onTabSelected!(AppBottomTab.games);
                    return;
                  }
                  context.go(AppRoutes.gameSelection);
                },
              ),
            ),
            SizedBox(width: 8.w),
            if (showCenterAction)
              InkWell(
                onTap: () {
                  if (onCenterActionPressed != null) {
                    onCenterActionPressed!();
                    return;
                  }
                  context.go('${AppRoutes.createParty}?gameId=$gameId');
                },
                borderRadius: BorderRadius.circular(28.r),
                child: Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue,
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.electricBlue.withValues(
                          alpha: activeTab == AppBottomTab.create ? 0.52 : 0.42,
                        ),
                        blurRadius: 24,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              )
            else
              SizedBox(width: 56.w),
            SizedBox(width: 8.w),
            Expanded(
              child: _BottomItem(
                icon: Icons.groups_rounded,
                label: AppStrings.myRooms,
                active: activeTab == AppBottomTab.rooms,
                onTap: () {
                  if (onTabSelected != null) {
                    onTabSelected!(AppBottomTab.rooms);
                    return;
                  }
                  context.go(AppRoutes.rooms);
                },
              ),
            ),
            Expanded(
              child: _BottomAvatarItem(
                avatarUrl: profileAvatarUrl,
                label: AppStrings.profile,
                active: activeTab == AppBottomTab.profile,
                onTap: () {
                  if (onTabSelected != null) {
                    onTabSelected!(AppBottomTab.profile);
                    return;
                  }
                  context.go(AppRoutes.profile);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.electricBlue : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 22.sp),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9.sp,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAvatarItem extends StatelessWidget {
  const _BottomAvatarItem({
    required this.avatarUrl,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String? avatarUrl;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.electricBlue : AppColors.textSecondary;
    final avatarProvider = _avatarProvider(avatarUrl);
    final size = 22.sp;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: active ? 1.6 : 1.2,
                ),
              ),
              child: ClipOval(
                child: avatarProvider != null
                    ? Image(
                        image: avatarProvider,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.account_circle_rounded,
                        color: color,
                        size: size,
                      ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9.sp,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ImageProvider? _avatarProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.trim().isEmpty) {
    return null;
  }
  if (avatarUrl.startsWith('http')) {
    return NetworkImage(avatarUrl);
  }
  return AssetImage(avatarUrl);
}
