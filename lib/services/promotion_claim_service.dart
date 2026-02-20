// ============================================
// PROMOTION CLAIM SERVICE — Proof of Reputation
// ============================================
//
// Löst das "Trust Score Paradoxon":
// Ein User der lokal zum Admin promotet wird,
// muss auch von ANDEREN Apps als Admin erkannt werden.
//
// KONZEPT:
//   1. User sammelt genug Badges → Trust Score erreicht
//   2. App publiziert einen "Admin Claim" auf Nostr (Kind 30021)
//      → Enthält die Badge-Beweise (Schnorr-Signaturen)
//   3. JEDE andere App kann diesen Claim verifizieren:
//      → Sind die Badge-Signaturen echt?
//      → Stammen sie von bekannten Admins?
//      → Reicht die Anzahl für den Schwellenwert?
//   4. Wenn ja → Claimer wird lokal als "organic" Admin akzeptiert
//
// SICHERHEIT:
//   - Schnorr-Signaturen sind unfälschbar
//   - Niemand kann Badges erfinden die er nicht hat
//   - Kein Super-Admin nötig → erlaubnisfreies Wachstum
//   - Jede App verifiziert selbst ("Don't trust, verify")
//
// GENERATIONEN:
//   Gen 0: Super-Admin (Genesis)
//   Gen 1: Badges von Gen 0 → werden selbst Admin
//   Gen 2: Badges von Gen 1 → werden selbst Admin
//   Das Netz wächst wie ein Pilzgeflecht.
//
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nostr/nostr.dart';
import '../models/badge.dart';
import 'secure_key_store.dart';
import 'nostr_service.dart';
import 'badge_security.dart';
import 'admin_registry.dart';
import 'trust_score_service.dart';

class PromotionClaimService {
  // Nostr Event Kind für Admin Claims
  static const int _claimKind = 30021;
  static const String _claimDTag = 'einundzwanzig-admin-claim';

  // Minimale Badge-Anforderungen für einen gültigen Claim
  // (Muss mit TrustConfig übereinstimmen)
  static const int minVerifiedBadges = 3;
  static const int minUniqueSigners = 1;

