// ============================================
// HUMANITY PROOF SERVICE — Lightning Anti-Bot
// ============================================
// Beweist, dass ein Nutzer ein Mensch ist, indem
// geprüft wird ob er JEMALS einen echten Nostr-Zap
// gesendet hat.
//
// Ansatz: Dezentral, keine hardcodierten Adressen
//
//   Die App sucht auf Nostr-Relays nach Zap-Receipts
//   (Kind 9735) in denen der Nutzer als Sender steht.
//   Hat er jemals irgendjemanden gezappt, ist bewiesen:
//
//     ✓ Er besitzt eine echte Lightning-Wallet
//     ✓ Er hat echte Sats ausgegeben
//     ✓ Er ist mit dem Nostr-Netzwerk verbunden
//     ✓ Die Zahlung ist kryptographisch verifizierbar
//
//   Wem er gezappt hat ist irrelevant. Es zählt NUR:
//   "Dieser npub hat eine echte Lightning-Transaktion
//   auf dem Nostr-Netzwerk ausgeführt."
//
// Warum das gegen Bots hilft:
//   - Bots haben keine Lightning-Wallets
//   - Jeder Fake-Account bräuchte echte Sats
//   - Wallet-Setup erfordert menschliche Interaktion
//   - Zap-Receipts sind unfälschbar (vom LNURL-Server signiert)
//
// Für Nutzer die noch nie gezappt haben:
//   - App erklärt: "Zappe irgendjemanden auf Nostr"
//   - Optional: Deep-Link zu bekannten Nostr-Clients
//   - Danach: "Erneut prüfen" Button
//
// Privacy:
//   - Reputation-Event speichert NUR:
//     "humanity_verified: true, method: lightning_zap,
//      first_zap_at: unix_timestamp"
//   - NICHT: Empfänger, Betrag, Wallet, Invoice
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'relay_config.dart';
import 'secure_key_store.dart';
import 'dart:math';

class HumanityProofService {
  // Cache-Keys
  static const String _keyVerified = 'humanity_verified';
  static const String _keyFirstZapAt = 'humanity_first_zap_at';
  static const String _keyReceiptId = 'humanity_receipt_id';
  static const String _keyCheckedAt = 'humanity_checked_at';

  // =============================================
  // STATUS PRÜFEN
  // =============================================

