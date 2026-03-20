import '../../../../core/constants/app_images.dart';
import '../../../../core/constants/app_options.dart';
import '../../../../core/utils/paged_result.dart';
import '../../../auth/models/user_model.dart';
import '../../models/create_party_form_model.dart';
import '../../models/party_model.dart';
import '../../models/party_player_model.dart';
import 'party_repository.dart';

class MockPartyRepository implements PartyRepository {
  static const String _hostUserId = 'u_001';
  static const String _joinedUserId = 'u_joined_001';

  MockPartyRepository() {
    _parties = <PartyModel>[
      PartyModel(
        id: 'party_101',
        name: 'Mumbai Radiant Grind',
        gameId: AppOptions.valorantId,
        rank: 'Ascendant 2',
        language: 'Hindi',
        maxPlayers: 5,
        players: <PartyPlayerModel>[
          const PartyPlayerModel(
            id: 'u_001',
            name: 'ShadowPlayer',
            avatarUrl: AppImages.avatarHost,
            status: 'Host',
            isHost: true,
          ),
          const PartyPlayerModel(
            id: 'u_002',
            name: 'LunaVibe',
            avatarUrl: AppImages.avatarOne,
            status: 'Ready',
          ),
          const PartyPlayerModel(
            id: 'u_003',
            name: 'CyberPunk_01',
            avatarUrl: AppImages.avatarTwo,
            status: 'In Lobby',
            isMuted: true,
          ),
        ],
        partyCode: 'AX7-92B',
        createdAt: DateTime(2026, 03, 01),
        coverImageUrl: AppImages.valorant,
        hostId: _hostUserId,
        hostDisplayName: 'ShadowPlayer',
        logoImageUrl: AppImages.valorant,
        tags: <String>['Mic On', 'India Server'],
      ),
      PartyModel(
        id: 'party_102',
        name: 'Delhi Competitive Push',
        gameId: AppOptions.valorantId,
        rank: 'Diamond 1',
        language: 'English',
        maxPlayers: 5,
        players: <PartyPlayerModel>[
          const PartyPlayerModel(
            id: 'u_011',
            name: 'FrostNova',
            avatarUrl: AppImages.avatarHost,
            status: 'Host',
            isHost: true,
          ),
          const PartyPlayerModel(
            id: 'u_012',
            name: 'LunaVibe',
            avatarUrl: AppImages.avatarOne,
            status: 'Ready',
          ),
        ],
        partyCode: 'GOLD-527',
        createdAt: DateTime(2026, 03, 01),
        coverImageUrl: AppImages.valorant,
        hostId: 'u_011',
        hostDisplayName: 'FrostNova',
        logoImageUrl: AppImages.valorant,
        tags: <String>[],
      ),
      PartyModel(
        id: 'party_103',
        name: 'Need Sentinel Main',
        gameId: AppOptions.valorantId,
        rank: 'Platinum 3',
        language: 'English',
        maxPlayers: 5,
        players: <PartyPlayerModel>[
          const PartyPlayerModel(
            id: 'u_021',
            name: 'ClutchKing',
            avatarUrl: AppImages.avatarHost,
            status: 'Host',
            isHost: true,
          ),
          const PartyPlayerModel(
            id: 'u_022',
            name: 'SageMain',
            avatarUrl: AppImages.avatarOne,
            status: 'Ready',
          ),
          const PartyPlayerModel(
            id: 'u_023',
            name: 'RushB',
            avatarUrl: AppImages.avatarTwo,
            status: 'Ready',
          ),
          const PartyPlayerModel(
            id: 'u_024',
            name: 'VisionLock',
            avatarUrl: AppImages.avatarHost,
            status: 'Ready',
          ),
        ],
        partyCode: 'SEA-404',
        createdAt: DateTime(2026, 03, 02),
        coverImageUrl: AppImages.valorant,
        hostId: 'u_021',
        hostDisplayName: 'ClutchKing',
        logoImageUrl: AppImages.valorant,
        tags: <String>[],
      ),
      PartyModel(
        id: 'party_201',
        name: 'BGMI Erangel Push',
        gameId: AppOptions.pubgId,
        rank: 'Ace',
        language: 'Hindi',
        maxPlayers: 4,
        players: <PartyPlayerModel>[
          const PartyPlayerModel(
            id: 'u_031',
            name: 'BattleBoi',
            avatarUrl: AppImages.avatarHost,
            status: 'Host',
            isHost: true,
          ),
          const PartyPlayerModel(
            id: 'u_032',
            name: 'RushMitra',
            avatarUrl: AppImages.avatarOne,
            status: 'Ready',
          ),
          const PartyPlayerModel(
            id: _joinedUserId,
            name: 'QueuePlayer',
            avatarUrl: AppImages.avatarTwo,
            status: 'Joined',
          ),
        ],
        partyCode: 'BGMI-919',
        createdAt: DateTime(2026, 03, 02),
        coverImageUrl: AppImages.pubg,
        hostId: 'u_031',
        hostDisplayName: 'BattleBoi',
        logoImageUrl: AppImages.pubg,
        tags: <String>['Classic', 'India'],
      ),
    ];
  }

