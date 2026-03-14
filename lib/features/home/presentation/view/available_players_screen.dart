import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/glow_background.dart';
import '../../../../core/widgets/responsive_layout_builder.dart';
import '../../../../core/widgets/safe_back_button.dart';
import '../../bloc/available_players_bloc.dart';
import '../../bloc/available_players_event.dart';
import '../../bloc/available_players_state.dart';
import 'widgets/available_player_card.dart';
import 'widgets/available_players_filters.dart';

class AvailablePlayersScreen extends StatefulWidget {
  const AvailablePlayersScreen({super.key});

  @override
  State<AvailablePlayersScreen> createState() => _AvailablePlayersScreenState();
}

class _AvailablePlayersScreenState extends State<AvailablePlayersScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _initializedFromRoute = false;

  @override
  void initState() {
    super.initState();
    context.read<AvailablePlayersBloc>().add(const AvailablePlayersLoaded());
    _scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromRoute) {
      return;
    }
    _initializedFromRoute = true;
    final gameId = GoRouterState.of(context).uri.queryParameters['gameId'];
    if (gameId != null && gameId.isNotEmpty) {
      context
          .read<AvailablePlayersBloc>()
          .add(AvailablePlayersGameChanged(gameId: gameId));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= 200.h) {
      context
          .read<AvailablePlayersBloc>()
          .add(const AvailablePlayersLoadMoreRequested());
    }
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
                  return BlocBuilder<AvailablePlayersBloc, AvailablePlayersState>(
                    builder: (BuildContext context, AvailablePlayersState state) {
                      final players = state.players;
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;

                      return BlocListener<
                        AvailablePlayersBloc,
                        AvailablePlayersState
                      >(
                        listenWhen: (previous, current) =>
                            previous.requestMessage != current.requestMessage &&
                            current.requestMessage != null,
                        listener: (context, state) {
                          final message = state.requestMessage;
                          if (message == null) {
                            return;
                          }
                          if (state.requestSuccess == true) {
                            AppSnackBar.showSuccess(context, message);
                          } else {
                            AppSnackBar.showError(context, message);
                          }
                          context.read<AvailablePlayersBloc>().add(
                                const AvailablePlayersRequestMessageCleared(),
                              );
                        },
                        child: Column(
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
                              child: state.isLoading && players.isEmpty
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : players.isEmpty
                                      ? Center(
                                          child: Text(
                                            AppStrings.noAvailablePlayers,
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        )
                                      : ListView.separated(
                                          controller: _scrollController,
                                          padding: EdgeInsets.fromLTRB(
                                            contentPadding.left,
                                            14.h,
                                            contentPadding.right,
                                            20.h,
                                          ),
                                          itemCount: players.length +
                                              (state.isLoadingMore ? 1 : 0),
                                          separatorBuilder: (context, index) =>
                                              SizedBox(height: 10.h),
                                          itemBuilder: (BuildContext context,
                                              int index) {
                                            if (index >= players.length) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  vertical: 8.h,
                                                ),
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                            final player = players[index];
                                            final isSelf =
                                                currentUserId != null &&
                                                player.id == currentUserId;
                                            Future<void> handleRequestTap()
                                            async {
                                              if (isSelf) {
                                                AppSnackBar.showError(
                                                  context,
                                                  AppStrings
                                                      .cannotChatWithSelf,
                                                );
                                                return;
                                              }
                                              final confirmed =
                                                  await AppDialog.showConfirm(
                                                context,
                                                title: AppStrings
                                                    .sendChatRequestTitle,
                                                message: AppStrings
                                                    .sendChatRequestMessage(
                                                      player.name,
                                                    ),
                                                confirmLabel: AppStrings
                                                    .sendChatRequestAction,
                                                cancelLabel:
                                                    AppStrings.cancelAction,
                                              );
                                              if (!context.mounted) {
                                                return;
                                              }
                                              if (!confirmed) {
                                                return;
                                              }
                                              context
                                                  .read<
                                                      AvailablePlayersBloc>()
                                                  .add(
                                                    AvailablePlayersRequestSent(
                                                      player: player,
                                                    ),
                                                  );
                                            }

                                            return AvailablePlayerCard(
                                              player: player,
                                              canChat: !isSelf,
                                              onTap: handleRequestTap,
                                              onChatTap: handleRequestTap,
                                            );
                                          },
                                        ),
                            ),
                          ],
                        ),
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