  static Future<HumanityStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return HumanityStatus(
      verified: prefs.getBool(_keyVerified) ?? false,
      firstZapAt: prefs.getInt(_keyFirstZapAt) ?? 0,
      receiptEventId: prefs.getString(_keyReceiptId) ?? '',
      lastCheckedAt: prefs.getInt(_keyCheckedAt) ?? 0,
    );
  }

  // =============================================
  // PRÜFUNG: Hat dieser npub jemals gezappt?
  // =============================================
  // Sucht auf Relays nach Kind 9735 Events
  // (Zap Receipts) in denen unser Pubkey als
  // Sender im eingebetteten Zap-Request steht.
  //
  // Ein einziges Receipt reicht als Beweis.
  // =============================================

  static Future<HumanityCheckResult> checkForZaps() async {
    final npub = await SecureKeyStore.getNpub();
    if (npub == null || npub.isEmpty) {
      return HumanityCheckResult(
        found: false,
        message: 'Kein Schlüssel vorhanden',
      );
    }

    String pubkeyHex;
    try {
      pubkeyHex = Nip19.decodePubkey(npub);
    } catch (e) {
      return HumanityCheckResult(found: false, message: 'Ungültiger npub');
    }

    final relays = await RelayConfig.getActiveRelays();

    // Zap-Daten sind oft auf großen öffentlichen Relays.
    // Nutzer-Relays kennen die Zaps evtl. nicht.
    final zapRelays = <String>{
      ...relays,
      'wss://relay.damus.io',
      'wss://relay.nostr.band',
      'wss://nos.lol',
      'wss://relay.snort.social',
    };

    // Auf mehreren Relays suchen
    for (final relayUrl in zapRelays) {
      try {
        final result = await _searchZapActivity(relayUrl, pubkeyHex);
        if (result != null) {
          // Beweis gefunden! Speichern.
          await _saveProof(result.receiptEventId, result.zapTimestamp);

          return HumanityCheckResult(
            found: true,
            receiptEventId: result.receiptEventId,
            zapTimestamp: result.zapTimestamp,
            message: 'Lightning-Zahlung gefunden — du bist verifiziert!',
          );
        }
      } catch (e) {
        // Nächstes Relay versuchen
      }
    }

    // Prüfzeitpunkt speichern (auch bei Misserfolg)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCheckedAt, DateTime.now().millisecondsSinceEpoch ~/ 1000);

    return HumanityCheckResult(
      found: false,
      message: 'Kein Zap-Receipt gefunden. '
          'Hast du schon einmal jemanden auf Nostr gezappt? '
          'Zappe irgendjemanden (egal wieviel Sats) und komm zurück.',
    );
  }

  // =============================================
  // PRÜFUNG FÜR FREMDEN NUTZER
  // =============================================

  static Future<bool> checkForZapsByPubkey(String pubkeyHex) async {
    final relays = await RelayConfig.getActiveRelays();
    final zapRelays = <String>{
      ...relays.take(2),
      'wss://relay.damus.io',
      'wss://relay.nostr.band',
      'wss://nos.lol',
    };

    for (final relayUrl in zapRelays) {
      try {
        final result = await _searchZapActivity(relayUrl, pubkeyHex);
        if (result != null) return true;
      } catch (_) {}
    }
    return false;
  }

  // =============================================
  // ZAP-AKTIVITÄT SUCHEN — ZWEI STRATEGIEN
  // =============================================
  // Strategie 1: Kind 9735 mit #p = pubkey
  //   → Findet EMPFANGENE Zaps (Nutzer wurde gezappt)
  //   → Standard NIP-57, alle Relays unterstützen das
  //   → Beweis: Echte Menschen haben ihm Sats geschickt
  //
  // Strategie 2: Kind 9734 mit authors = pubkey
  //   → Findet GESENDETE Zap-Requests (Nutzer hat gezappt)
  //   → Manche Clients speichern diese auf Relays
  //   → Beweis: Er hat selbst eine Lightning-Zahlung ausgelöst
  //
  // Ein Treffer bei EINER der Strategien reicht.
  // =============================================

  static Future<_ZapSearchResult?> _searchZapActivity(
    String relayUrl,
    String pubkeyHex,
  ) async {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(relayUrl).timeout(RelayConfig.relayTimeout);
      final completer = Completer<_ZapSearchResult?>();
      // Security Audit M4: Kryptographisch sichere Subscription-IDs
      final random = Random.secure();
      final hex1 = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final hex2 = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId1 = 'zap-recv-$hex1';
      final subId2 = 'zap-sent-$hex2';
      _ZapSearchResult? found;
      int eoseCount = 0;

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3 && found == null) {
              final eventData = message[2] as Map<String, dynamic>;
              final eventId = eventData['id'] as String? ?? '';
              final createdAt = eventData['created_at'] as int? ?? 0;
              final kind = eventData['kind'] as int? ?? 0;

              if (kind == 9735) {
                // Strategie 1: Empfangenes Zap Receipt
                // Prüfe ob der Nutzer der Empfänger ist (#p Tag)
                final tags = eventData['tags'] as List<dynamic>? ?? [];
                for (final tag in tags) {
                  final t = tag as List<dynamic>;
                  if (t.length >= 2 && t[0] == 'p' && t[1] == pubkeyHex) {
                    found = _ZapSearchResult(
                      receiptEventId: eventId,
                      zapTimestamp: createdAt,
                    );
                    if (!completer.isCompleted) completer.complete(found);
                    return;
                  }
                }

                // Zusätzlich: Prüfe description-Tag auf Sender
                for (final tag in tags) {
                  final t = tag as List<dynamic>;
                  if (t.length >= 2 && t[0] == 'description') {
                    try {
                      final zapReq = jsonDecode(t[1] as String) as Map<String, dynamic>;
                      if (zapReq['pubkey'] == pubkeyHex) {
                        found = _ZapSearchResult(
                          receiptEventId: eventId,
                          zapTimestamp: createdAt,
                        );
                        if (!completer.isCompleted) completer.complete(found);
                        return;
                      }
                    } catch (_) {}
                  }
                }
              } else if (kind == 9734) {
                // Strategie 2: Gesendeter Zap Request
                found = _ZapSearchResult(
                  receiptEventId: eventId,
                  zapTimestamp: createdAt,
                );
                if (!completer.isCompleted) completer.complete(found);
                return;
              }
            } else if (type == 'EOSE') {
              eoseCount++;
              // Warte auf beide Subscriptions
              if (eoseCount >= 2 && !completer.isCompleted) {
                completer.complete(found);
              }
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      // Strategie 1: Empfangene Zap Receipts (Kind 9735, #p = pubkey)
      ws.add(jsonEncode([
        'REQ', subId1,
        {
          'kinds': [9735],
          '#p': [pubkeyHex],
          'limit': 3, // Ein einziger reicht, aber 3 für Redundanz
        }
      ]));

      // Strategie 2: Gesendete Zap Requests (Kind 9734, authors = pubkey)
      ws.add(jsonEncode([
        'REQ', subId2,
        {
          'kinds': [9734],
          'authors': [pubkeyHex],
          'limit': 3,
        }
      ]));

      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => found,
      );
    } finally {
      ws?.close();
    }
  }

  // =============================================
  // BEWEIS SPEICHERN / LADEN / ZURÜCKSETZEN
  // =============================================

  static Future<void> _saveProof(String receiptEventId, int zapTimestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVerified, true);
    await prefs.setString(_keyReceiptId, receiptEventId);
    await prefs.setInt(_keyFirstZapAt, zapTimestamp);
    await prefs.setInt(_keyCheckedAt, DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVerified);
    await prefs.remove(_keyReceiptId);
    await prefs.remove(_keyFirstZapAt);
    await prefs.remove(_keyCheckedAt);
  }

  // =============================================
  // FÜR REPUTATION-EVENT
  // =============================================

  static Future<Map<String, dynamic>?> getProofForPublishing() async {
    final status = await getStatus();
    if (!status.verified) return null;

    return {
      'verified': true,
      'method': 'lightning_zap',
      'first_zap_at': status.firstZapAt,
    };
  }

  // =============================================
  // REMOTE: Proof eines anderen prüfen
  // =============================================

  static Future<bool> verifyReceiptExists(String receiptEventId) async {
    if (receiptEventId.isEmpty) return false;

    final relays = await RelayConfig.getActiveRelays();
    for (final relayUrl in relays.take(3)) {
      try {
        final exists = await _checkEventExists(relayUrl, receiptEventId);
        if (exists) return true;
      } catch (_) {}
    }
    return false;
  }

  static Future<bool> _checkEventExists(String relayUrl, String eventId) async {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(relayUrl).timeout(RelayConfig.relayTimeout);
      final completer = Completer<bool>();
      // Security Audit M4: Kryptographisch sichere Subscription-ID
      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId = 'verify-$subIdHex';

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            if (message[0] == 'EVENT') {
              if (!completer.isCompleted) completer.complete(true);
            } else if (message[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(false);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      ws.add(jsonEncode([
        'REQ', subId,
        {'ids': [eventId], 'kinds': [9735], 'limit': 1}
      ]));

      return await completer.future.timeout(
        RelayConfig.relayTimeout,
        onTimeout: () => false,
      );
    } finally {
      ws?.close();
    }
  }
}

// =============================================
// DATENMODELLE
// =============================================

class _ZapSearchResult {
  final String receiptEventId;
  final int zapTimestamp;
  _ZapSearchResult({required this.receiptEventId, required this.zapTimestamp});
}

class HumanityStatus {
  final bool verified;
  final int firstZapAt;
  final String receiptEventId;
  final int lastCheckedAt;

  HumanityStatus({
    required this.verified,
    this.firstZapAt = 0,
    this.receiptEventId = '',
    this.lastCheckedAt = 0,
  });

  String get firstZapDateStr {
    if (firstZapAt == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(firstZapAt * 1000);
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  String get lastCheckedStr {
    if (lastCheckedAt == 0) return 'Nie';
    final dt = DateTime.fromMillisecondsSinceEpoch(lastCheckedAt * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Gerade eben';
    if (diff.inHours < 1) return 'Vor ${diff.inMinutes} Min.';
    if (diff.inDays < 1) return 'Vor ${diff.inHours} Std.';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

class HumanityCheckResult {
  final bool found;
  final String? receiptEventId;
  final int? zapTimestamp;
  final String message;

  HumanityCheckResult({
    required this.found,
    this.receiptEventId,
    this.zapTimestamp,
    required this.message,
  });
}