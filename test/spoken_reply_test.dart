import 'package:einundzwanzig_meetup_app/services/voice_wallet/spoken_reply.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('null Sats ohne Tausenderpunkt', () {
    expect(spokenReply(amount: 0), '0 Sats');
    expect(spokenReply(amount: 1000), '1000 Sats');
    expect(spokenReply(amount: 1000), isNot(contains('.')));
  });

  test('Satz dazu, Token nicht', () {
    expect(
      spokenReply(amount: 21, sentence: 'Eingelöst. Stand 30.'),
      '21 Sats. Eingelöst. Stand 30.',
    );
    expect(
      spokenReply(amount: 4, sentence: 'cashuBgeheim'),
      '4 Sats',
    );
    expect(spokenReply(sentence: 'ur:bytes/1-2/abcd'), isNull);
    expect(spokenReply(sentence: 'Kein Cashu-Code im Bild.'), 'Kein Cashu-Code im Bild.');
  });
}
