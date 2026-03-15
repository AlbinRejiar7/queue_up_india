import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/app_preferences.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _transitionDuration = Duration(milliseconds: 2400);
  static const Duration _navigationDelay = Duration(milliseconds: 2600);

  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _hasNavigated = false;
  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _transitionDuration)
      ..forward();
    _progress = Tween<double>(begin: 0.18, end: 0.86).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future<void>.delayed(_navigationDelay, _navigateNext);
    _loadVersion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      setState(() {
        _versionLabel = 'Ver ${info.version}';
      });
    } catch (_) {
      // Keep the fallback label.
    }
  }

  Future<void> _navigateNext() async {
    if (_hasNavigated || !mounted) {
      return;
    }
    _hasNavigated = true;
    final bool isLoggedIn = await AppPreferences.isLoggedIn();
    await AppPreferences.markFirstLaunchComplete();
    if (!mounted) {
      return;
    }
    context.go(isLoggedIn ? AppRoutes.home : AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: ResponsiveLayoutBuilder(
            builder:
                (
                  BuildContext context,
                  BoxConstraints constraints,
                  EdgeInsets contentPadding,
                ) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: contentPadding,
                        child: Column(
                          children: <Widget>[
                            SizedBox(height: 12.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.circle,
                                      size: 8.sp,
                                      color: AppColors.electricBlue,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      AppStrings.serverStatus,
                                      style: AppTextStyles.caption.copyWith(
                                        letterSpacing: 1.8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: <Widget>[
                                    TextButton(
                                      onPressed: _navigateNext,
                                      child: Text(
                                        AppStrings.skip,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.wifi_tethering,
                                      color: AppColors.textSecondary,
                                      size: 22.sp,
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.settings,
                                      color: AppColors.textSecondary,
                                      size: 22.sp,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Container(
                              width: 280.w,
                              height: 280.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(36.r),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.electricBlue.withValues(
                                      alpha: 0.24,
                                    ),
                                    blurRadius: 44.r,
                                    spreadRadius: -16.r,
                                  ),
                                ],
                                image: const DecorationImage(
                                  image: NetworkImage(AppImages.splashHero),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 30.h),
                            Text.rich(
                              TextSpan(
                                text: 'Queue',
                                children: <InlineSpan>[
                                  TextSpan(
                                    text: 'Up',
                                    style: TextStyle(
                                      color: AppColors.electricBlue,
                                      shadows: <Shadow>[
                                        Shadow(
                                          color: AppColors.electricBlue
                                              .withValues(alpha: 0.46),
                                          blurRadius: 24.r,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              style: AppTextStyles.sectionTitle.copyWith(
                                fontSize: 58.sp,
                                letterSpacing: -1.8,
                                height: 0.95,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              AppStrings.tagline,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontSize: 17.sp,
                              ),
                            ),
                            SizedBox(height: 40.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  AppStrings.syncingServers,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _progress,
                                  builder: (context, child) {
                                    final percent =
                                        (_progress.value * 100).round();
                                    return Text(
                                      '$percent%',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.electricBlue,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            AnimatedBuilder(
                              animation: _progress,
                              builder: (context, child) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: LinearProgressIndicator(
                                    value: _progress.value,
                                    minHeight: 6,
                                    backgroundColor: AppColors.surface,
                                    color: AppColors.electricBlue,
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    Text(
                                      '14.2k',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20.sp,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      AppStrings.activePlayers,
                                      style: AppTextStyles.caption.copyWith(
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20.w),
                                SizedBox(
                                  height: 42.h,
                                  child: const VerticalDivider(
                                    color: AppColors.navSurface,
                                    width: 1,
                                  ),
                                ),
                                SizedBox(width: 20.w),
                                Column(
                                  children: <Widget>[
                                    Text(
                                      '2.4s',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20.sp,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      AppStrings.averageQueue,
                                      style: AppTextStyles.caption.copyWith(
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  _versionLabel.isEmpty
                                      ? AppStrings.versionLabel
                                      : _versionLabel,
                                  style: AppTextStyles.caption.copyWith(
                                    letterSpacing: 2.2,
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    Text(
                                      AppStrings.privacy,
                                      style: AppTextStyles.caption.copyWith(
                                        letterSpacing: 2.2,
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Text(
                                      AppStrings.terms,
                                      style: AppTextStyles.caption.copyWith(
                                        letterSpacing: 2.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                          ],
                        ),
                      ),
                    ),
                  );
                },
          ),
        ),
      ),
    );
  }
}
