// ============================================
// UNIT TESTS: MeetupBadge Model
// ============================================
// Testet das Badge-Datenmodell:
//   - Serialisierung (toJson / fromJson Roundtrip)
//   - Kryptographische Eigenschaften (hasCryptoProof, isNostrSigned)
//   - Claim-Binding (isClaimed, isFullyBound)
//   - Badge-Proof-Hash (deterministisch, datenschutzkonform)
//   - Reputations-Statistiken
//   - withClaim() Builder
// ============================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';

void main() {
  // =============================================
  // TEST FIXTURES
  // =============================================

  MeetupBadge _fullBadge({
    String id = 'badge-001',
    String meetupName = 'Aschaffenburg',
    int sigVersion = 2,
    String sig = '',
    String adminPubkey = '',
    String claimSig = '',
    String claimPubkey = '',
    int claimTimestamp = 0,
    bool isRetroactive = false,
  }) {
    return MeetupBadge(
      id: id,
      meetupName: meetupName,
      date: DateTime.utc(2025, 3, 15),
      iconPath: 'assets/badge.png',
      blockHeight: 875000,
      signerNpub: 'npub1testadmin',
      meetupEventId: 'aschaffenburg-2025-03-15',
      delivery: 'nfc',
      sig: sig.isNotEmpty ? sig : 'a' * 128,
      sigId: 'c' * 64,
      adminPubkey: adminPubkey.isNotEmpty ? adminPubkey : 'b' * 64,
      sigVersion: sigVersion,
      sigContent: '{"v":2,"t":"B","m":"aschaffenburg-de"}',
      claimSig: claimSig,
      claimPubkey: claimPubkey,
      claimTimestamp: claimTimestamp,
      isRetroactive: isRetroactive,
    );
  }

  MeetupBadge _claimedBadge({
    String id = 'badge-001',
    String meetupName = 'Aschaffenburg',
  }) {
    return _fullBadge(
      id: id,
      meetupName: meetupName,
      claimSig: 'd' * 128,
      claimPubkey: 'e' * 64,
      claimTimestamp: 1700000000,
    );
  }

  // =============================================
  // SERIALISIERUNG
  // =============================================

  group('toJson / fromJson Roundtrip', () {
    test('vollständiges Badge überlebt Roundtrip', () {
      final original = _claimedBadge();
      final json = original.toJson();
      final restored = MeetupBadge.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.meetupName, original.meetupName);
      expect(restored.date, original.date);
      expect(restored.blockHeight, original.blockHeight);
      expect(restored.sig, original.sig);
      expect(restored.sigId, original.sigId);
      expect(restored.adminPubkey, original.adminPubkey);
      expect(restored.sigVersion, original.sigVersion);
      expect(restored.delivery, original.delivery);
      expect(restored.claimSig, original.claimSig);
      expect(restored.claimPubkey, original.claimPubkey);
      expect(restored.claimTimestamp, original.claimTimestamp);
    });

    test('minimales Badge (backward-compatible)', () {
      final json = {
        'id': 'old-badge',
        'meetupName': 'Test',
        'date': '2025-01-01T00:00:00.000Z',
        'iconPath': '',
        // Keine sig, claim, etc. → Defaults
      };
      final badge = MeetupBadge.fromJson(json);
      
      expect(badge.id, 'old-badge');
      expect(badge.sig, isEmpty);
      expect(badge.sigVersion, 0);
      expect(badge.claimSig, isEmpty);
      expect(badge.delivery, 'nfc'); // Default
    });

    test('JSON-Encode produziert gültiges JSON', () {
      final badge = _fullBadge();
      final jsonStr = jsonEncode(badge.toJson());
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['id'], 'badge-001');
    });
  });

  // =============================================
  // KRYPTOGRAPHISCHE EIGENSCHAFTEN
  // =============================================

  group('Kryptographische Properties', () {
    test('hasCryptoProof: v2 mit Signatur → true', () {
      final badge = _fullBadge(sigVersion: 2);
      expect(badge.hasCryptoProof, isTrue);
    });

    test('hasCryptoProof: v0 ohne Signatur → false', () {
      final badge = _fullBadge(sigVersion: 0, sig: '');
      expect(badge.hasCryptoProof, isFalse);
    });

    test('hasCryptoProof: v1 Legacy → true (hat sig)', () {
      final badge = _fullBadge(sigVersion: 1);
      expect(badge.hasCryptoProof, isTrue);
    });

    test('isNostrSigned: v2 + 128-Char-Sig + Pubkey → true', () {
      final badge = _fullBadge(sigVersion: 2);
      expect(badge.isNostrSigned, isTrue);
    });

    test('isNostrSigned: v1 → false', () {
      final badge = _fullBadge(sigVersion: 1);
      expect(badge.isNostrSigned, isFalse);
    });

    test('isNostrSigned: v2 aber leere Signatur → false', () {
      final badge = _fullBadge(sigVersion: 2, sig: '');
      expect(badge.isNostrSigned, isFalse);
    });

    test('isNostrSigned: v2 mit zu kurzer Signatur → false', () {
      final badge = _fullBadge(sigVersion: 2, sig: 'a' * 64);
      expect(badge.isNostrSigned, isFalse);
    });
  });

  // =============================================
  // CLAIM-BINDING
  // =============================================

  group('Claim-Binding', () {
    test('isClaimed: mit claimSig + claimPubkey → true', () {
      final badge = _claimedBadge();
      expect(badge.isClaimed, isTrue);
    });

    test('isClaimed: ohne Claim → false', () {
      final badge = _fullBadge();
      expect(badge.isClaimed, isFalse);
    });

    test('isFullyBound: Signatur + Claim → true', () {
      final badge = _claimedBadge();
      expect(badge.isFullyBound, isTrue);
    });

    test('isFullyBound: Signatur ohne Claim → false', () {
      final badge = _fullBadge();
      expect(badge.isFullyBound, isFalse);
    });

    test('isFullyBound: Claim ohne Signatur → false', () {
      final badge = MeetupBadge(
        id: 'test', meetupName: 'Test', date: DateTime.now(), iconPath: '',
        sigVersion: 0, sig: '', adminPubkey: '',
        claimSig: 'd' * 128, claimPubkey: 'e' * 64,
      );
      expect(badge.isFullyBound, isFalse);
    });
  });

  // =============================================
  // withClaim() BUILDER
  // =============================================

  group('withClaim', () {
    test('erzeugt neues Badge mit Claim-Daten', () {
      final original = _fullBadge();
      expect(original.isClaimed, isFalse);

      final claimed = original.withClaim(
        claimSig: 'x' * 128,
        claimEventId: 'y' * 64,
        claimPubkey: 'z' * 64,
        claimTimestamp: 1700000000,
      );

      expect(claimed.isClaimed, isTrue);
      expect(claimed.claimSig, 'x' * 128);
      expect(claimed.claimPubkey, 'z' * 64);
      // Original bleibt unverändert
      expect(original.isClaimed, isFalse);
    });

    test('behält Original-Daten bei', () {
      final original = _fullBadge();
      final claimed = original.withClaim(
        claimSig: 'x' * 128, claimEventId: 'y' * 64,
        claimPubkey: 'z' * 64, claimTimestamp: 1700000000,
      );

      expect(claimed.id, original.id);
      expect(claimed.meetupName, original.meetupName);
      expect(claimed.sig, original.sig);
      expect(claimed.sigVersion, original.sigVersion);
    });

    test('retroactive Flag wird gesetzt', () {
      final original = _fullBadge();
      final claimed = original.withClaim(
        claimSig: 'x' * 128, claimEventId: 'y' * 64,
        claimPubkey: 'z' * 64, claimTimestamp: 1700000000,
        isRetroactive: true,
      );
      expect(claimed.isRetroactive, isTrue);
    });
  });

  // =============================================
  // PROOF-IDs
  // =============================================

  group('proofId', () {
    test('nutzt sigId wenn vorhanden', () {
      final badge = _fullBadge();
      expect(badge.proofId, 'c' * 64); // sigId
    });

    test('nutzt sig-Prefix als Fallback', () {
      final badge = MeetupBadge(
        id: 'test', meetupName: 'Test', date: DateTime.now(), iconPath: '',
        sig: 'abcd' * 32, sigId: '', sigVersion: 2, adminPubkey: 'b' * 64,
      );
      expect(badge.proofId, ('abcd' * 32).substring(0, 64));
    });

    test('generiert SHA-256 Hash als letzten Fallback', () {
      final badge = MeetupBadge(
        id: 'test', meetupName: 'Test', date: DateTime.utc(2025), iconPath: '',
        sig: '', sigId: '', sigVersion: 0,
      );
      // Sollte ein deterministischer 64-Zeichen-Hash sein
      expect(badge.proofId.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(badge.proofId), isTrue);
    });
  });

  group('claimProofId', () {
    test('geclaimes Badge hat claimProofId', () {
      final badge = _claimedBadge();
      expect(badge.claimProofId, isNotEmpty);
      expect(badge.claimProofId.length, 64);
    });

    test('ungeclaimtes Badge hat leere claimProofId', () {
      final badge = _fullBadge();
      expect(badge.claimProofId, isEmpty);
    });

    test('claimProofId ist deterministisch', () {
      final a = _claimedBadge();
      final b = _claimedBadge();
      expect(a.claimProofId, b.claimProofId);
    });
  });

  // =============================================
  // BADGE-PROOF HASH
  // =============================================

  group('Badge-Proof Hashes', () {
    test('generateBadgeProof: deterministisch', () {
      final badges = [
        _fullBadge(id: '1'),
        _fullBadge(id: '2'),
      ];
      final a = MeetupBadge.generateBadgeProof(badges);
      final b = MeetupBadge.generateBadgeProof(badges);
      expect(a, b);
      expect(a.length, 64); // SHA-256
    });

    test('generateBadgeProof: leere Liste → leerer String', () {
      expect(MeetupBadge.generateBadgeProof([]), isEmpty);
    });

    test('generateBadgeProof: Reihenfolge wird sortiert (deterministisch)', () {
      final b1 = _fullBadge(id: '1');
      final b2 = _fullBadge(id: '2');
      final a = MeetupBadge.generateBadgeProof([b1, b2]);
      final b = MeetupBadge.generateBadgeProof([b2, b1]);
      expect(a, b); // Sortiert nach Datum
    });

    test('verifyBadgeProof: korrekt → true', () {
      final badges = [_fullBadge(id: '1'), _fullBadge(id: '2')];
      final proof = MeetupBadge.generateBadgeProof(badges);
      expect(MeetupBadge.verifyBadgeProof(badges, proof), isTrue);
    });

    test('verifyBadgeProof: manipuliert → false', () {
      final badges = [_fullBadge(id: '1')];
      expect(MeetupBadge.verifyBadgeProof(badges, 'fake_proof'), isFalse);
    });

    test('generateBadgeProofV2: nur gebundene Badges', () {
      final badges = [
        _claimedBadge(id: '1'),     // Gebunden
        _fullBadge(id: '2'),         // NICHT gebunden
        _claimedBadge(id: '3'),     // Gebunden
      ];
      final proof = MeetupBadge.generateBadgeProofV2(badges);
      expect(proof, isNotEmpty);
      expect(proof.length, 64);
    });

    test('generateBadgeProofV2: keine gebundenen Badges → leer', () {
      final badges = [_fullBadge(id: '1'), _fullBadge(id: '2')];
      expect(MeetupBadge.generateBadgeProofV2(badges), isEmpty);
    });
  });

  // =============================================
  // REPUTATIONS-STATISTIKEN
  // =============================================

  group('Reputations-Statistiken', () {
    test('getReputationStats: korrekte Zählung', () {
      final badges = [
        _claimedBadge(id: '1'),                    // fully bound
        _fullBadge(id: '2'),                        // crypto proof, not claimed
        _claimedBadge(id: '3'),                    // fully bound
        MeetupBadge(
          id: '4', meetupName: 'X', date: DateTime.now(),
          iconPath: '', sigVersion: 0,              // no proof
        ),
      ];

      final stats = MeetupBadge.getReputationStats(badges);
      expect(stats['total'], 4);
      expect(stats['crypto_proof'], 3); // Badge 1, 2, 3
      expect(stats['claimed'], 2);      // Badge 1, 3
      expect(stats['fully_trusted'], 2);
      expect(stats['retroactive'], 0);
    });

    test('countVerifiedBadges', () {
      final badges = [
        _fullBadge(id: '1', sigVersion: 2),    // verified
        _fullBadge(id: '2', sigVersion: 0, sig: ''), // not verified
        _fullBadge(id: '3', sigVersion: 1),    // verified (has sig)
      ];
      expect(MeetupBadge.countVerifiedBadges(badges), 2);
    });

    test('retroactive Badges werden separat gezählt', () {
      final badges = [
        _fullBadge(
          id: '1',
          claimSig: 'd' * 128,
          claimPubkey: 'e' * 64,
          claimTimestamp: 1700000000,
        ),
        MeetupBadge(
          id: '2', meetupName: 'Test', date: DateTime.now(), iconPath: '',
          sig: 'a' * 128, sigId: 'c' * 64, adminPubkey: 'b' * 64, sigVersion: 2,
          claimSig: 'd' * 128, claimPubkey: 'e' * 64, claimTimestamp: 1700000000,
          isRetroactive: true,
        ),
      ];
      final stats = MeetupBadge.getReputationStats(badges);
      expect(stats['retroactive'], 1);
      expect(stats['fully_trusted'], 1);
    });
  });
}
