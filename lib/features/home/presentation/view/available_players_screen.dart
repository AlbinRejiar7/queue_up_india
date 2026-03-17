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

  Future<void> _handleRefresh() async {
    final bloc = context.read<AvailablePlayersBloc>();
    bloc.add(const AvailablePlayersRefreshRequested());
    await bloc.stream.firstWhere((state) => state.isLoading);
    await bloc.stream.firstWhere((state) => !state.isLoading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: ResponsiveLayoutBuilder(
            tabletMaxWidth: 960,
            tabletHorizontalPadding: 32,
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
                      final bool isTablet = constraints.maxWidth >= 600;

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
                          final messageType = state.requestMessageType ??
                              (state.requestSuccess == true
                                  ? RequestMessageType.success
                                  : RequestMessageType.error);
                          if (state.requestActionPeerId != null) {
                            final peerId = state.requestActionPeerId!;
                            AppSnackBar.showAction(
                              context,
                              message,
                              actionLabel: AppStrings.openChatAction,
                              onAction: () {
                                if (!context.mounted) {
                                  return;
                                }
                                context.push(
                                  AppRoutes.playerChatPath(peerId),
                                );
                              },
                              type: _mapSnackBarType(messageType),
                            );
                          } else {
                            switch (messageType) {
                              case RequestMessageType.success:
                                AppSnackBar.showSuccess(context, message);
                                break;
                              case RequestMessageType.info:
                                AppSnackBar.showInfo(context, message);
                                break;
                              case RequestMessageType.error:
                                AppSnackBar.showError(context, message);
                                break;
                            }
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
                              child: RefreshIndicator(
                                onRefresh: _handleRefresh,
                                child: state.isLoading && players.isEmpty
                                    ? ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        padding: EdgeInsets.fromLTRB(
                                          contentPadding.left,
                                          120.h,
                                          contentPadding.right,
                                          20.h,
                                        ),
                                        children: const <Widget>[
                                          Center(
                                            child:
                                                CircularProgressIndicator(),
                                          ),
                                        ],
                                      )
                                    : players.isEmpty
                                        ? ListView(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            padding: EdgeInsets.fromLTRB(
                                              contentPadding.left,
                                              120.h,
                                              contentPadding.right,
                                              20.h,
                                            ),
                                            children: <Widget>[
                                              Center(
                                                child: Text(
                                                  AppStrings.noAvailablePlayers,
                                                  style:
                                                      AppTextStyles.bodyMedium,
                                                ),
                                              ),
                                            ],
                                          )
                                        : (isTablet
                                            ? GridView.builder(
                                                controller: _scrollController,
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(),
                                                padding: EdgeInsets.fromLTRB(
                                                  contentPadding.left,
                                                  14.h,
                                                  contentPadding.right,
                                                  20.h,
                                                ),
                                                itemCount: players.length +
                                                    (state.isLoadingMore
                                                        ? 1
                                                        : 0),
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  mainAxisExtent: 140.h,
                                                  mainAxisSpacing: 12.h,
                                                  crossAxisSpacing: 12.w,
                                                ),
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  if (index >= players.length) {
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  }
                                                  final player = players[index];
                                                  final isSelf =
                                                      currentUserId != null &&
                                                      player.id ==
                                                          currentUserId;
                                                  Future<void>
                                                      handleRequestTap() async {
                                                    if (isSelf) {
                                                      AppSnackBar.showError(
                                                        context,
                                                        AppStrings
                                                            .cannotChatWithSelf,
                                                      );
                                                      return;
                                                    }
                                                    final confirmed =
                                                        await AppDialog
                                                            .showConfirm(
                                                      context,
                                                      title: AppStrings
                                                          .sendChatRequestTitle,
                                                      message: AppStrings
                                                          .sendChatRequestMessage(
                                                        player.name,
                                                      ),
                                                      confirmLabel: AppStrings
                                                          .sendChatRequestAction,
                                                      cancelLabel: AppStrings
                                                          .cancelAction,
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
                                              )
                                            : ListView.separated(
                                                controller: _scrollController,
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(),
                                                padding: EdgeInsets.fromLTRB(
                                                  contentPadding.left,
                                                  14.h,
                                                  contentPadding.right,
                                                  20.h,
                                                ),
                                                itemCount: players.length +
                                                    (state.isLoadingMore
                                                        ? 1
                                                        : 0),
                                                separatorBuilder:
                                                    (context, index) =>
                                                        SizedBox(height: 10.h),
                                                itemBuilder: (
                                                  BuildContext context,
                                                  int index,
                                                ) {
                                                  if (index >= players.length) {
                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        vertical: 8.h,
                                                      ),
                                                      child: const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    );
                                                  }
                                                  final player =
                                                      players[index];
                                                  final isSelf =
                                                      currentUserId != null &&
                                                      player.id ==
                                                          currentUserId;
                                                  Future<void>
                                                      handleRequestTap() async {
                                                    if (isSelf) {
                                                      AppSnackBar.showError(
                                                        context,
                                                        AppStrings
                                                            .cannotChatWithSelf,
                                                      );
                                                      return;
                                                    }
                                                    final confirmed =
                                                        await AppDialog
                                                            .showConfirm(
                                                      context,
                                                      title: AppStrings
                                                          .sendChatRequestTitle,
                                                      message: AppStrings
                                                          .sendChatRequestMessage(
                                                        player.name,
                                                      ),
                                                      confirmLabel: AppStrings
                                                          .sendChatRequestAction,
                                                      cancelLabel: AppStrings
                                                          .cancelAction,
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
                                              )),
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

AppSnackBarType _mapSnackBarType(RequestMessageType type) {
  switch (type) {
    case RequestMessageType.success:
      return AppSnackBarType.success;
    case RequestMessageType.info:
      return AppSnackBarType.info;
    case RequestMessageType.error:
      return AppSnackBarType.error;
  }
}
