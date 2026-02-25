// ============================================
// BADGE CLAIM SERVICE — Identitäts-Binding
// ============================================
// Bindet Badges kryptographisch an den Sammler.
//
// Jeder Claim ist ein Nostr-Event (Kind 21002):
//   Content = JSON mit Organisator-Signatur-Referenz
//   Signiert mit dem privaten Schlüssel des Sammlers
//
// Damit kann niemand fremde Badges für seine
// eigene Reputation verwenden.
//
// Ablauf:
//   1. Badge wird gescannt (Organisator-Signatur geprüft)
//   2. createClaim() → Claim-Signatur erstellen
//   3. Badge + Claim zusammen speichern
//   4. Reputation nutzt nur gebundene Badges
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/badge.dart';
import 'nostr_service.dart';
import 'badge_security.dart';

// Nostr Event und Nip19 Imports (aus dem nostr package)
// Diese sind bereits in der App vorhanden über badge_security.dart
import 'package:nostr/nostr.dart';

/// Ergebnis einer Claim-Erstellung
class ClaimResult {
  final bool success;
  final String claimSig;
  final String claimEventId;
  final String claimPubkey;
  final int claimTimestamp;
  final String message;

  ClaimResult({
    required this.success,
    this.claimSig = '',
    this.claimEventId = '',
    this.claimPubkey = '',
    this.claimTimestamp = 0,
    this.message = '',
  });
}

/// Ergebnis einer Claim-Verifikation
class ClaimVerifyResult {
  final bool isValid;
  final String claimerNpub;
  final String message;

  ClaimVerifyResult({
    required this.isValid,
    this.claimerNpub = '',
    this.message = '',
  });
}

class BadgeClaimService {

  // =============================================
  // CLAIM ERSTELLEN
  // =============================================
  // Wird automatisch nach jedem Badge-Scan aufgerufen.
  // Erstellt eine Schnorr-Signatur die das Badge
  // an den Sammler bindet.
  // =============================================

  /// Erstellt einen Claim für ein neues Badge
  static Future<ClaimResult> createClaim({
    required String orgSig,        // Organisator-Signatur des Badges
    required String orgEventId,    // Event-ID des Badge-Events (sigId)
    required String orgPubkey,     // Pubkey des Organisators
    required int blockHeight,      // Block Height des Badges
  }) async {
    try {
      final privHex = await SecureKeyStore.getPrivHex();
      if (privHex == null || privHex.isEmpty) {
        return ClaimResult(
          success: false,
          message: 'Kein Schlüssel vorhanden — Claim nicht möglich',
        );
      }

      final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Claim-Content: Referenziert die Organisator-Signatur
      // Damit ist der Claim an genau DIESES Badge gebunden
      final Map<String, dynamic> claimContent = {
        'action': 'claim_badge',
        'org_sig': orgSig,
        'org_event_id': orgEventId,
        'org_pubkey': orgPubkey,
        'block_height': blockHeight,
        'claimed_at': now,
      };

      // Kanonisiert für deterministischen Hash
      final contentJson = BadgeSecurity.canonicalJsonEncode(claimContent);

      // Nostr-Event erstellen und signieren
      final event = Event.from(
        kind: 21002,  // Badge-Claim Event Kind
        tags: [
          ['t', 'badge_claim'],
          ['p', orgPubkey],      // Referenz zum Organisator
          ['block', blockHeight.toString()],
        ],
        content: contentJson,
        privkey: privHex,
      );

      return ClaimResult(
        success: true,
        claimSig: event.sig,
        claimEventId: event.id,
        claimPubkey: event.pubkey,
        claimTimestamp: now,
        message: 'Badge gebunden ✓',
      );
    } catch (e) {
      return ClaimResult(
        success: false,
        message: 'Claim-Fehler: $e',
      );
    }
  }

  // =============================================
  // CLAIM VERIFIZIEREN
  // =============================================
  // Prüft ob ein Claim gültig ist:
  //   1. Schnorr-Signatur des Claims gültig?
  //   2. Claim referenziert die richtige Organisator-Signatur?
  //   3. Claim-Pubkey stimmt?
  // =============================================

