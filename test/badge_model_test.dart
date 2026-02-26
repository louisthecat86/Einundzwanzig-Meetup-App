// ============================================
// UNIT TESTS: MeetupBadge Model
// ============================================

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';

// Dart erlaubt 'a' * 128 nicht in const/default-Kontexten.
// Daher vorgefertigte Test-Konstanten:
const _sig128 = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _pub64 = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _sigId64 = 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _claimSig128 = 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _claimPub64 = 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const _xSig128 = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _yId64 = 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy';
const _zPub64 = 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz';

void main() {
  MeetupBadge _fullBadge({
    String id = 'badge-001',
    String meetupName = 'Aschaffenburg',
    int sigVersion = 2,
    String sig = _sig128,
    String adminPubkey = _pub64,
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
      sig: sig,
      sigId: _sigId64,
      adminPubkey: adminPubkey,
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
      claimSig: _claimSig128,
      claimPubkey: _claimPub64,
      claimTimestamp: 1700000000,
    );
  }

  group('toJson / fromJson Roundtrip', () {
    test('vollstaendiges Badge ueberlebt Roundtrip', () {
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
      };
      final badge = MeetupBadge.fromJson(json);
      expect(badge.id, 'old-badge');
      expect(badge.sig, isEmpty);
      expect(badge.sigVersion, 0);
      expect(badge.claimSig, isEmpty);
      expect(badge.delivery, 'nfc');
    });

    test('JSON-Encode produziert gueltiges JSON', () {
      final badge = _fullBadge();
      final jsonStr = jsonEncode(badge.toJson());
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['id'], 'badge-001');
    });
  });

  group('Kryptographische Properties', () {
    test('hasCryptoProof: v2 mit Signatur true', () {
      expect(_fullBadge(sigVersion: 2).hasCryptoProof, isTrue);
    });

    test('hasCryptoProof: v0 ohne Signatur false', () {
      expect(_fullBadge(sigVersion: 0, sig: '').hasCryptoProof, isFalse);
    });

    test('hasCryptoProof: v1 Legacy true (hat sig)', () {
      expect(_fullBadge(sigVersion: 1).hasCryptoProof, isTrue);
    });

    test('isNostrSigned: v2 + 128-Char-Sig + Pubkey true', () {
      expect(_fullBadge(sigVersion: 2).isNostrSigned, isTrue);
    });

    test('isNostrSigned: v1 false', () {
      expect(_fullBadge(sigVersion: 1).isNostrSigned, isFalse);
    });

    test('isNostrSigned: v2 aber leere Signatur false', () {
      expect(_fullBadge(sigVersion: 2, sig: '').isNostrSigned, isFalse);
    });

    test('isNostrSigned: v2 mit zu kurzer Signatur false', () {
      expect(_fullBadge(sigVersion: 2, sig: _pub64).isNostrSigned, isFalse);
    });
  });

  group('Claim-Binding', () {
    test('isClaimed: mit claimSig + claimPubkey true', () {
      expect(_claimedBadge().isClaimed, isTrue);
    });

    test('isClaimed: ohne Claim false', () {
      expect(_fullBadge().isClaimed, isFalse);
    });

    test('isFullyBound: Signatur + Claim true', () {
      expect(_claimedBadge().isFullyBound, isTrue);
    });

    test('isFullyBound: Signatur ohne Claim false', () {
      expect(_fullBadge().isFullyBound, isFalse);
    });

    test('isFullyBound: Claim ohne Signatur false', () {
      final badge = MeetupBadge(
        id: 'test', meetupName: 'Test', date: DateTime.now(), iconPath: '',
        sigVersion: 0, sig: '', adminPubkey: '',
        claimSig: _claimSig128, claimPubkey: _claimPub64,
      );
      expect(badge.isFullyBound, isFalse);
    });
  });

  group('withClaim', () {
    test('erzeugt neues Badge mit Claim-Daten', () {
      final original = _fullBadge();
      expect(original.isClaimed, isFalse);

      final claimed = original.withClaim(
        claimSig: _xSig128,
        claimEventId: _yId64,
        claimPubkey: _zPub64,
        claimTimestamp: 1700000000,
      );

      expect(claimed.isClaimed, isTrue);
      expect(claimed.claimSig, _xSig128);
      expect(claimed.claimPubkey, _zPub64);
      expect(original.isClaimed, isFalse);
    });

    test('behaelt Original-Daten bei', () {
      final original = _fullBadge();
      final claimed = original.withClaim(
        claimSig: _xSig128, claimEventId: _yId64,
        claimPubkey: _zPub64, claimTimestamp: 1700000000,
      );
      expect(claimed.id, original.id);
      expect(claimed.meetupName, original.meetupName);
      expect(claimed.sig, original.sig);
      expect(claimed.sigVersion, original.sigVersion);
    });

    test('retroactive Flag wird gesetzt', () {
      final claimed = _fullBadge().withClaim(
        claimSig: _xSig128, claimEventId: _yId64,
        claimPubkey: _zPub64, claimTimestamp: 1700000000,
        isRetroactive: true,
      );
      expect(claimed.isRetroactive, isTrue);
    });
  });

  group('proofId', () {
    test('nutzt sigId wenn vorhanden', () {
      expect(_fullBadge().proofId, _sigId64);
    });

    test('nutzt sig-Prefix als Fallback', () {
      final badge = MeetupBadge(
        id: 'test', meetupName: 'Test', date: DateTime.now(), iconPath: '',
        sig: _sig128, sigId: '', sigVersion: 2, adminPubkey: _pub64,
      );
      expect(badge.proofId, _sig128.substring(0, 64));
    });

    test('generiert SHA-256 Hash als letzten Fallback', () {
      final badge = MeetupBadge(
        id: 'test', meetupName: 'Test', date: DateTime.utc(2025), iconPath: '',
        sig: '', sigId: '', sigVersion: 0,
      );
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
      expect(_fullBadge().claimProofId, isEmpty);
    });

    test('claimProofId ist deterministisch', () {
      expect(_claimedBadge().claimProofId, _claimedBadge().claimProofId);
    });
  });

  group('Badge-Proof Hashes', () {
    test('generateBadgeProof: deterministisch', () {
      final badges = [_fullBadge(id: '1'), _fullBadge(id: '2')];
      final a = MeetupBadge.generateBadgeProof(badges);
      final b = MeetupBadge.generateBadgeProof(badges);
      expect(a, b);
      expect(a.length, 64);
    });

    test('generateBadgeProof: leere Liste leer', () {
      expect(MeetupBadge.generateBadgeProof([]), isEmpty);
    });

    test('generateBadgeProof: Reihenfolge wird sortiert', () {
      final b1 = _fullBadge(id: '1');
      final b2 = _fullBadge(id: '2');
      expect(
        MeetupBadge.generateBadgeProof([b1, b2]),
        MeetupBadge.generateBadgeProof([b2, b1]),
      );
    });

    test('verifyBadgeProof: korrekt true', () {
      final badges = [_fullBadge(id: '1'), _fullBadge(id: '2')];
      final proof = MeetupBadge.generateBadgeProof(badges);
      expect(MeetupBadge.verifyBadgeProof(badges, proof), isTrue);
    });

    test('verifyBadgeProof: manipuliert false', () {
      expect(MeetupBadge.verifyBadgeProof([_fullBadge(id: '1')], 'fake'), isFalse);
    });

    test('generateBadgeProofV2: nur gebundene Badges', () {
      final badges = [
        _claimedBadge(id: '1'),
        _fullBadge(id: '2'),
        _claimedBadge(id: '3'),
      ];
      final proof = MeetupBadge.generateBadgeProofV2(badges);
      expect(proof, isNotEmpty);
      expect(proof.length, 64);
    });

    test('generateBadgeProofV2: keine gebundenen leer', () {
      expect(MeetupBadge.generateBadgeProofV2([_fullBadge(id: '1')]), isEmpty);
    });
  });

  group('Reputations-Statistiken', () {
    test('getReputationStats: korrekte Zaehlung', () {
      final badges = [
        _claimedBadge(id: '1'),
        _fullBadge(id: '2'),
        _claimedBadge(id: '3'),
        MeetupBadge(id: '4', meetupName: 'X', date: DateTime.now(), iconPath: '', sigVersion: 0),
      ];
      final stats = MeetupBadge.getReputationStats(badges);
      expect(stats['total'], 4);
      expect(stats['crypto_proof'], 3);
      expect(stats['claimed'], 2);
      expect(stats['fully_trusted'], 2);
      expect(stats['retroactive'], 0);
    });

    test('countVerifiedBadges', () {
      final badges = [
        _fullBadge(id: '1', sigVersion: 2),
        _fullBadge(id: '2', sigVersion: 0, sig: ''),
        _fullBadge(id: '3', sigVersion: 1),
      ];
      expect(MeetupBadge.countVerifiedBadges(badges), 2);
    });

    test('retroactive Badges werden separat gezaehlt', () {
      final badges = [
        _fullBadge(id: '1', claimSig: _claimSig128, claimPubkey: _claimPub64, claimTimestamp: 1700000000),
        MeetupBadge(
          id: '2', meetupName: 'Test', date: DateTime.now(), iconPath: '',
          sig: _sig128, sigId: _sigId64, adminPubkey: _pub64, sigVersion: 2,
          claimSig: _claimSig128, claimPubkey: _claimPub64, claimTimestamp: 1700000000,
          isRetroactive: true,
        ),
      ];
      final stats = MeetupBadge.getReputationStats(badges);
      expect(stats['retroactive'], 1);
      expect(stats['fully_trusted'], 1);
    });
  });
}
