abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String languageSelection = '/language';
  static const String registration = '/register';
  static const String login = '/login';
  static const String home = '/home';
  static const String availablePlayers = '/available-players';
  static const String chatHistory = '/chat-history';
  static const String playerChat = '/player-chat';
  static const String notifications = '/notifications';
  static const String gameSelection = '/game-selection';
  static const String rooms = '/rooms';
  static const String partyList = '/party-list';
  static const String createParty = '/create-party';
  static const String partyDetails = '/party-details';
  static const String profile = '/profile';

  static String partyListPath(String gameId) => '$partyList/$gameId';

  static String partyDetailsPath(String partyId) => '$partyDetails/$partyId';

  static String playerChatPath(String playerId) => '$playerChat/$playerId';
}
