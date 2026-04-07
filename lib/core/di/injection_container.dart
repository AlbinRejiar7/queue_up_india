import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/registration_bloc.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/chat/data/local/direct_chat_cache_store.dart';
import '../../features/chat/data/repositories/firestore_chat_repository.dart';
import '../../features/chat/bloc/chat_badge_bloc.dart';
import '../../features/chat/viewmodel/chat_view_model.dart';
import '../../features/auth/viewmodel/auth_view_model.dart';
import '../../features/auth/viewmodel/registration_view_model.dart';
import '../../features/game_selection/bloc/game_bloc.dart';
import '../../features/game_selection/data/repositories/game_repository.dart';
import '../../features/game_selection/data/repositories/firestore_game_repository.dart';
import '../../features/game_selection/viewmodel/game_view_model.dart';
import '../../features/home/bloc/available_players_bloc.dart';
import '../../features/home/bloc/home_availability_bloc.dart';
import '../../features/home/data/repositories/availability_repository.dart';
import '../../features/home/data/repositories/firestore_availability_repository.dart';
import '../../features/home/viewmodel/availability_view_model.dart';
import '../../features/home/viewmodel/available_players_view_model.dart';
import '../../features/matchmaking/bloc/matchmaking_bloc.dart';
import '../../features/matchmaking/data/repositories/firestore_matchmaking_repository.dart';
import '../../features/matchmaking/data/repositories/matchmaking_repository.dart';
import '../../features/matchmaking/viewmodel/matchmaking_view_model.dart';
import '../../features/notifications/bloc/notifications_bloc.dart';
import '../../features/notifications/data/repositories/firestore_notifications_repository.dart';
import '../../features/notifications/data/repositories/notifications_repository.dart';
import '../../features/notifications/viewmodel/notifications_view_model.dart';
import '../../features/party/bloc/party_bloc.dart';
import '../../features/party/data/repositories/firestore_party_repository.dart';
import '../../features/party/data/repositories/party_repository.dart';
import '../../features/party/viewmodel/party_view_model.dart';
import '../../features/settings/bloc/language_bloc.dart';
import '../../features/settings/bloc/profile_bloc.dart';
import '../../features/settings/data/repositories/firestore_settings_repository.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/settings/viewmodel/language_view_model.dart';
import '../../features/settings/viewmodel/profile_view_model.dart';
import '../network/network_status_cubit.dart';
import '../navigation/bloc/main_tab_bloc.dart';
import '../navigation/app_router.dart';
import '../services/app_update_service.dart';
import '../services/activity_pulse_service.dart';
import '../services/direct_chat_monitor_service.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  _registerRepositories();
  _registerViewModels();
  _registerBlocs();
}

void registerRouter({String initialLocation = AppRoutes.splash}) {
  if (sl.isRegistered<GoRouter>()) {
    sl.unregister<GoRouter>();
  }
  sl.registerLazySingleton<GoRouter>(
    () => AppRouter.createRouter(initialLocation: initialLocation),
  );
}

void _registerRepositories() {
  sl.registerLazySingleton<AuthRepository>(FirebaseAuthRepository.new);
  sl.registerLazySingleton<GameRepository>(FirestoreGameRepository.new);
  sl.registerLazySingleton<PartyRepository>(FirestorePartyRepository.new);
  sl.registerLazySingleton<SettingsRepository>(FirestoreSettingsRepository.new);
  sl.registerLazySingleton<AvailabilityRepository>(
    FirestoreAvailabilityRepository.new,
  );
  sl.registerLazySingleton<DirectChatCacheStore>(DirectChatCacheStore.new);
  sl.registerLazySingleton<DirectChatMonitorService>(
    DirectChatMonitorService.new,
  );
  sl.registerLazySingleton<ChatRepository>(
    () => FirestoreChatRepository(
      directChatCacheStore: sl<DirectChatCacheStore>(),
    ),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    FirestoreNotificationsRepository.new,
  );
  sl.registerLazySingleton<MatchmakingRepository>(
    FirestoreMatchmakingRepository.new,
  );
  sl.registerLazySingleton<ActivityPulseService>(ActivityPulseService.new);
  sl.registerLazySingleton<AppUpdateService>(AppUpdateService.new);
  sl.registerLazySingleton<Connectivity>(Connectivity.new);
}

