import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../../game_selection/bloc/game_bloc.dart';
import '../../../game_selection/bloc/game_event.dart';
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
                  return BlocBuilder<HomeAvailabilityBloc, HomeAvailabilityState>(
                    builder: (BuildContext context, HomeAvailabilityState state) {
                      if (state.selectedGameId == null) {
                        context.read<HomeAvailabilityBloc>().add(
                              HomeAvailabilityInitialized(
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
                                    if (showBackButton)
                                      const SafeBackButton(
                                        fallbackRoute: AppRoutes.gameSelection,
                                      )
                                    else
                                      SizedBox(width: 48.w),
                                    Expanded(
                                      child: Text(
                                        AppStrings.home,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        context.push(AppRoutes.notifications);
                                      },
                                      icon: Icon(
                                        Icons.notifications_none_rounded,
                                        size: 22.sp,
                                        color: AppColors.textPrimary,
                                      ),
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
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              contentPadding.left,
                              0,
                              contentPadding.right,
                              10.h,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 42.h,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.push(AppRoutes.availablePlayers);
                                },
                                icon: Icon(Icons.groups_rounded, size: 18.sp),
                                label: Text(
                                  AppStrings.seeAvailablePlayers,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
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
    );
  }
}
