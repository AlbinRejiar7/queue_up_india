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
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/game_bloc.dart';
import '../../bloc/game_event.dart';
import '../../bloc/game_state.dart';
import 'widgets/game_tile.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({
    super.key,
    this.showBackButton = true,
  });

  final bool showBackButton;

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GameBloc>().add(const GamesRequested());
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
                  return BlocConsumer<GameBloc, GameState>(
                    listener: (BuildContext context, GameState state) {
                      if (state is GameError) {
                        AppSnackBar.showError(context, state.message);
                      }
                    },
                    builder: (BuildContext context, GameState state) {
                      final games = state.data.games;
                      final selectedGameId = state.data.selectedGameId;

                      return Column(
                        children: <Widget>[
                          Padding(
                            padding: contentPadding,
                            child: Column(
                              children: <Widget>[
                                SizedBox(height: 6.h),
                                Row(
                                  children: <Widget>[
                                    if (widget.showBackButton)
                                      const SafeBackButton(
                                        fallbackRoute: AppRoutes.login,
                                      )
                                    else
                                      SizedBox(width: 48.w),
                                    Expanded(
                                      child: Text(
                                        AppStrings.selectGame,
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.pageTitle,
                                      ),
                                    ),
                                    SizedBox(width: 48.w),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: contentPadding,
                              child: ListView(
                                children: <Widget>[
                                  Text(
                                    AppStrings.popularGames,
                                    style: AppTextStyles.sectionTitle,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    AppStrings.gameDescription,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  SizedBox(height: 20.h),
                                  if (state is GameLoading && games.isEmpty)
                                    SizedBox(
                                      height: 220.h,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else
                                    ...games.map(
                                      (game) => Padding(
                                        padding: EdgeInsets.only(bottom: 16.h),
                                        child: GameTile(
                                          game: game,
                                          onTap: () {
                                            context.read<GameBloc>().add(
                                              GameSelected(gameId: game.id),
                                            );
                                            context.push(
                                              AppRoutes.partyListPath(game.id),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 24.h),
                                ],
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
