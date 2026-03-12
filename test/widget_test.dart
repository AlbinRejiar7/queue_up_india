import 'package:flutter_test/flutter_test.dart';
import 'package:queue_up_india/features/party/models/create_party_form_model.dart';

void main() {
  test('create party form validates required fields', () {
    const empty = CreatePartyFormModel();
    expect(empty.isValid, isFalse);

    const valid = CreatePartyFormModel(
      partyName: 'Rank Push',
      rank: 'Gold / Plat',
      language: 'English',
      partyCode: 'ABCD-1234',
    );
    expect(valid.isValid, isTrue);
  });
}
