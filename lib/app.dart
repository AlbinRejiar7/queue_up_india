import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection_container.dart';
import 'core/network/network_status_cubit.dart';
import 'core/navigation/bloc/main_tab_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/availability_lifecycle_handler.dart';
import 'core/widgets/app_update_prompt_gate.dart';
import 'core/widgets/network_status_snack_listener.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/chat/bloc/chat_badge_bloc.dart';
import 'features/game_selection/bloc/game_bloc.dart';
import 'features/home/bloc/available_players_bloc.dart';
import 'features/home/bloc/home_availability_bloc.dart';
import 'features/party/bloc/party_bloc.dart';
import 'features/settings/bloc/language_bloc.dart';
import 'features/settings/bloc/profile_bloc.dart';

class QueueUpApp extends StatelessWidget {
  const QueueUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<MainTabBloc>(create: (_) => sl<MainTabBloc>()),
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<LanguageBloc>(create: (_) => sl<LanguageBloc>()),
        BlocProvider<ProfileBloc>(create: (_) => sl<ProfileBloc>()),
        BlocProvider<GameBloc>(create: (_) => sl<GameBloc>()),
        BlocProvider<PartyBloc>(create: (_) => sl<PartyBloc>()),
        BlocProvider<HomeAvailabilityBloc>(
          create: (_) => sl<HomeAvailabilityBloc>(),
        ),
        BlocProvider<AvailablePlayersBloc>(
          create: (_) => sl<AvailablePlayersBloc>(),
        ),
        BlocProvider<ChatBadgeBloc>(create: (_) => sl<ChatBadgeBloc>()),
        BlocProvider<NetworkStatusCubit>(
          create: (_) => sl<NetworkStatusCubit>(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return AvailabilityLifecycleHandler(
            child: MaterialApp.router(
              title: 'QueueUp',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              routerConfig: sl<GoRouter>(),
              builder: (context, child) {
                return AppUpdatePromptGate(
                  child: NetworkStatusSnackListener(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
