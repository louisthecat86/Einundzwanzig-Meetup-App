// ============================================
// UNIT TESTS: BadgeSecurity
// ============================================
// Testet die kryptographischen Kernfunktionen:
//   - Pubkey/Signatur-Validierung
//   - JSON-Kanonisierung
//   - Legacy v1 Deaktivierung (Security Audit C1)
//   - Kompakt-Signatur-Verifikation (Schnorr/BIP-340)
//   - Unified verify() Routing
//   - Compact → Full Format Normalisierung
//   - Ablauf-Checks
//   - QR-Legacy-Ablehnung
// ============================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:nostr/nostr.dart';
import 'package:einundzwanzig_meetup_app/services/badge_security.dart';

void main() {
  // =============================================
  // TEST FIXTURES
  // =============================================
  
  // Deterministischer Test-Keychain (NICHT für Produktion!)
  // Dieser Schlüssel wird NUR für Tests verwendet.
  late Keychain testKeychain;
  late String testPubkeyHex;
  
  setUp(() {
    testKeychain = Keychain.generate();
    testPubkeyHex = testKeychain.public;
  });

  /// Erzeugt einen gültig signierten Kompakt-Payload mit dem Test-Keychain
  Map<String, dynamic> _createValidCompactPayload({
    String meetupId = 'aschaffenburg-de',
    int blockHeight = 875000,
    int? expiresAt,
  }) {
    final int expiry = expiresAt ?? 
        (DateTime.now().millisecondsSinceEpoch ~/ 1000 + 6 * 3600); // +6h

    final content = {
      'v': 2,
      't': 'B',
      'm': meetupId,
      'b': blockHeight,
      'x': expiry,
    };

    final contentJson = BadgeSecurity.canonicalJsonEncode(content);
    final tags = [['t', 'badge'], ['m', meetupId]];

    final event = Event.from(
      kind: 21000,
      tags: tags,
      content: contentJson,
      privkey: testKeychain.private,
    );

    return {
      ...content,
      'c': event.createdAt,
      'p': event.pubkey,
      's': event.sig,
    };
  }

  // =============================================
  // PUBKEY & SIGNATUR VALIDIERUNG
  // =============================================

  group('isValidPubkeyHex', () {
    test('akzeptiert gültigen 64-Zeichen Hex-Pubkey', () {
      expect(BadgeSecurity.isValidPubkeyHex(testPubkeyHex), isTrue);
    });

    test('lehnt zu kurzen Pubkey ab', () {
      expect(BadgeSecurity.isValidPubkeyHex('abcdef1234'), isFalse);
    });

    test('lehnt zu langen Pubkey ab', () {
      expect(BadgeSecurity.isValidPubkeyHex('a' * 65), isFalse);
    });

    test('lehnt Nicht-Hex-Zeichen ab', () {
      expect(BadgeSecurity.isValidPubkeyHex('g' * 64), isFalse);
      expect(BadgeSecurity.isValidPubkeyHex('x' + 'a' * 63), isFalse);
    });

    test('lehnt leeren String ab', () {
      expect(BadgeSecurity.isValidPubkeyHex(''), isFalse);
    });

    test('akzeptiert Großbuchstaben Hex', () {
      expect(BadgeSecurity.isValidPubkeyHex('A' * 64), isTrue);
      expect(BadgeSecurity.isValidPubkeyHex('aAbBcCdDeEfF' * 5 + 'aAbB'), isTrue);
    });
  });

  group('isValidSignatureHex', () {
    test('akzeptiert gültige 128-Zeichen Hex-Signatur', () {
      expect(BadgeSecurity.isValidSignatureHex('a' * 128), isTrue);
    });

    test('lehnt zu kurze Signatur ab', () {
      expect(BadgeSecurity.isValidSignatureHex('a' * 127), isFalse);
    });

    test('lehnt zu lange Signatur ab', () {
      expect(BadgeSecurity.isValidSignatureHex('a' * 129), isFalse);
    });

    test('lehnt Nicht-Hex ab', () {
      expect(BadgeSecurity.isValidSignatureHex('z' * 128), isFalse);
    });
  });

  // =============================================
  // JSON KANONISIERUNG
  // =============================================

  group('canonicalJsonEncode', () {
    test('sortiert Keys alphabetisch', () {
      final result = BadgeSecurity.canonicalJsonEncode({
        'z': 1, 'a': 2, 'm': 3, 'b': 4,
      });
      expect(result, '{"a":2,"b":4,"m":3,"z":1}');
    });

    test('identisches Ergebnis unabhängig von Eingabe-Reihenfolge', () {
      final a = BadgeSecurity.canonicalJsonEncode({'x': 1, 'a': 2, 'c': 3});
      final b = BadgeSecurity.canonicalJsonEncode({'c': 3, 'x': 1, 'a': 2});
      final c = BadgeSecurity.canonicalJsonEncode({'a': 2, 'x': 1, 'c': 3});
      expect(a, equals(b));
      expect(b, equals(c));
    });

    test('leere Map', () {
      expect(BadgeSecurity.canonicalJsonEncode({}), '{}');
    });

    test('behandelt verschachtelte Werte korrekt', () {
      final result = BadgeSecurity.canonicalJsonEncode({
        'b': [1, 2, 3],
        'a': {'nested': true},
      });
      expect(result, '{"a":{"nested":true},"b":[1,2,3]}');
    });
  });

  // =============================================
  // LEGACY v1 DEAKTIVIERUNG (Security Audit C1)
  // =============================================

  group('Legacy v1 — Security Audit C1', () {
    test('signLegacy gibt immer leeren String zurück', () {
      final result = BadgeSecurity.signLegacy('meetup-123', '2025-01-01', 875000);
      expect(result, isEmpty);
    });

    test('verifyLegacy gibt immer false zurück', () {
      expect(BadgeSecurity.verifyLegacy({
        'meetup_id': 'test',
        'timestamp': '2025-01-01',
        'hash': 'fakehash',
      }), isFalse);
    });

    test('verify() lehnt v1 Badges ab mit Upgrade-Hinweis', () {
      final result = BadgeSecurity.verify({
        'v': 1,
        'meetup_id': 'test',
        'timestamp': '2025-01-01',
        'hash': 'anything',
      });
      expect(result.isValid, isFalse);
      expect(result.version, 1);
      expect(result.message, contains('v1'));
      expect(result.message, contains('nicht mehr akzeptiert'));
    });

    test('verify() lehnt auch v0 ab', () {
      final result = BadgeSecurity.verify({
        'meetup_id': 'test',
        'timestamp': '2025-01-01',
      });
      expect(result.isValid, isFalse);
    });
  });

  // =============================================
  // KOMPAKT-SIGNATUR VERIFIKATION (Schnorr/BIP-340)
  // =============================================

  group('verifyCompact — Schnorr-Signaturen', () {
    test('akzeptiert gültig signiertes Kompakt-Badge', () {
      final payload = _createValidCompactPayload();
      final result = BadgeSecurity.verifyCompact(payload);
      
      expect(result.isValid, isTrue);
      expect(result.version, 2);
      expect(result.adminPubkey, testPubkeyHex);
      expect(result.adminNpub, isNotEmpty);
      expect(result.message, contains('gültig'));
    });

    test('lehnt manipierten Meetup-Namen ab', () {
      final payload = _createValidCompactPayload(meetupId: 'aschaffenburg-de');
      payload['m'] = 'manipuliert-de'; // Meetup-ID geändert
      
      final result = BadgeSecurity.verifyCompact(payload);
      expect(result.isValid, isFalse);
    });

    test('lehnt manipierte Blockhöhe ab', () {
      final payload = _createValidCompactPayload(blockHeight: 875000);
      payload['b'] = 999999; // Blockhöhe manipuliert
      
      final result = BadgeSecurity.verifyCompact(payload);
      expect(result.isValid, isFalse);
    });

    test('lehnt manipierten Pubkey ab', () {
      final payload = _createValidCompactPayload();
      final otherKey = Keychain.generate();
      payload['p'] = otherKey.public; // Anderer Pubkey
      
      final result = BadgeSecurity.verifyCompact(payload);
      expect(result.isValid, isFalse);
    });

    test('lehnt manipierte Signatur ab', () {
      final payload = _createValidCompactPayload();
      // Signatur-Bit flippen
      final sigChars = payload['s'].split('');
      sigChars[0] = sigChars[0] == 'a' ? 'b' : 'a';
      payload['s'] = sigChars.join('');
      
      final result = BadgeSecurity.verifyCompact(payload);
      expect(result.isValid, isFalse);
    });

    test('lehnt abgelaufenes Badge ab', () {
      final expired = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600; // 1h her
      final payload = _createValidCompactPayload(expiresAt: expired);
      
      final result = BadgeSecurity.verifyCompact(payload);
      expect(result.isValid, isFalse);
      expect(result.message, contains('abgelaufen'));
    });

    test('lehnt fehlende Signatur ab', () {
      final result = BadgeSecurity.verifyCompact({
        'v': 2, 't': 'B', 'm': 'test-de', 'b': 875000,
        'c': 1700000000, 'p': testPubkeyHex, // 's' fehlt
      });
      expect(result.isValid, isFalse);
      expect(result.message, contains('Fehlende'));
    });

    test('lehnt ungültiges Pubkey-Format ab', () {
      final result = BadgeSecurity.verifyCompact({
        'v': 2, 't': 'B', 'm': 'test-de', 'b': 875000,
        'c': 1700000000, 'p': 'zu_kurz', 's': 'a' * 128,
      });
      expect(result.isValid, isFalse);
      expect(result.message, contains('Pubkey-Format'));
    });

    test('lehnt ungültiges Signatur-Format ab', () {
      final result = BadgeSecurity.verifyCompact({
        'v': 2, 't': 'B', 'm': 'test-de', 'b': 875000,
        'c': 1700000000, 'p': testPubkeyHex, 's': 'kurz',
      });
      expect(result.isValid, isFalse);
      expect(result.message, contains('Signatur-Format'));
    });

    test('Cross-Signing: Signatur von anderem Key wird abgelehnt', () {
      final otherKey = Keychain.generate();
      final content = {'v': 2, 't': 'B', 'm': 'test-de', 'b': 875000, 'x': 9999999999};
      final contentJson = BadgeSecurity.canonicalJsonEncode(content);
      final tags = [['t', 'badge'], ['m', 'test-de']];

      // Mit otherKey signieren
      final event = Event.from(
        kind: 21000, tags: tags, content: contentJson, privkey: otherKey.private,
      );

      // Aber testPubkeyHex als Pubkey angeben
      final payload = {
        ...content,
        'c': event.createdAt,
        'p': testPubkeyHex, // Falscher Pubkey!
        's': event.sig,
      };
      
      final result = BadgeSecurity.verifyCompact(payload);
      expect(result.isValid, isFalse);
    });
  });

  // =============================================
  // UNIFIED VERIFY — Routing
  // =============================================

  group('verify() — Unified Routing', () {
    test('routet Kompakt-Format (p+s) korrekt', () {
      final payload = _createValidCompactPayload();
      final result = BadgeSecurity.verify(payload);
      
      expect(result.isValid, isTrue);
      expect(result.version, 2);
    });

    test('lehnt v1 Legacy ab', () {
      final result = BadgeSecurity.verify({
        'v': 1, 'meetup_id': 'test', 'timestamp': '2025-01-01', 'hash': 'x',
      });
      expect(result.isValid, isFalse);
      expect(result.version, 1);
    });

    test('versucht v2 Legacy-Format (mit sig + admin_pubkey)', () {
      // Ohne korrekte created_at wird verifyNostr fehlschlagen → fail-secure
      final result = BadgeSecurity.verify({
        'v': 2,
        'meetup_id': 'test',
        'admin_pubkey': testPubkeyHex,
        'sig': 'a' * 128,
        'sig_id': 'b' * 64,
      });
      // Sollte fehlschlagen da created_at fehlt
      expect(result.isValid, isFalse);
    });
  });

  // =============================================
  // NORMALISIERUNG (Compact → Full)
  // =============================================

  group('normalize', () {
    test('konvertiert Kompakt-Format korrekt', () {
      final compact = {
        'v': 2, 't': 'B', 'm': 'aschaffenburg-de',
        'b': 875000, 'c': 1700000000, 'x': 1700021600,
        'p': testPubkeyHex, 's': 'a' * 128,
      };
      final full = BadgeSecurity.normalize(compact);

      expect(full['v'], 2);
      expect(full['type'], 'BADGE');
      expect(full['meetup_id'], 'aschaffenburg');
      expect(full['meetup_country'], 'DE');
      expect(full['block_height'], 875000);
      expect(full['admin_pubkey'], testPubkeyHex);
      expect(full['sig'], 'a' * 128);
      expect(full['expires_at'], 1700021600);
    });

    test('extrahiert Meetup-Name aus ID (Großbuchstabe)', () {
      final compact = {'v': 2, 't': 'B', 'm': 'münchen-de', 'b': 0};
      final full = BadgeSecurity.normalize(compact);
      expect(full['meetup_name'], 'München');
      expect(full['meetup_country'], 'DE');
    });

    test('lässt bereits normalisiertes Format unverändert', () {
      final full = {'meetup_id': 'test', 'v': 2};
      final result = BadgeSecurity.normalize(full);
      expect(result, same(full)); // Identisches Objekt zurückgegeben
    });

    test('konvertiert delivery-Feld d=qr → rolling_qr', () {
      final compact = {'v': 2, 't': 'B', 'm': 'test', 'b': 0, 'd': 'qr'};
      final full = BadgeSecurity.normalize(compact);
      expect(full['delivery'], 'rolling_qr');
    });

    test('setzt admin_npub aus Pubkey', () {
      final compact = {'v': 2, 't': 'B', 'm': 'test-de', 'b': 0, 'p': testPubkeyHex};
      final full = BadgeSecurity.normalize(compact);
      expect(full['admin_npub'], startsWith('npub1'));
    });
  });

  // =============================================
  // ABLAUF-CHECKS
  // =============================================

  group('isExpired', () {
    test('nicht abgelaufen (Zukunft)', () {
      final future = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
      expect(BadgeSecurity.isExpired({'x': future}), isFalse);
    });

    test('abgelaufen (Vergangenheit)', () {
      final past = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600;
      expect(BadgeSecurity.isExpired({'x': past}), isTrue);
    });

    test('kein Ablauf gesetzt → nicht abgelaufen', () {
      expect(BadgeSecurity.isExpired({}), isFalse);
      expect(BadgeSecurity.isExpired({'x': 0}), isFalse);
    });

    test('unterstützt auch expires_at Feld', () {
      final past = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 1;
      expect(BadgeSecurity.isExpired({'expires_at': past}), isTrue);
    });
  });

  group('expiryInfo', () {
    test('kein Ablauf', () {
      expect(BadgeSecurity.expiryInfo({}), 'Kein Ablauf');
    });

    test('abgelaufen zeigt Zeitangabe', () {
      final past = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 7200; // 2h her
      final info = BadgeSecurity.expiryInfo({'x': past});
      expect(info, contains('Abgelaufen'));
    });

    test('noch gültig zeigt Restzeit', () {
      final future = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 7200; // +2h
      final info = BadgeSecurity.expiryInfo({'x': future});
      expect(info, contains('Gültig'));
    });
  });

  // =============================================
  // QR LEGACY ABLEHNUNG
  // =============================================

  group('verifyQRLegacy', () {
    test('lehnt immer ab (Security Audit C1)', () {
      final result = BadgeSecurity.verifyQRLegacy(
        jsonData: '{"test": true}',
        signature: 'fake_signature',
      );
      expect(result.isValid, isFalse);
    });
  });
}
