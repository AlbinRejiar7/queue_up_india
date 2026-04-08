import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/registration_bloc.dart';
import '../../features/auth/bloc/registration_event.dart';
import '../../features/auth/bloc/registration_state.dart';
import '../../features/auth/presentation/view/login_screen.dart';
import '../../features/auth/presentation/view/registration_screen.dart';
import '../../features/auth/presentation/view/splash_screen.dart';
import '../../features/chat/presentation/view/chat_history_screen.dart';
import '../../features/chat/presentation/view/player_chat_screen.dart';
import '../../features/home/presentation/view/available_players_screen.dart';
import '../../features/home/models/available_player_model.dart';
import '../../features/matchmaking/bloc/matchmaking_bloc.dart';
import '../../features/matchmaking/presentation/view/solo_matchmaking_screen.dart';
import '../../features/notifications/presentation/view/notification_center_screen.dart';
import '../../features/party/presentation/view/party_details_screen.dart';
import '../../features/party/presentation/view/party_list_screen.dart';
import '../../features/settings/presentation/view/language_selection_screen.dart';
import '../constants/app_options.dart';
import '../constants/app_images.dart';
import '../constants/app_routes.dart';
import '../di/injection_container.dart';
import '../widgets/app_bottom_bar.dart';
import 'main_tab_shell_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract final class AppRouter {
  static GoRouter createRouter({String initialLocation = AppRoutes.splash}) {
    return GoRouter(
      initialLocation: initialLocation,
      redirect: (context, state) async {
        if (state.matchedLocation == '/') {
          return initialLocation;
        }
        return null;
      },
      routes: <RouteBase>[
        GoRoute(path: '/', redirect: (_, state) => AppRoutes.splash),
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.languageSelection,
          builder: (_, state) => const LanguageSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.registration,
          builder: (_, state) => BlocProvider<RegistrationBloc>(
            create: (_) => sl<RegistrationBloc>()
              ..add(
                const RegistrationModeChanged(mode: RegistrationMode.register),
              ),
            child: const RegistrationScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, state) => BlocProvider<RegistrationBloc>(
            create: (_) => sl<RegistrationBloc>()
              ..add(
                const RegistrationModeChanged(mode: RegistrationMode.login),
              ),
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.gameSelection,
          builder: (_, state) =>
              const MainTabShellScreen(initialTab: AppBottomTab.games),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, state) =>
              const MainTabShellScreen(initialTab: AppBottomTab.home),
        ),
        GoRoute(
          path: AppRoutes.availablePlayers,
          builder: (_, state) => const AvailablePlayersScreen(),
        ),
        GoRoute(
          path: AppRoutes.chatHistory,
          builder: (_, state) => const ChatHistoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (_, state) => const NotificationCenterScreen(),
        ),
        GoRoute(
          path: '${AppRoutes.playerChat}/:playerId',
          builder: (_, GoRouterState state) {
            final player = state.extra as AvailablePlayerModel?;
            final fallback = AvailablePlayerModel(
              id: state.pathParameters['playerId'] ?? '',
              name: 'Player',
              avatarUrl: AppImages.avatarHost,
              gameId: AppOptions.valorantId,
              rank: AppOptions.valorantRankOptions.first.name,
              language: AppOptions.languageOptions.first,
              availableSince: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            return PlayerChatScreen(player: player ?? fallback);
          },
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) =>
              const MainTabShellScreen(initialTab: AppBottomTab.profile),
        ),
        GoRoute(
          path: AppRoutes.rooms,
          builder: (_, _) =>
              const MainTabShellScreen(initialTab: AppBottomTab.rooms),
        ),
        GoRoute(
          path: '${AppRoutes.partyList}/:gameId',
          builder: (_, GoRouterState state) {
            return PartyListScreen(
              gameId: state.pathParameters['gameId'] ?? AppOptions.valorantId,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.createParty,
          builder: (_, GoRouterState state) {
            return MainTabShellScreen(
              initialTab: AppBottomTab.create,
              initialGameId:
                  state.uri.queryParameters['gameId'] ?? AppOptions.valorantId,
            );
          },
        ),
        GoRoute(
          path: '${AppRoutes.partyDetails}/:partyId',
          builder: (_, GoRouterState state) {
            return PartyDetailsScreen(
              partyId: state.pathParameters['partyId'] ?? '',
            );
          },
        ),
        GoRoute(
          path: AppRoutes.soloMatchmaking,
          builder: (_, GoRouterState state) {
            final gameId =
                state.uri.queryParameters['gameId'] ?? AppOptions.valorantId;
            final rank = state.uri.queryParameters['rank'];
            final language = state.uri.queryParameters['language'];
            final autoStart = state.uri.queryParameters['autoStart'] == 'true';
            return BlocProvider<MatchmakingBloc>(
              create: (_) => sl<MatchmakingBloc>(),
              child: SoloMatchmakingScreen(
                gameId: gameId,
                initialRank: rank,
                initialLanguage: language,
                autoStart: autoStart,
              ),
            );
          },
        ),
      ],
    );
  }
}
