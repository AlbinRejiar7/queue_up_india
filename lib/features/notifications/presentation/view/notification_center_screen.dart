import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

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
                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: contentPadding,
                        child: Column(
                          children: <Widget>[
                            SizedBox(height: 6.h),
                            Row(
                              children: <Widget>[
                                const SafeBackButton(
                                  fallbackRoute: AppRoutes.home,
                                ),
                                Expanded(
                                  child: Text(
                                    AppStrings.notifications,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.pageTitle,
                                  ),
                                ),
                                SizedBox(width: 48.w),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              AppStrings.notificationsSubtitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(
                            contentPadding.left,
                            16.h,
                            contentPadding.right,
                            24.h,
                          ),
                          children: <Widget>[
                            GlassContainer(
                              borderRadius: 24.r,
                              padding: EdgeInsets.all(16.r),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.notifications_active_outlined,
                                    size: 22.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      AppStrings.noNotifications,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
          ),
        ),
      ),
    );
  }
}