void _registerViewModels() {
  sl.registerFactory<AuthViewModel>(
    () => AuthViewModel(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<RegistrationViewModel>(
    () => RegistrationViewModel(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<GameViewModel>(
    () => GameViewModel(gameRepository: sl<GameRepository>()),
  );
  sl.registerFactory<PartyViewModel>(
    () => PartyViewModel(partyRepository: sl<PartyRepository>()),
  );
  sl.registerFactory<LanguageViewModel>(
    () => LanguageViewModel(settingsRepository: sl<SettingsRepository>()),
  );
  sl.registerFactory<ProfileViewModel>(
    () => ProfileViewModel(settingsRepository: sl<SettingsRepository>()),
  );
  sl.registerFactory<AvailabilityViewModel>(
    () => AvailabilityViewModel(repository: sl<AvailabilityRepository>()),
  );
  sl.registerFactory<AvailablePlayersViewModel>(
    () => AvailablePlayersViewModel(repository: sl<AvailabilityRepository>()),
  );
  sl.registerFactory<ChatViewModel>(
    () => ChatViewModel(repository: sl<ChatRepository>()),
  );
  sl.registerFactory<NotificationsViewModel>(
    () => NotificationsViewModel(repository: sl<NotificationsRepository>()),
  );
  sl.registerFactory<MatchmakingViewModel>(
    () => MatchmakingViewModel(repository: sl<MatchmakingRepository>()),
  );
}

void _registerBlocs() {
  sl.registerFactory<MainTabBloc>(MainTabBloc.new);
  sl.registerFactory<HomeAvailabilityBloc>(
    () => HomeAvailabilityBloc(
      availabilityViewModel: sl<AvailabilityViewModel>(),
      profileViewModel: sl<ProfileViewModel>(),
    ),
  );
  sl.registerFactory<AvailablePlayersBloc>(
    () => AvailablePlayersBloc(
      availablePlayersViewModel: sl<AvailablePlayersViewModel>(),
      notificationsViewModel: sl<NotificationsViewModel>(),
      chatViewModel: sl<ChatViewModel>(),
    ),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authViewModel: sl<AuthViewModel>()),
  );
  sl.registerFactory<RegistrationBloc>(
    () => RegistrationBloc(registrationViewModel: sl<RegistrationViewModel>()),
  );
  sl.registerFactory<GameBloc>(
    () => GameBloc(gameViewModel: sl<GameViewModel>()),
  );
  sl.registerFactory<PartyBloc>(
    () => PartyBloc(partyViewModel: sl<PartyViewModel>()),
  );
  sl.registerFactory<LanguageBloc>(
    () => LanguageBloc(languageViewModel: sl<LanguageViewModel>()),
  );
  sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(profileViewModel: sl<ProfileViewModel>()),
  );
  sl.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(
      notificationsViewModel: sl<NotificationsViewModel>(),
      chatViewModel: sl<ChatViewModel>(),
    ),
  );
  sl.registerFactory<ChatBadgeBloc>(
    () =>
        ChatBadgeBloc(directChatMonitorService: sl<DirectChatMonitorService>()),
  );
  sl.registerFactory<NetworkStatusCubit>(
    () => NetworkStatusCubit(connectivity: sl<Connectivity>()),
  );
  sl.registerFactory<MatchmakingBloc>(
    () => MatchmakingBloc(
      matchmakingViewModel: sl<MatchmakingViewModel>(),
      partyViewModel: sl<PartyViewModel>(),
    ),
  );
}
