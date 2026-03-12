import '../../../auth/models/user_model.dart';
import '../../models/create_party_form_model.dart';
import '../../models/party_model.dart';

abstract class PartyRepository {
  Future<String?> fetchCurrentPartyId();

  Future<List<PartyModel>> fetchParties({required String gameId});

  Future<List<PartyModel>> fetchCreatedParties();

  Future<List<PartyModel>> fetchJoinedParties();

  Future<PartyModel> fetchPartyDetails({required String partyId});

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
