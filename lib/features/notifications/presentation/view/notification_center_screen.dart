import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/notifications_bloc.dart';
import '../../bloc/notifications_event.dart';
import '../../bloc/notifications_state.dart';
import '../../models/notification_item.dart';

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
                    return BlocListener<NotificationsBloc, NotificationsState>(
                      listenWhen: (previous, current) =>
                          previous.actionMessage != current.actionMessage ||
                          previous.pendingChatPlayer !=
                              current.pendingChatPlayer,
                      listener: (context, state) {
                        final message = state.actionMessage;
                        if (message != null && message.isNotEmpty) {
                          if (state.actionSuccess == true) {
                            AppSnackBar.showSuccess(context, message);
                          } else {
                            AppSnackBar.showError(context, message);
                          }
                        }
                        final chatPlayer = state.pendingChatPlayer;
                        if (chatPlayer != null) {
                          context.push(
                            AppRoutes.playerChatPath(chatPlayer.id),
                            extra: chatPlayer,
                          );
                        }
                        if (message != null || chatPlayer != null) {
                          context.read<NotificationsBloc>().add(
                                const NotificationsActionCleared(),
                              );
                        }
                      },
                      child:
                          BlocBuilder<NotificationsBloc, NotificationsState>(
                        builder:
                            (BuildContext context, NotificationsState state) {
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
                                          final isRequest = item.isChatRequest;
                                          final isPending =
                                              item.isPending ||
                                              item.status == null;
                                          final title = item.fromUserName ??
                                              item.title;
                                          final avatar = item.fromUserAvatar ??
                                              AppImages.avatarHost;

                                          return GlassContainer(
                                            borderRadius: 24.r,
                                            padding: EdgeInsets.all(16.r),
                                            onTap: !isRequest
                                                ? () {
                                                    if (!item.isRead) {
                                                      context
                                                          .read<
                                                              NotificationsBloc>()
                                                          .add(
                                                            NotificationReadRequested(
                                                              notificationId:
                                                                  item.id,
                                                            ),
                                                          );
                                                    }
                                                  }
                                                : null,
                                            child: Column(
                                              children: <Widget>[
                                                Row(
                                                  children: <Widget>[
                                                    CircleAvatar(
                                                      radius: 18.r,
                                                      backgroundColor: AppColors
                                                          .electricBlue
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      backgroundImage:
                                                          _avatarProvider(
                                                            avatar,
                                                          ),
                                                    ),
                                                    SizedBox(width: 12.w),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(
                                                            title,
                                                            style: AppTextStyles
                                                                .bodyMedium
                                                                .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          if (item
                                                              .body.isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  EdgeInsets.only(
                                                                top: 4.h,
                                                              ),
                                                              child: Text(
                                                                item.body,
                                                                style:
                                                                    AppTextStyles
                                                                        .caption,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (!isRequest)
                                                      Icon(
                                                        item.isRead
                                                            ? Icons
                                                                .notifications_none
                                                            : Icons
                                                                .notifications_active_outlined,
                                                        size: 22.sp,
                                                        color: Colors.white,
                                                      ),
                                                  ],
                                                ),
                                                if (isRequest) ...<Widget>[
                                                  SizedBox(height: 12.h),
                                                  Row(
                                                    children: <Widget>[
                                                      _StatusChip(
                                                        label: _statusLabel(
                                                          item.status,
                                                          isPending,
                                                        ),
                                                        isPending: isPending,
                                                      ),
                                                      const Spacer(),
                                                      if (isPending) ...<Widget>[
                                                        OutlinedButton(
                                                          onPressed: () {
                                                            context
                                                                .read<
                                                                    NotificationsBloc>()
                                                                .add(
                                                                  NotificationRequestDeclined(
                                                                    notification:
                                                                        item,
                                                                  ),
                                                                );
                                                          },
                                                          child: Text(
                                                            AppStrings
                                                                .declineAction,
                                                          ),
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            context
                                                                .read<
                                                                    NotificationsBloc>()
                                                                .add(
                                                                  NotificationRequestAccepted(
                                                                    notification:
                                                                        item,
                                                                  ),
                                                                );
                                                          },
                                                          child: Text(
                                                            AppStrings
                                                                .acceptAction,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isPending});

  final String label;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final color = isPending ? AppColors.electricBlueBright : AppColors.success;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

ImageProvider _avatarProvider(String url) {
  if (url.trim().isEmpty) {
    return const NetworkImage(AppImages.avatarHost);
  }
  if (url.startsWith('http')) {
    return NetworkImage(url);
  }
  return AssetImage(url);
}

String _statusLabel(String? status, bool isPending) {
  if (isPending) {
    return AppStrings.requestPendingLabel;
  }
  if (status == NotificationItem.statusAccepted) {
    return AppStrings.requestAcceptedLabel;
  }
  if (status == NotificationItem.statusDeclined) {
    return AppStrings.requestDeclinedLabel;
  }
  return AppStrings.requestPendingLabel;
}
