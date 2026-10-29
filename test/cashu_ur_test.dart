import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur/bc_ur.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_ur.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const token =
      'cashuAeyJ0b2tlbiI6W3sibWludCI6Imh0dHA6Ly9sb2NhbGhvc3QifV19';

  test('ein wechselnder QR setzt den Token wieder zusammen', () {
    final ur = BCUR.fromData('bytes', Uint8List.fromList(utf8.encode(token)));
    final encoder = BCURFountainEncoder(ur, maxFragmentLength: 30);
    final collector = CashuUrCollector();
    String? got;
    for (var i = 0; i < 40 && got == null; i++) {
      final part = encoder.nextPart().toUpperCase();
      got = collector.add('schau $part bitte');
      if (got == null) expect(collector.expected, greaterThan(0));
    }
    expect(got, token);
  });

  test('ein einzelner ur-Code gilt sofort', () {
    final ur = BCUR.fromData('bytes', Uint8List.fromList(utf8.encode(token)));
    expect(CashuUrCollector().add(ur.toString()), token);
  });

  test('ein feststehender Cashu-Text ist kein ur-Teil', () {
    expect(urPart(token), isNull);
    expect(CashuUrCollector().add(token), isNull);
  });
}
