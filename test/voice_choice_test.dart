import 'package:einundzwanzig_meetup_app/services/speech/voice_choice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Premium schlaegt die blecherne Compact-Stimme', () {
    final picked = pickPhoneVoice([
      {
        'name': 'Anna',
        'locale': 'de-DE',
        'quality': 'default',
        'identifier': 'com.apple.voice.compact.de-DE.Anna',
      },
      {
        'name': 'Helena',
        'locale': 'de-DE',
        'quality': 'premium',
        'identifier': 'com.apple.voice.premium.de-DE.Helena',
      },
      {
        'name': 'Sandy',
        'locale': 'de-DE',
        'quality': 'premium',
        'identifier': 'com.apple.eloquence.de-DE.Sandy',
      },
    ], 'de-DE');
    expect(picked?.name, 'Helena');
  });

  test('Ohne Premium bleibt die vorhandene Stimme', () {
    final picked = pickPhoneVoice([
      {
        'name': 'Anna',
        'locale': 'de-DE',
        'quality': 'default',
        'identifier': 'com.apple.voice.compact.de-DE.Anna',
      },
    ], 'de-DE');
    expect(picked?.name, 'Anna');
  });
}
