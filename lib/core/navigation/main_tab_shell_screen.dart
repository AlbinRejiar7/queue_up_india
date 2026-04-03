import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/home/presentation/view/home_screen.dart';
import '../../features/game_selection/bloc/game_bloc.dart';
import '../../features/game_selection/bloc/game_event.dart';
import '../../features/game_selection/bloc/game_state.dart';
import '../../features/game_selection/presentation/view/game_selection_screen.dart';
import '../../features/home/bloc/home_availability_bloc.dart';
import '../../features/party/presentation/view/create_party_screen.dart';
import '../../features/party/presentation/view/my_rooms_screen.dart';
import '../../features/settings/bloc/profile_bloc.dart';
import '../../features/settings/bloc/profile_event.dart';
import '../../features/settings/bloc/profile_state.dart';
import '../../features/settings/presentation/view/profile_screen.dart';
import '../constants/app_options.dart';
import '../constants/app_strings.dart';
import '../di/injection_container.dart';
import '../services/direct_chat_monitor_service.dart';
import '../services/in_app_alert_service.dart';
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

class _MainTabShellScreenState extends State<MainTabShellScreen>
    with WidgetsBindingObserver {
  static const Duration _slideDuration = Duration(milliseconds: 260);

  late final PageController _pageController;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _hostPartySub;
  StreamSubscription<bool>? _availabilitySub;
  late final DirectChatMonitorService _directChatMonitorService =
      sl<DirectChatMonitorService>();
  final Map<String, int> _lastPartyCount = <String, int>{};
  bool _isAppActive = true;
  bool _hostPartyPrimed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialIndex = _indexForTab(widget.initialTab);
    _pageController = PageController(initialPage: initialIndex);
    context.read<MainTabBloc>().add(MainTabInitialized(index: initialIndex));
    final initialGameId = widget.initialGameId;
    if (initialGameId != null && initialGameId.trim().isNotEmpty) {
      context.read<GameBloc>().add(GameSelected(gameId: initialGameId));
    }
    context.read<ProfileBloc>().add(const ProfileRequested());
    _availabilitySub = context
        .read<HomeAvailabilityBloc>()
        .stream
        .map((state) => state.isAvailable)
        .distinct()
        .listen((_) {
          _refreshInAppAlerts();
        });
    _directChatMonitorService.start();
    _refreshInAppAlerts();
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
    WidgetsBinding.instance.removeObserver(this);
    _hostPartySub?.cancel();
    _availabilitySub?.cancel();
    _directChatMonitorService.setAlertsEnabled(false);
    unawaited(_directChatMonitorService.stop());
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;
    _refreshInAppAlerts();
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

  void _refreshInAppAlerts() {
    _directChatMonitorService.setAlertsEnabled(_shouldListenForAlerts());
    if (_shouldListenForAlerts()) {
      _startInAppAlerts();
    } else {
      _stopInAppAlerts();
    }
  }

  void _startInAppAlerts() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _stopInAppAlerts();
      return;
    }

    if (_hostPartySub == null) {
      _hostPartyPrimed = false;
      _hostPartySub = FirebaseFirestore.instance
          .collection('parties')
          .where('hostId', isEqualTo: uid)
          .where('status', whereIn: <String>['open', 'full'])
          .limit(10)
          .snapshots()
          .listen(_handleHostPartySnapshot);
    }
  }

  void _stopInAppAlerts() {
    _hostPartySub?.cancel();
    _hostPartySub = null;
    _hostPartyPrimed = false;
    _lastPartyCount.clear();
  }

  void _handleHostPartySnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (!_shouldNotify()) {
      return;
    }
    if (!_hostPartyPrimed) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final currentPlayers = (data['currentPlayers'] as int?) ?? 0;
        _lastPartyCount[doc.id] = currentPlayers;
      }
      _hostPartyPrimed = true;
      return;
    }
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final currentPlayers = (data['currentPlayers'] as int?) ?? 0;
      final previous = _lastPartyCount[doc.id];
      _lastPartyCount[doc.id] = currentPlayers;
      if (previous != null && currentPlayers > previous) {
        InAppAlertService.notify();
      }
    }
  }

  bool _shouldListenForAlerts() {
    if (!_isAppActive) {
      return false;
    }
    final availability = context.read<HomeAvailabilityBloc>().state;
    return availability.isAvailable;
  }

  bool _shouldNotify() {
    return _shouldListenForAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
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
      },
      child: Scaffold(
        bottomNavigationBar: BlocBuilder<GameBloc, GameState>(
          builder: (BuildContext context, GameState gameState) {
            final selectedGameId =
                gameState.data.selectedGameId ?? AppOptions.valorantId;

            return BlocBuilder<MainTabBloc, MainTabState>(
              builder: (BuildContext context, MainTabState tabState) {
                return BlocBuilder<ProfileBloc, ProfileState>(
                  buildWhen: (previous, current) =>
                      previous.data.avatarUrl != current.data.avatarUrl,
                  builder: (context, profileState) {
                    return AppBottomBar(
                      activeTab: _tabForIndex(tabState.activeIndex),
                      selectedGameId: selectedGameId,
                      profileAvatarUrl: profileState.data.avatarUrl,
                      onTabSelected: (AppBottomTab tab) {
                        final nextIndex = _indexForTab(tab);
                        context.read<MainTabBloc>().add(
                          MainTabIndexChanged(index: nextIndex),
                        );
                        _animateToIndex(nextIndex);
                      },
                      onCenterActionPressed: () {
                        final nextIndex = _indexForTab(AppBottomTab.create);
                        context.read<MainTabBloc>().add(
                          MainTabIndexChanged(index: nextIndex),
                        );
                        _animateToIndex(nextIndex);
                      },
                    );
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

            return BlocBuilder<MainTabBloc, MainTabState>(
              builder: (BuildContext context, MainTabState tabState) {
                final activeIndex = tabState.activeIndex;
                return PageView.builder(
                  controller: _pageController,
                  itemCount: 5,
                  onPageChanged: (int pageIndex) {
                    context.read<MainTabBloc>().add(
                      MainTabIndexChanged(index: pageIndex),
                    );
                  },
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return HomeScreen(
                        key: ValueKey<String>('home-tab-$selectedGameId'),
                        selectedGameId: selectedGameId,
                        showBackButton: false,
                        isActive: activeIndex == 0,
                      );
                    }

                    if (index == 1) {
                      return const GameSelectionScreen(showBackButton: false);
                    }

                    if (index == 2) {
                      return CreatePartyScreen(
                        key: ValueKey<String>('create-tab-$selectedGameId'),
                        gameId: selectedGameId,
                        showBackButton: false,
                      );
                    }

                    if (index == 3) {
                      return const MyRoomsScreen(showBackButton: false);
                    }

                    return const ProfileScreen(showBackButton: false);
                  },
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
