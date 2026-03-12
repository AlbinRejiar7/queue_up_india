import '../../auth/models/user_model.dart';
import '../data/repositories/party_repository.dart';
import '../models/create_party_form_model.dart';
import '../models/party_model.dart';
import '../models/party_player_model.dart';
import '../../../core/utils/paged_result.dart';

class PartyViewModel {
  PartyViewModel({required PartyRepository partyRepository})
    : _partyRepository = partyRepository;

  final PartyRepository _partyRepository;

  Future<String?> getCurrentPartyId() {
    return _partyRepository.fetchCurrentPartyId();
  }

  Future<List<PartyModel>> loadParties(String gameId) {
    return _partyRepository.fetchParties(gameId: gameId);
  }

  Future<PagedResult<PartyModel>> loadPartiesPage({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
    Object? cursor,
    int limit = 10,
  }) {
    return _partyRepository.fetchPartiesPage(
      gameId: gameId,
      rankFilter: rankFilter,
      languageFilter: languageFilter,
      cursor: cursor,
      limit: limit,
    );
  }

  Stream<PagedResult<PartyModel>> watchPartiesPage({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
    int limit = 10,
  }) {
    return _partyRepository.watchPartiesPage(
      gameId: gameId,
      rankFilter: rankFilter,
      languageFilter: languageFilter,
      limit: limit,
    );
  }

  Future<List<PartyModel>> loadCreatedParties() {
    return _partyRepository.fetchCreatedParties();
  }

  Future<List<PartyModel>> loadJoinedParties() {
    return _partyRepository.fetchJoinedParties();
  }

  Future<PartyModel> loadPartyDetails(String partyId) {
    return _partyRepository.fetchPartyDetails(partyId: partyId);
  }

  Stream<List<PartyPlayerModel>> watchPartyMembers(String partyId) {
    return _partyRepository.watchPartyMembers(partyId: partyId);
  }

  Future<PartyModel> createParty({
    required String gameId,
    required CreatePartyFormModel form,
  }) {
    return _partyRepository.createParty(gameId: gameId, form: form);
  }

  Future<PartyModel> joinParty({
    required String partyId,
    required UserModel user,
  }) {
    return _partyRepository.joinParty(partyId: partyId, user: user);
  }

  Future<PartyModel> kickPlayer({
    required String partyId,
    required String playerId,
  }) {
    return _partyRepository.kickPlayer(
      partyId: partyId,
      playerId: playerId,
    );
  }

  Future<void> leaveParty(String partyId) {
    return _partyRepository.leaveParty(partyId: partyId);
  }
}
