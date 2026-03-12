import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/notifications_bloc.dart';
import '../../bloc/notifications_event.dart';
import '../../bloc/notifications_state.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider<NotificationsBloc>(
        create: (_) =>
            sl<NotificationsBloc>()..add(const NotificationsStarted()),
        child: GlowBackground(
          child: SafeArea(
            child: ResponsiveLayoutBuilder(
              builder:
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsets contentPadding,
                  ) {
                    return BlocBuilder<NotificationsBloc, NotificationsState>(
                      builder: (BuildContext context, NotificationsState state) {
                        final items = state.notifications;
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
                              child: items.isEmpty
                                  ? Center(
                                      child: Text(
                                        AppStrings.noNotifications,
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.fromLTRB(
                                        contentPadding.left,
                                        16.h,
                                        contentPadding.right,
                                        24.h,
                                      ),
                                      itemCount: items.length,
                                      separatorBuilder: (context, index) =>
                                          SizedBox(height: 10.h),
                                      itemBuilder: (context, index) {
                                        final item = items[index];
                                        return GlassContainer(
                                          borderRadius: 24.r,
                                          padding: EdgeInsets.all(16.r),
                                          child: Row(
                                            children: <Widget>[
                                              Icon(
                                                item.isRead
                                                    ? Icons.notifications_none
                                                    : Icons
                                                        .notifications_active_outlined,
                                                size: 22.sp,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      item.title,
                                                      style: AppTextStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    if (item.body.isNotEmpty)
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                          top: 4.h,
                                                        ),
                                                        child: Text(
                                                          item.body,
                                                          style:
                                                              AppTextStyles.caption,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    );
                  },
            ),
          ),
        ),
      ),
    );
  }
}
