import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../game_selection/bloc/game_bloc.dart';
import '../../../game_selection/bloc/game_event.dart';
import '../../../chat/bloc/chat_badge_bloc.dart';
import '../../../chat/bloc/chat_badge_event.dart';
import '../../../chat/bloc/chat_badge_state.dart';
import '../../../notifications/bloc/notifications_bloc.dart';
import '../../../notifications/bloc/notifications_event.dart';
import '../../../notifications/bloc/notifications_state.dart';
import '../../bloc/home_availability_bloc.dart';
import '../../bloc/home_availability_event.dart';
import '../../bloc/home_availability_state.dart';
import 'widgets/availability_filters_card.dart';
import 'widgets/availability_wave_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.showBackButton = true,
    this.selectedGameId,
  });

  final bool showBackButton;
  final String? selectedGameId;

  @override
  Widget build(BuildContext context) {
    final selectedGameId = this.selectedGameId ?? AppOptions.valorantId;

    return BlocProvider<NotificationsBloc>(
      create: (_) =>
          sl<NotificationsBloc>()..add(const NotificationsStarted()),
      child: Scaffold(
        body: GlowBackground(
          child: SafeArea(
            child: ResponsiveLayoutBuilder(
              builder:
                  (
                    BuildContext context,
                    BoxConstraints constraints,
                    EdgeInsets contentPadding,
                  ) {
                    return BlocBuilder<HomeAvailabilityBloc,
                        HomeAvailabilityState>(
                      builder:
                          (BuildContext context, HomeAvailabilityState state) {
                        context.read<ChatBadgeBloc>().add(
                              const ChatBadgeStarted(),
                            );
                        if (state.selectedGameId == null) {
                          context.read<HomeAvailabilityBloc>().add(
                                HomeAvailabilityInitialized(
                                  gameId: selectedGameId,
                                ),
                              );
                        } else if (state.selectedGameId != selectedGameId) {
                          context.read<HomeAvailabilityBloc>().add(
                                HomeAvailabilityGameChanged(
                                  gameId: selectedGameId,
                                ),
                              );
                        }

                        return Column(
                          children: <Widget>[
                            Padding(
                              padding: contentPadding,
                              child: Column(
                                children: <Widget>[
                                SizedBox(height: 6.h),
                                Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: max(48, 48.w),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: showBackButton
                                            ? const SafeBackButton(
                                                fallbackRoute:
                                                    AppRoutes.gameSelection,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        AppStrings.home,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        BlocBuilder<ChatBadgeBloc,
                                            ChatBadgeState>(
                                          builder: (context, chatState) {
                                            return IconButton(
                                              padding: EdgeInsets.zero,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              constraints: BoxConstraints(
                                                minWidth: 40.w,
                                                minHeight: 40.w,
                                              ),
                                              onPressed: () {
                                                context.push(
                                                  AppRoutes.chatHistory,
                                                );
                                              },
                                              icon: Stack(
                                                clipBehavior: Clip.none,
                                                children: <Widget>[
                                                  Icon(
                                                    Icons.chat_bubble_outline,
                                                    size: 22.sp,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                  if (chatState.hasUnread)
                                                    Positioned(
                                                      right: -1,
                                                      top: -1,
                                                      child: Container(
                                                        width: 8.r,
                                                        height: 8.r,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              AppColors.success,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        BlocBuilder<NotificationsBloc,
                                            NotificationsState>(
                                          builder: (context, notifications) {
                                            final hasBadge =
                                                notifications
                                                    .hasPendingRequests ||
                                                notifications.hasUnread;
                                            return IconButton(
                                              padding: EdgeInsets.zero,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              constraints: BoxConstraints(
                                                minWidth: 40.w,
                                                minHeight: 40.w,
                                              ),
                                              onPressed: () {
                                                context.push(
                                                  AppRoutes.notifications,
                                                );
                                              },
                                              icon: Stack(
                                                clipBehavior: Clip.none,
                                                children: <Widget>[
                                                  Icon(
                                                    Icons.notifications_none,
                                                    size: 22.sp,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                  if (hasBadge)
                                                    Positioned(
                                                      right: -1,
                                                      top: -1,
                                                      child: Container(
                                                        width: 8.r,
                                                        height: 8.r,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              AppColors.success,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  AppStrings.homeTitle,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.sectionTitle.copyWith(
                                    fontSize: 28.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  AppStrings.homeSubtitle,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12.sp,
                                  ),
                                ),
                                BlocBuilder<ChatBadgeBloc, ChatBadgeState>(
                                  builder: (context, chatState) {
                                    return BlocBuilder<NotificationsBloc,
                                        NotificationsState>(
                                      builder: (context, notificationsState) {
                                        final hasRequests =
                                            notificationsState
                                                .hasPendingRequests;
                                        final hasMessages = chatState.hasUnread;
                                        String? hint;
                                        if (hasRequests && hasMessages) {
                                          hint = AppStrings
                                              .newRequestsAndMessagesHint;
                                        } else if (hasRequests) {
                                          hint = AppStrings.newRequestsHint;
                                        } else if (hasMessages) {
                                          hint = AppStrings.newMessagesHint;
                                        }
                                        if (hint == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: EdgeInsets.only(top: 6.h),
                                          child: Text(
                                            hint,
                                            textAlign: TextAlign.center,
                                            style:
                                                AppTextStyles.caption.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder:
                                  (
                                    BuildContext context,
                                    BoxConstraints boxConstraints,
                                  ) {
                                    final minSide = min(
                                      boxConstraints.maxWidth,
                                      boxConstraints.maxHeight,
                                    );
                                    final maxDiameter =
                                        minSide / AvailabilityWaveButton.waveScale;
                                    final target = min(maxDiameter, 220.w);
                                    final safeMin = 120.w;
                                    final diameter = maxDiameter < safeMin
                                        ? maxDiameter
                                        : max(safeMin, target);

                                    return Center(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onTap: () {
                                          if (!state.canToggleAvailability) {
                                            AppSnackBar.showInfo(
                                              context,
                                              AppStrings
                                                  .completeAvailabilitySelection,
                                            );
                                            return;
                                          }
                                          context
                                              .read<HomeAvailabilityBloc>()
                                              .add(
                                                const HomeAvailabilityToggled(),
                                              );
                                        },
                                        child: AvailabilityWaveButton(
                                          isAvailable: state.isAvailable,
                                          enabled: state.canToggleAvailability,
                                          diameter: diameter,
                                          onPressed: () {
                                            context
                                                .read<HomeAvailabilityBloc>()
                                                .add(
                                                  const HomeAvailabilityToggled(),
                                                );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              contentPadding.left,
                              0,
                              contentPadding.right,
                              8.h,
                            ),
                            child: AvailabilityFiltersCard(
                              selectedGameId: state.selectedGameId,
                              selectedLanguage: state.selectedLanguage,
                              selectedRank: state.selectedRank,
                              onGameChanged: (String? value) {
                                if (value != null) {
                                  context.read<HomeAvailabilityBloc>().add(
                                        HomeAvailabilityGameChanged(
                                          gameId: value,
                                        ),
                                      );
                                  context.read<GameBloc>().add(
                                        GameSelected(gameId: value),
                                      );
                                }
                              },
                              onLanguageChanged: (String? value) {
                                context.read<HomeAvailabilityBloc>().add(
                                      HomeAvailabilityLanguageChanged(
                                        language: value,
                                      ),
                                    );
                              },
                              onRankChanged: (String? value) {
                                context.read<HomeAvailabilityBloc>().add(
                                      HomeAvailabilityRankChanged(rank: value),
                                    );
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              contentPadding.left,
                              0,
                              contentPadding.right,
                              10.h,
                            ),
                            child: Text(
                              !state.canToggleAvailability
                                  ? AppStrings.completeAvailabilitySelection
                                  : state.isAvailable
                                  ? AppStrings.availabilityHintOn
                                  : AppStrings.availabilityHintOff,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium,
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
