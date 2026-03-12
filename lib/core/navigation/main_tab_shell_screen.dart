import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/home/presentation/view/home_screen.dart';
import '../../features/game_selection/bloc/game_bloc.dart';
import '../../features/game_selection/bloc/game_event.dart';
import '../../features/game_selection/bloc/game_state.dart';
import '../../features/game_selection/presentation/view/game_selection_screen.dart';
import '../../features/party/presentation/view/create_party_screen.dart';
import '../../features/party/presentation/view/my_rooms_screen.dart';
import '../../features/settings/presentation/view/profile_screen.dart';
import '../constants/app_options.dart';
import '../constants/app_strings.dart';
import '../navigation/bloc/main_tab_bloc.dart';
import '../navigation/bloc/main_tab_event.dart';
import '../navigation/bloc/main_tab_state.dart';
import '../widgets/app_bottom_bar.dart';
import '../widgets/app_dialog.dart';

class MainTabShellScreen extends StatefulWidget {
  const MainTabShellScreen({
    required this.initialTab,
    super.key,
    this.initialGameId,
  });

  final AppBottomTab initialTab;
  final String? initialGameId;

  @override
  State<MainTabShellScreen> createState() => _MainTabShellScreenState();
}

class _MainTabShellScreenState extends State<MainTabShellScreen> {
  static const Duration _slideDuration = Duration(milliseconds: 260);

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = _indexForTab(widget.initialTab);
    _pageController = PageController(initialPage: initialIndex);
    context.read<MainTabBloc>().add(MainTabInitialized(index: initialIndex));
    final initialGameId = widget.initialGameId;
    if (initialGameId != null && initialGameId.trim().isNotEmpty) {
      context.read<GameBloc>().add(GameSelected(gameId: initialGameId));
    }
  }

  @override
  void didUpdateWidget(covariant MainTabShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final nextIndex = _indexForTab(widget.initialTab);
      context.read<MainTabBloc>().add(MainTabInitialized(index: nextIndex));
      _animateToIndex(nextIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _animateToIndex(int index) async {
    if (!mounted || index == _pageController.page?.round()) {
      return;
    }

    await _pageController.animateToPage(
      index,
      duration: _slideDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await AppDialog.showConfirm(
          context,
          title: AppStrings.confirmExitTitle,
          message: AppStrings.confirmExitMessage,
          confirmLabel: AppStrings.confirmAction,
          cancelLabel: AppStrings.cancelAction,
        );
        if (shouldExit) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        bottomNavigationBar: BlocBuilder<GameBloc, GameState>(
          builder: (BuildContext context, GameState gameState) {
            final selectedGameId =
                gameState.data.selectedGameId ?? AppOptions.valorantId;

            return BlocBuilder<MainTabBloc, MainTabState>(
              builder: (BuildContext context, MainTabState tabState) {
                return AppBottomBar(
                  activeTab: _tabForIndex(tabState.activeIndex),
                  selectedGameId: selectedGameId,
                  onTabSelected: (AppBottomTab tab) {
                    final nextIndex = _indexForTab(tab);
                    context
                        .read<MainTabBloc>()
                        .add(MainTabIndexChanged(index: nextIndex));
                    _animateToIndex(nextIndex);
                  },
                  onCenterActionPressed: () {
                    final nextIndex = _indexForTab(AppBottomTab.create);
                    context
                        .read<MainTabBloc>()
                        .add(MainTabIndexChanged(index: nextIndex));
                    _animateToIndex(nextIndex);
                  },
                );
              },
            );
          },
        ),
        body: BlocBuilder<GameBloc, GameState>(
          builder: (BuildContext context, GameState gameState) {
            final selectedGameId =
                gameState.data.selectedGameId ?? AppOptions.valorantId;

            return PageView.builder(
              controller: _pageController,
              itemCount: 5,
              onPageChanged: (int pageIndex) {
                context
                    .read<MainTabBloc>()
                    .add(MainTabIndexChanged(index: pageIndex));
              },
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return HomeScreen(
                    key: ValueKey<String>('home-tab-$selectedGameId'),
                    selectedGameId: selectedGameId,
                    showBackButton: false,
                  );
                }

                if (index == 1) {
                  return const GameSelectionScreen(
                    showBackButton: false,
                  );
                }

                if (index == 2) {
                  return CreatePartyScreen(
                    key: ValueKey<String>('create-tab-$selectedGameId'),
                    gameId: selectedGameId,
                    showBackButton: false,
                  );
                }

                if (index == 3) {
                  return const MyRoomsScreen(
                    showBackButton: false,
                  );
                }

                return const ProfileScreen(
                  showBackButton: false,
                );
              },
            );
          },
        ),
      ),
    );
  }

  static int _indexForTab(AppBottomTab tab) {
    switch (tab) {
      case AppBottomTab.home:
        return 0;
      case AppBottomTab.games:
        return 1;
      case AppBottomTab.create:
        return 2;
      case AppBottomTab.rooms:
        return 3;
      case AppBottomTab.profile:
        return 4;
    }
  }

  static AppBottomTab _tabForIndex(int index) {
    if (index == 1) {
      return AppBottomTab.games;
    }
    if (index == 2) {
      return AppBottomTab.create;
    }
    if (index == 3) {
      return AppBottomTab.rooms;
    }
    if (index == 4) {
      return AppBottomTab.profile;
    }
    return AppBottomTab.home;
  }
}
