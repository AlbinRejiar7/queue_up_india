import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/available_players_bloc.dart';
import '../../bloc/available_players_event.dart';
import '../../bloc/available_players_state.dart';
import 'widgets/available_player_card.dart';
import 'widgets/available_players_filters.dart';

class AvailablePlayersScreen extends StatelessWidget {
  const AvailablePlayersScreen({super.key});

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
                  return BlocBuilder<AvailablePlayersBloc, AvailablePlayersState>(
                    builder: (BuildContext context, AvailablePlayersState state) {
                      if (state.allPlayers.isEmpty) {
                        context
                            .read<AvailablePlayersBloc>()
                            .add(const AvailablePlayersLoaded());
                      }

                      final players = state.filteredPlayers;

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
                                        AppStrings.availablePlayersTitle,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    SizedBox(width: 48.w),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  AppStrings.availablePlayersSubtitle,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium,
                                ),
                                SizedBox(height: 10.h),
                                AvailablePlayersFilters(
                                  selectedGameId: state.selectedGameId,
                                  selectedRank: state.selectedRank,
                                  selectedLanguage: state.selectedLanguage,
                                  onGameChanged: (String? value) {
                                    context.read<AvailablePlayersBloc>().add(
                                          AvailablePlayersGameChanged(
                                            gameId: value,
                                          ),
                                        );
                                  },
                                  onRankChanged: (String? value) {
                                    context.read<AvailablePlayersBloc>().add(
                                          AvailablePlayersRankChanged(
                                            rank: value,
                                          ),
                                        );
                                  },
                                  onLanguageChanged: (String? value) {
                                    context.read<AvailablePlayersBloc>().add(
                                          AvailablePlayersLanguageChanged(
                                            language: value,
                                          ),
                                        );
                                  },
                                  onReset: () {
                                    context
                                        .read<AvailablePlayersBloc>()
                                        .add(const AvailablePlayersReset());
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: players.isEmpty
                                ? Center(
                                    child: Text(
                                      AppStrings.noAvailablePlayers,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.fromLTRB(
                                      contentPadding.left,
                                      14.h,
                                      contentPadding.right,
                                      20.h,
                                    ),
                                    itemCount: players.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(height: 10.h),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          return AvailablePlayerCard(
                                            player: players[index],
                                            onTap: () {
                                              context.push(
                                                AppRoutes.playerChatPath(
                                                  players[index].id,
                                                ),
                                                extra: players[index],
                                              );
                                            },
                                            onChatTap: () {
                                              context.push(
                                                AppRoutes.playerChatPath(
                                                  players[index].id,
                                                ),
                                                extra: players[index],
                                              );
                                            },
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
    );
  }
}