  /// Verifiziert einen Badge-Claim
  static ClaimVerifyResult verifyClaim({
    required String claimSig,
    required String claimEventId,
    required String claimPubkey,
    required int claimTimestamp,
    required String orgSig,
    required String orgEventId,
    required String orgPubkey,
    required int blockHeight,
  }) {
    try {
      if (claimSig.isEmpty || claimEventId.isEmpty || claimPubkey.isEmpty) {
        return ClaimVerifyResult(
          isValid: false,
          message: 'Fehlende Claim-Daten',
        );
      }

      // Claim-Content rekonstruieren
      final Map<String, dynamic> claimContent = {
        'action': 'claim_badge',
        'org_sig': orgSig,
        'org_event_id': orgEventId,
        'org_pubkey': orgPubkey,
        'block_height': blockHeight,
        'claimed_at': claimTimestamp,
      };

      final contentJson = BadgeSecurity.canonicalJsonEncode(claimContent);

      // Event-ID nachrechnen
      final tags = [
        ['t', 'badge_claim'],
        ['p', orgPubkey],
        ['block', blockHeight.toString()],
      ];
      final serialized = jsonEncode([0, claimPubkey, claimTimestamp, 21002, tags, contentJson]);
      final expectedEventId = sha256.convert(utf8.encode(serialized)).toString();

      // Event-ID prüfen
      if (expectedEventId != claimEventId) {
        return ClaimVerifyResult(
          isValid: false,
          message: 'Claim Event-ID stimmt nicht überein',
        );
      }

      // Schnorr-Signatur prüfen
      final event = Event(claimEventId, claimPubkey, claimTimestamp, 21002, tags, contentJson, claimSig);
      final isValid = event.isValid();

      String claimerNpub = '';
      try { claimerNpub = Nip19.encodePubkey(claimPubkey); } catch (_) {}

      return ClaimVerifyResult(
        isValid: isValid,
        claimerNpub: claimerNpub,
        message: isValid 
            ? 'Claim verifiziert ✓ — Gebunden an $claimerNpub' 
            : 'Claim-Signatur ungültig!',
      );
    } catch (e) {
      return ClaimVerifyResult(
        isValid: false,
        message: 'Claim-Verifikation fehlgeschlagen: $e',
      );
    }
  }

  /// Verifiziert den Claim eines MeetupBadge-Objekts
  static ClaimVerifyResult verifyBadgeClaim(MeetupBadge badge) {
    if (!badge.isClaimed) {
      return ClaimVerifyResult(
        isValid: false,
        message: 'Badge hat keinen Claim',
      );
    }

    return verifyClaim(
      claimSig: badge.claimSig,
      claimEventId: badge.claimEventId,
      claimPubkey: badge.claimPubkey,
      claimTimestamp: badge.claimTimestamp,
      orgSig: badge.sig,
      orgEventId: badge.sigId,
      orgPubkey: badge.adminPubkey,
      blockHeight: badge.blockHeight,
    );
  }

  // =============================================
  // RETROAKTIVES CLAIMING
  // =============================================
  // Für Badges die VOR dem Update gesammelt wurden.
  // Werden als "retroactive" markiert (reduzierter Wert).
  // Läuft automatisch beim App-Start.
  // =============================================

  /// Retroaktiv alle ungebundenen Badges claimen
  /// Gibt die Anzahl der neu geclaimten Badges zurück
  static Future<int> claimUnboundBadges(List<MeetupBadge> badges) async {
    int claimedCount = 0;

    for (int i = 0; i < badges.length; i++) {
      final badge = badges[i];

      // Nur Badges mit Organisator-Signatur aber ohne Claim
      if (badge.hasCryptoProof && !badge.isClaimed) {
        final result = await createClaim(
          orgSig: badge.sig,
          orgEventId: badge.sigId,
          orgPubkey: badge.adminPubkey,
          blockHeight: badge.blockHeight,
        );

        if (result.success) {
          badges[i] = badge.withClaim(
            claimSig: result.claimSig,
            claimEventId: result.claimEventId,
            claimPubkey: result.claimPubkey,
            claimTimestamp: result.claimTimestamp,
            isRetroactive: true,  // Markiert als nachträglich
          );
          claimedCount++;
        }
      }
    }

    if (claimedCount > 0) {
      await MeetupBadge.saveBadges(badges);
    }

    return claimedCount;
  }

  /// Prüft ob retroaktives Claiming nötig ist und führt es durch
  /// Sollte beim App-Start aufgerufen werden (einmalig)
  static Future<int> ensureBadgesClaimed(List<MeetupBadge> badges) async {
    final unclaimedCount = badges.where((b) => b.hasCryptoProof && !b.isClaimed).length;
    
    if (unclaimedCount == 0) return 0;

    return await claimUnboundBadges(badges);
  }
}