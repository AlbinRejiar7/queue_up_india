import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/registration_bloc.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/viewmodel/auth_view_model.dart';
import '../../features/auth/viewmodel/registration_view_model.dart';
import '../../features/game_selection/bloc/game_bloc.dart';
import '../../features/game_selection/data/repositories/game_repository.dart';
import '../../features/game_selection/data/repositories/mock_game_repository.dart';
import '../../features/game_selection/viewmodel/game_view_model.dart';
import '../../features/home/bloc/available_players_bloc.dart';
import '../../features/home/bloc/home_availability_bloc.dart';
import '../../features/party/bloc/party_bloc.dart';
import '../../features/party/data/repositories/mock_party_repository.dart';
import '../../features/party/data/repositories/party_repository.dart';
import '../../features/party/viewmodel/party_view_model.dart';
import '../../features/settings/bloc/language_bloc.dart';
import '../../features/settings/bloc/profile_bloc.dart';
import '../../features/settings/data/repositories/mock_settings_repository.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../../features/settings/viewmodel/language_view_model.dart';
import '../../features/settings/viewmodel/profile_view_model.dart';
import '../navigation/bloc/main_tab_bloc.dart';
import '../navigation/app_router.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  _registerRepositories();
  _registerViewModels();
  _registerBlocs();

  sl.registerLazySingleton<GoRouter>(AppRouter.createRouter);
}

void _registerRepositories() {
  sl.registerLazySingleton<AuthRepository>(MockAuthRepository.new);
  sl.registerLazySingleton<GameRepository>(MockGameRepository.new);
  sl.registerLazySingleton<PartyRepository>(MockPartyRepository.new);
  sl.registerLazySingleton<SettingsRepository>(MockSettingsRepository.new);
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
}

void _registerBlocs() {
  sl.registerFactory<MainTabBloc>(MainTabBloc.new);
  sl.registerFactory<HomeAvailabilityBloc>(HomeAvailabilityBloc.new);
  sl.registerFactory<AvailablePlayersBloc>(AvailablePlayersBloc.new);
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(authViewModel: sl<AuthViewModel>()),
  );
  sl.registerFactory<RegistrationBloc>(
    () => RegistrationBloc(
      registrationViewModel: sl<RegistrationViewModel>(),
    ),
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
}
