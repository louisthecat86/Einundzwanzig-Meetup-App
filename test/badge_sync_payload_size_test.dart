import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_codec.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_format.dart';
import 'package:einundzwanzig_meetup_app/services/nip44.dart';

void main() {
  test('32 komprimierte Bytes ergeben nach Base64 und NIP-44 176 Zeichen', () {
    expect(BadgeSyncFormat.payloadCharsForGzip(32), 176);
  });

  test('Größenberechnung entspricht NIP-44 an Base64- und Padding-Grenzen', () {
    final key = Uint8List(32);
    for (final length in [
      1,
      21,
      23,
      24,
      25,
      31,
      32,
      33,
      47,
      48,
      49,
      95,
      96,
      97,
      191,
      192,
      193,
      511,
      767,
      768,
      769,
      819,
      1500,
      1535,
      1536,
      1537,
      9000,
      16383,
      16384,
      16385,
      40000,
    ]) {
      final compressed = Uint8List(length);
      final payload = Nip44.encrypt(base64Encode(compressed), key);
      expect(
        BadgeSyncFormat.payloadCharsForGzip(length),
        payload.length,
        reason: 'Komprimierte Länge: $length Bytes',
      );
    }
  });

  test('Größenberechnung stimmt für tatsächlich komprimierte UTF-8-Daten', () {
    final random = Random(21);
    final fixtures = [
      jsonEncode({'meetup': 'München', 'notiz': 'Grüße 👋'}),
      jsonEncode({'meetup': 'Köln', 'notiz': 'ÄÖÜ ß 🚀 ' * 200}),
      jsonEncode({
        'meetup': 'Würzburg',
        'testdaten': List.generate(
          2048,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join(),
      }),
    ];
    for (final plain in fixtures) {
      final compressed = BadgeSyncCodec.deflate(plain);
      final key = Uint8List(32);
      final payload = Nip44.encrypt(base64Encode(compressed), key);
      expect(
        BadgeSyncFormat.payloadCharsForGzip(compressed.length),
        payload.length,
      );
      expect(
        BadgeSyncCodec.inflate(base64Decode(Nip44.decrypt(payload, key))),
        plain,
      );
    }
  });
}
