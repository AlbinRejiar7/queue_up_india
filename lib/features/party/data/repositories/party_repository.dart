import '../../../auth/models/user_model.dart';
import '../../models/create_party_form_model.dart';
import '../../models/party_model.dart';
import '../../models/party_player_model.dart';
import '../../../../core/utils/paged_result.dart';

abstract class PartyRepository {
  Future<String?> fetchCurrentPartyId();

  Future<List<PartyModel>> fetchParties({required String gameId});

  Future<PagedResult<PartyModel>> fetchPartiesPage({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
    Object? cursor,
    int limit = 10,
  });

  Stream<PagedResult<PartyModel>> watchPartiesPage({
    required String gameId,
    String? rankFilter,
    String? languageFilter,
    int limit = 10,
  });

  Future<List<PartyModel>> fetchCreatedParties();

  Future<List<PartyModel>> fetchJoinedParties();

  Future<PartyModel> fetchPartyDetails({required String partyId});

  Stream<List<PartyPlayerModel>> watchPartyMembers({
    required String partyId,
  });

  Future<PartyModel> createParty({
    required String gameId,
    required CreatePartyFormModel form,
  });

  Future<PartyModel> joinParty({
    required String partyId,
    required UserModel user,
  });

  Future<PartyModel> kickPlayer({
    required String partyId,
    required String playerId,
  });

  Future<void> leaveParty({required String partyId});
}