  late List<PartyModel> _parties;
  String? _currentPartyId;

  @override
  Future<PartyModel> createParty({
    required String gameId,
    required CreatePartyFormModel form,
  }) async {
    // TODO: Implement Firestore query here
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final id = 'party_${DateTime.now().millisecondsSinceEpoch}';
    final code = form.partyCode.trim();
    if (code.isEmpty) {
      throw StateError('Party code is required');
    }

    final created = PartyModel(
      id: id,
      name: form.partyName.trim(),
      gameId: gameId,
      rank: form.rank ?? AppOptions.defaultRankForGame(gameId).name,
      language: form.language ?? 'Hindi',
      maxPlayers: form.maxPlayers,
      players: const <PartyPlayerModel>[
        PartyPlayerModel(
          id: _hostUserId,
          name: 'ShadowPlayer',
          avatarUrl: AppImages.avatarHost,
          status: 'Host',
          isHost: true,
        ),
      ],
      partyCode: code,
      createdAt: DateTime.now(),
      coverImageUrl: _logoForGame(gameId),
      hostId: _hostUserId,
      hostDisplayName: 'ShadowPlayer',
      logoImageUrl: _logoForGame(gameId),
      tags: const <String>['New'],
    );

    _parties = <PartyModel>[created, ..._parties];
    _currentPartyId = created.id;
    return created;
  }