  // Relays (gleiche wie AdminRegistry)
  static const List<String> _relays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://nostr.einundzwanzig.space',
  ];

  static const Duration _relayTimeout = Duration(seconds: 8);

  // =============================================
  // CLAIM PUBLIZIEREN (Wenn User Threshold erreicht)
  // =============================================
  //
  // Wird aufgerufen wenn der Trust Score den
  // Schwellenwert überschreitet. Erstellt ein
  // signiertes Nostr Event mit den Badge-Beweisen.
  //
  static Future<bool> publishAdminClaim({
    required List<MeetupBadge> badges,
    required String meetupName,
  }) async {
    final privHex = await SecureKeyStore.getPrivHex();
    final npub = await SecureKeyStore.getNpub();
    if (privHex == null || npub == null) return false;

    // Nur Badges mit kryptographischem Beweis
    final verifiedBadges = badges.where((b) => b.hasCryptoProof).toList();
    if (verifiedBadges.length < minVerifiedBadges) return false;

    // Badge-Beweise kompakt verpacken
    final proofs = verifiedBadges.map((b) => {
      'meetup': b.meetupName,
      'date': b.date.toIso8601String(),
      'block': b.blockHeight,
      'sig': b.sig,
      'sig_id': b.sigId,
      'admin_pubkey': b.adminPubkey,
      'sig_version': b.sigVersion,
      'sig_content': b.sigContent,
    }).toList();

    // Unique Signers zählen
    final uniqueSigners = verifiedBadges
        .map((b) => b.adminPubkey)
        .where((p) => p.isNotEmpty)
        .toSet()
        .length;

    final claimContent = jsonEncode({
      'type': 'admin_claim',
      'version': 1,
      'claimer_npub': npub,
      'meetup': meetupName,
      'verified_badges': verifiedBadges.length,
      'unique_signers': uniqueSigners,
      'proofs': proofs,
      'claimed_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    // Signiertes Nostr Event erstellen
    final event = Event.from(
      kind: _claimKind,
      tags: [
        ['d', _claimDTag],
        ['meetup', meetupName],
      ],
      content: claimContent,
      privkey: privHex,
    );

    // An Relays publishen
    int successCount = 0;
    final eventJson = jsonEncode([
      'EVENT',
      {
        'id': event.id,
        'pubkey': event.pubkey,
        'created_at': event.createdAt,
        'kind': event.kind,
        'tags': event.tags,
        'content': event.content,
        'sig': event.sig,
      }
    ]);

    for (final relayUrl in _relays) {
      try {
        final ws = await WebSocket.connect(relayUrl)
            .timeout(const Duration(seconds: 5));
        ws.add(eventJson);
        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        successCount++;
        print('[PromotionClaim] Claim an $relayUrl gesendet ✓');
      } catch (e) {
        print('[PromotionClaim] $relayUrl fehlgeschlagen: $e');
      }
    }

    print('[PromotionClaim] Claim publiziert an $successCount Relays');
    return successCount > 0;
  }

  // =============================================
  // CLAIMS VON RELAYS LADEN UND VERIFIZIEREN
  // =============================================
  //
  // Wird beim App-Start aufgerufen. Lädt alle
  // Admin Claims und verifiziert sie mathematisch.
  // Gültige Claims werden in die lokale Admin-Liste
  // aufgenommen.
  //
  static Future<List<VerifiedClaim>> syncOrganicAdmins() async {
    final List<VerifiedClaim> verifiedClaims = [];

    try {
      final claims = await _fetchClaimsFromRelays();
      if (claims == null || claims.isEmpty) return verifiedClaims;

      // Bekannte Admins laden (Genesis + Registry)
      final knownAdmins = await AdminRegistry.getAdminList();
      final knownPubkeys = <String>{};

      // Super-Admin Pubkey
      try {
        knownPubkeys.add(Nip19.decodePubkey(AdminRegistry.superAdminNpub));
      } catch (_) {}

      // Alle bekannten Admin-Pubkeys sammeln
      for (final admin in knownAdmins) {
        try {
          knownPubkeys.add(Nip19.decodePubkey(admin.npub));
        } catch (_) {}
      }

      for (final claim in claims) {
        try {
          final result = _verifyClaim(claim, knownPubkeys);
          if (result != null) {
            verifiedClaims.add(result);

            // In die lokale Admin-Registry aufnehmen
            try {
              final claimerNpub = Nip19.encodePubkey(claim.pubkey);
              await AdminRegistry.addAdmin(AdminEntry(
                npub: claimerNpub,
                meetup: result.meetup,
                name: 'Organic (${result.verifiedBadgeCount} Badges)',
                addedAt: claim.createdAt,
              ));
              print('[PromotionClaim] Organic Admin akzeptiert: ${NostrService.shortenNpub(claimerNpub)}');
            } catch (e) {
              // Duplikat — bereits in der Liste
            }
          }
        } catch (e) {
          print('[PromotionClaim] Claim-Verifikation fehlgeschlagen: $e');
        }
      }
    } catch (e) {
      print('[PromotionClaim] Sync fehlgeschlagen: $e');
    }

    return verifiedClaims;
  }

  // =============================================
  // EINZELNEN CLAIM MATHEMATISCH VERIFIZIEREN
  // =============================================
  //
  // Das Herzstück: Prüft ob die Badge-Beweise
  // echt sind und von bekannten Admins stammen.
  //
  static VerifiedClaim? _verifyClaim(
    _RawClaim claim,
    Set<String> knownAdminPubkeys,
  ) {
    // 1. Claim-Content parsen
    Map<String, dynamic> content;
    try {
      content = jsonDecode(claim.content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    if (content['type'] != 'admin_claim') return null;

    final proofs = content['proofs'] as List<dynamic>? ?? [];
    final meetup = content['meetup'] as String? ?? '';

    if (proofs.isEmpty || meetup.isEmpty) return null;

    // 2. Jeden Badge-Beweis einzeln verifizieren
    int validBadgeCount = 0;
    final verifiedSigners = <String>{};

    for (final proof in proofs) {
      try {
        final proofMap = proof as Map<String, dynamic>;
        final sig = proofMap['sig'] as String? ?? '';
        final sigId = proofMap['sig_id'] as String? ?? '';
        final adminPubkey = proofMap['admin_pubkey'] as String? ?? '';
        final sigVersion = proofMap['sig_version'] as int? ?? 0;
        final sigContent = proofMap['sig_content'] as String? ?? '';

        if (sig.isEmpty || adminPubkey.isEmpty) continue;

        // Ist der Signer ein bekannter Admin?
        if (!knownAdminPubkeys.contains(adminPubkey)) {
          // Unbekannter Signer → Badge zählt nicht
          continue;
        }

        // Signatur mathematisch prüfen
        bool isValid = false;
        if (sigVersion >= 2 && sigContent.isNotEmpty) {
          // v2: Nostr Event Signatur prüfen
          try {
            final data = jsonDecode(sigContent) as Map<String, dynamic>;
            final verifyResult = BadgeSecurity.verify(data);
            isValid = verifyResult.isValid;
          } catch (_) {
            isValid = false;
          }
        }

        if (isValid) {
          validBadgeCount++;
          verifiedSigners.add(adminPubkey);
        }
      } catch (_) {
        continue;
      }
    }

    // 3. Schwellenwert-Check
    if (validBadgeCount < minVerifiedBadges) return null;
    if (verifiedSigners.length < minUniqueSigners) return null;

    return VerifiedClaim(
      claimerPubkey: claim.pubkey,
      meetup: meetup,
      verifiedBadgeCount: validBadgeCount,
      uniqueSignerCount: verifiedSigners.length,
      claimedAt: claim.createdAt,
    );
  }

  // =============================================
  // CLAIMS VON RELAYS FETCHEN
  // =============================================
  static Future<List<_RawClaim>?> _fetchClaimsFromRelays() async {
    for (final relayUrl in _relays) {
      try {
        final result = await _fetchFromSingleRelay(relayUrl);
        if (result != null && result.isNotEmpty) {
          print('[PromotionClaim] ${result.length} Claims von $relayUrl geladen');
          return result;
        }
      } catch (e) {
        print('[PromotionClaim] $relayUrl fehlgeschlagen: $e');
        continue;
      }
    }
    return null;
  }

  static Future<List<_RawClaim>?> _fetchFromSingleRelay(String relayUrl) async {
    WebSocket? ws;

    try {
      ws = await WebSocket.connect(relayUrl).timeout(_relayTimeout);

      final completer = Completer<List<_RawClaim>>();
      final claims = <_RawClaim>[];
      final subscriptionId = 'organic-claims-${DateTime.now().millisecondsSinceEpoch}';

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3) {
              final eventData = message[2] as Map<String, dynamic>;

              // Event-Signatur prüfen
              final event = Event(
                eventData['id'] ?? '',
                eventData['pubkey'] ?? '',
                eventData['created_at'] ?? 0,
                eventData['kind'] ?? 0,
                (eventData['tags'] as List<dynamic>?)
                    ?.map((t) => (t as List<dynamic>).map((e) => e.toString()).toList())
                    .toList() ?? [],
                eventData['content'] ?? '',
                eventData['sig'] ?? '',
              );

              if (event.isValid()) {
                claims.add(_RawClaim(
                  pubkey: event.pubkey,
                  content: event.content,
                  createdAt: event.createdAt,
                ));
              }
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) {
                completer.complete(claims.isNotEmpty ? claims : null);
              }
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(claims.isNotEmpty ? claims : null);
        },
      );

      // Query: Alle Kind 30021 Events mit d-Tag "einundzwanzig-admin-claim"
      final request = jsonEncode([
        'REQ',
        subscriptionId,
        {
          'kinds': [_claimKind],
          '#d': [_claimDTag],
          'limit': 100, // Max 100 Claims
        }
      ]);

      ws.add(request);

      final result = await completer.future.timeout(
        _relayTimeout,
        onTimeout: () => claims.isNotEmpty ? claims : null,
      );

      ws.add(jsonEncode(['CLOSE', subscriptionId]));
      return result;

    } catch (e) {
      rethrow;
    } finally {
      try { ws?.close(); } catch (_) {}
    }
  }
}

// =============================================
// DATENKLASSEN
// =============================================

class _RawClaim {
  final String pubkey;
  final String content;
  final int createdAt;

  _RawClaim({
    required this.pubkey,
    required this.content,
    required this.createdAt,
  });
}

class VerifiedClaim {
  final String claimerPubkey;
  final String meetup;
  final int verifiedBadgeCount;
  final int uniqueSignerCount;
  final int claimedAt;

  VerifiedClaim({
    required this.claimerPubkey,
    required this.meetup,
    required this.verifiedBadgeCount,
    required this.uniqueSignerCount,
    required this.claimedAt,
  });
}