  @override
  Future<String?> fetchCurrentPartyId() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _currentPartyId;
  }

  @override
  Future<PartyModel> fetchPartyDetails({required String partyId}) async {
    // TODO: Implement Firestore query here
    await Future<void>.delayed(const Duration(milliseconds: 420));
    return _parties.firstWhere((PartyModel party) => party.id == partyId);
  }

  @override
  Stream<List<PartyPlayerModel>> watchPartyMembers({
    required String partyId,
  }) {
    final party = _parties.firstWhere((party) => party.id == partyId);
    return Stream<List<PartyPlayerModel>>.value(party.players);
  }

  @override
  Future<List<PartyModel>> fetchParties({required String gameId}) async {
    // TODO: Implement Firestore query here
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final page = await fetchPartiesPage(gameId: gameId, limit: 50);
    return page.items;
  }

  @override
  Future<PagedResult<PartyModel>> fetchPartiesPage({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
    Object? cursor,
    int limit = 10,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final normalizedRank = rankFilter?.toLowerCase();
    final normalizedLanguage = languageFilter?.toLowerCase();
    final filtered = _parties
        .where((PartyModel party) => party.gameId == gameId)
        .where(
          (PartyModel party) =>
              normalizedRank == null ||
              normalizedRank.isEmpty ||
              party.rank.toLowerCase() == normalizedRank,
        )
        .where(
          (PartyModel party) =>
              normalizedLanguage == null ||
              normalizedLanguage.isEmpty ||
              party.language.toLowerCase() == normalizedLanguage,
        )
        .toList();

    final int startIndex = cursor is int ? cursor : 0;
    final slice = filtered.skip(startIndex).take(limit).toList();
    final nextIndex = startIndex + slice.length;
    final hasMore = nextIndex < filtered.length;

    return PagedResult<PartyModel>(
      items: slice,
      hasMore: hasMore,
      nextCursor: hasMore ? nextIndex : null,
    );
  }

  @override
  Stream<PagedResult<PartyModel>> watchPartiesPage({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
    int limit = 10,
  }) {
    return Stream.fromFuture(
      fetchPartiesPage(
        gameId: gameId,
        rankFilter: rankFilter,
        languageFilter: languageFilter,
        limit: limit,
      ),
    );
  }

  @override
  Future<List<PartyModel>> fetchCreatedParties() async {
    // TODO: Implement Firestore query here
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return _parties
        .where(
          (PartyModel party) =>
              party.players.isNotEmpty &&
              party.players.first.isHost &&
              party.players.first.id == _hostUserId,
        )
        .toList();
  }

  @override
  Future<List<PartyModel>> fetchJoinedParties() async {
    // TODO: Implement Firestore query here
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return _parties
        .where(
          (PartyModel party) => party.players.any(
            (PartyPlayerModel player) =>
                player.id == _joinedUserId && !player.isHost,
          ),
        )
        .toList();
  }

  @override
  Future<PartyModel> joinParty({
    required String partyId,
    required UserModel user,
  }) async {
    // TODO: Implement transaction-safe join logic here
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final int index = _parties.indexWhere(
      (PartyModel party) => party.id == partyId,
    );
    if (index < 0) {
      throw StateError('Party not found');
    }

    final party = _parties[index];
    if (party.isFull) {
      return party;
    }

    final exists = party.players.any((PartyPlayerModel p) => p.id == user.id);
    final updatedPlayers = exists
        ? party.players
        : <PartyPlayerModel>[
            ...party.players,
            PartyPlayerModel(
              id: user.id,
              name: user.displayName,
              avatarUrl: user.avatarUrl ?? AppImages.avatarHost,
              status: 'Ready',
            ),
          ];

    final updatedParty = party.copyWith(players: updatedPlayers);
    _parties[index] = updatedParty;
    _currentPartyId = updatedParty.id;
    return updatedParty;
  }

  @override
  Future<PartyModel> kickPlayer({
    required String partyId,
    required String playerId,
  }) async {
    // TODO: Implement transaction-safe kick logic here
    await Future<void>.delayed(const Duration(milliseconds: 280));

    final int index = _parties.indexWhere(
      (PartyModel party) => party.id == partyId,
    );
    if (index < 0) {
      throw StateError('Party not found');
    }

    final party = _parties[index];
    final updatedPlayers = party.players
        .where(
          (PartyPlayerModel player) => player.id != playerId || player.isHost,
        )
        .toList();
    final updatedParty = party.copyWith(players: updatedPlayers);
    _parties[index] = updatedParty;
    return updatedParty;
  }

  @override
  Future<void> leaveParty({required String partyId}) async {
    // TODO: Implement Firestore query here
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final int index = _parties.indexWhere(
      (PartyModel party) => party.id == partyId,
    );
    if (index >= 0) {
      final party = _parties[index];
      _parties[index] = party.copyWith(
        players: party.players
            .where((PartyPlayerModel player) => player.id != _joinedUserId)
            .toList(),
      );
    }
    if (_currentPartyId == partyId) {
      _currentPartyId = null;
    }
  }

  String _logoForGame(String gameId) {
    if (gameId == AppOptions.pubgId) {
      return AppImages.pubg;
    }
    if (gameId == AppOptions.freeFireId) {
      return AppImages.freeFire;
    }
    return AppImages.valorant;
  }
}
