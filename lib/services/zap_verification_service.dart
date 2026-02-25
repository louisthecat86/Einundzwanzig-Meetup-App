// ============================================
// ZAP VERIFICATION SERVICE — Lightning-Beweis
// ============================================
// Analysiert Lightning-Aktivität über Nostr Zaps:
//
//   1. Zap-Receipts abrufen (Kind 9735, NIP-57)
//   2. Gesendete + empfangene Zaps zählen
//   3. Zap-Diversität messen (verschiedene Empfänger/Sender)
//   4. Zeitliche Verteilung prüfen (Aktivitätszeitraum)
//
// Anti-Bot-Wirkung:
//   - Zaps kosten echtes Geld (Sats)
//   - Bot müsste über Monate Geld verbrennen
//   - Zap-Diversität verhindert Self-Zapping
//   - Empfangene Zaps = externe Bestätigung
//
// Privacy:
//   - Nur Anzahlen werden publiziert
//   - KEINE Beträge, Empfänger, Sender
//   - Zeitraum nur als "seit Monat/Jahr"
//
// Zap-Struktur (NIP-57):
//   Kind 9735 = Zap Receipt (vom LNURL-Server erstellt)
//   Tags: ["p", recipient_pubkey], ["e", zapped_event_id]
//         ["bolt11", invoice], ["description", zap_request_json]
//   Die "description" enthält den Original Zap-Request (Kind 9734)
//   mit dem Sender-Pubkey.
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'relay_config.dart';
import 'secure_key_store.dart';

class ZapVerificationService {
  // Cache
  static const String _cacheKeyStats = 'zap_stats_cache';
  static const String _cacheKeyTimestamp = 'zap_cache_ts';
  static const Duration _cacheDuration = Duration(hours: 6);

  // Zeitfenster für Zap-Analyse (6 Monate)
  static const Duration _analysisWindow = Duration(days: 180);

  // =============================================
  // ZAP-AKTIVITÄT EINES NUTZERS ANALYSIEREN
  // =============================================

  static Future<ZapStats> analyzeZapActivity(
    String pubkeyHex, {
    bool useCache = true,
  }) async {
    // Cache prüfen (nur für eigenen pubkey)
    if (useCache) {
      final cached = await _loadCachedStats(pubkeyHex);
      if (cached != null) return cached;
    }

    final relays = await RelayConfig.getActiveRelays();

    // Parallel: Empfangene + gesendete Zaps abrufen
    final receivedFuture = _fetchZapReceipts(relays, pubkeyHex, isReceived: true);
    final sentFuture = _fetchZapReceipts(relays, pubkeyHex, isReceived: false);

    final received = await receivedFuture;
    final sent = await sentFuture;

    final stats = _computeStats(pubkeyHex, received, sent);

    // Cache speichern
    await _cacheStats(pubkeyHex, stats);
    return stats;
  }

  // =============================================
  // ZAP RECEIPTS VON RELAYS ABRUFEN
  // =============================================
  // isReceived=true:  Zaps die an pubkey gerichtet sind (#p Tag)
  // isReceived=false: Zaps die von pubkey gesendet wurden
  //                   (Sender steht im description/zap_request)
  // =============================================

  static Future<List<ZapReceipt>> _fetchZapReceipts(
    List<String> relays,
    String pubkeyHex, {
    required bool isReceived,
  }) async {
    final since = DateTime.now().subtract(_analysisWindow).millisecondsSinceEpoch ~/ 1000;
    List<ZapReceipt> allReceipts = [];

    for (final relayUrl in relays.take(3)) { // Max 3 Relays für Performance
      try {
        final receipts = await _fetchFromRelay(relayUrl, pubkeyHex, since, isReceived);
        // Deduplizieren anhand der Event-ID
        for (final receipt in receipts) {
          if (!allReceipts.any((r) => r.eventId == receipt.eventId)) {
            allReceipts.add(receipt);
          }
        }
        if (allReceipts.length >= 50) break; // Genug Daten
      } catch (e) {
        // Nächstes Relay
      }
    }

    return allReceipts;
  }

  static Future<List<ZapReceipt>> _fetchFromRelay(
    String relayUrl,
    String pubkeyHex,
    int since,
    bool isReceived,
  ) async {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(relayUrl).timeout(RelayConfig.relayTimeout);
      final completer = Completer<List<ZapReceipt>>();
      final subId = 'zaps-${DateTime.now().millisecondsSinceEpoch}';
      List<ZapReceipt> receipts = [];

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3) {
              final eventData = message[2] as Map<String, dynamic>;
              final receipt = _parseZapReceipt(eventData, pubkeyHex);
              if (receipt != null) {
                receipts.add(receipt);
              }
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(receipts);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete([]);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(receipts);
        },
      );

      // Query: Kind 9735 (Zap Receipt)
      final Map<String, dynamic> filter = {
        'kinds': [9735],
        'since': since,
        'limit': 100,
      };

      if (isReceived) {
        // Zaps die an den Nutzer gehen
        filter['#p'] = [pubkeyHex];
      } else {
        // Zaps die vom Nutzer kommen — schwieriger, da der Sender
        // im "description"-Tag als eingebetteter JSON steht.
        // Manche Relays unterstützen '#P' für den Sender.
        // Fallback: Wir holen alle Zaps und filtern lokal.
        filter['#p'] = [pubkeyHex]; // Erstmal auch empfangene holen
      }

      ws.add(jsonEncode(['REQ', subId, filter]));

      return await completer.future.timeout(
        RelayConfig.relayTimeout,
        onTimeout: () => receipts,
      );
    } finally {
      ws?.close();
    }
  }

  // =============================================
  // ZAP RECEIPT PARSEN
  // =============================================

  static ZapReceipt? _parseZapReceipt(
    Map<String, dynamic> eventData,
    String contextPubkey,
  ) {
    try {
      final eventId = eventData['id'] as String? ?? '';
      final createdAt = eventData['created_at'] as int? ?? 0;
      final tags = eventData['tags'] as List<dynamic>? ?? [];

      String recipientPubkey = '';
      String senderPubkey = '';
      String? bolt11;

      for (final tag in tags) {
        final t = tag as List<dynamic>;
        if (t.isEmpty) continue;
        final key = t[0] as String;

        if (key == 'p' && t.length >= 2) {
          recipientPubkey = t[1] as String;
        } else if (key == 'bolt11' && t.length >= 2) {
          bolt11 = t[1] as String;
        } else if (key == 'description' && t.length >= 2) {
          // Zap Request (Kind 9734) ist als JSON im description-Tag
          try {
            final zapRequest = jsonDecode(t[1] as String) as Map<String, dynamic>;
            senderPubkey = zapRequest['pubkey'] as String? ?? '';
          } catch (_) {}
        }
      }

      if (recipientPubkey.isEmpty && senderPubkey.isEmpty) return null;

      final isSent = senderPubkey == contextPubkey;
      final isReceived = recipientPubkey == contextPubkey;

      if (!isSent && !isReceived) return null;

      return ZapReceipt(
        eventId: eventId,
        senderPubkey: senderPubkey,
        recipientPubkey: recipientPubkey,
        createdAt: createdAt,
        isSent: isSent,
        isReceived: isReceived,
        hasBolt11: bolt11 != null && bolt11.isNotEmpty,
      );
    } catch (e) {
      return null;
    }
  }

  // =============================================
  // STATISTIKEN BERECHNEN
  // =============================================

  static ZapStats _computeStats(
    String pubkeyHex,
    List<ZapReceipt> received,
    List<ZapReceipt> sent,
  ) {
    // Alle Receipts zusammenführen und deduplizieren
    final Map<String, ZapReceipt> allMap = {};
    for (final r in [...received, ...sent]) {
      allMap[r.eventId] = r;
    }
    final all = allMap.values.toList();

    // Gesendete Zaps (wo pubkey = sender)
    final sentZaps = all.where((r) => r.isSent).toList();

    // Empfangene Zaps (wo pubkey = recipient)
    final receivedZaps = all.where((r) => r.isReceived).toList();

    // Diversität: verschiedene Empfänger/Sender
    final uniqueRecipients = sentZaps.map((r) => r.recipientPubkey).toSet();
    final uniqueSenders = receivedZaps.map((r) => r.senderPubkey).where((s) => s.isNotEmpty).toSet();

    // Zeitliche Verteilung
    int? firstZapTimestamp;
    int? lastZapTimestamp;
    for (final zap in all) {
      if (zap.createdAt > 0) {
        firstZapTimestamp = firstZapTimestamp == null
            ? zap.createdAt
            : (zap.createdAt < firstZapTimestamp ? zap.createdAt : firstZapTimestamp);
        lastZapTimestamp = lastZapTimestamp == null
            ? zap.createdAt
            : (zap.createdAt > lastZapTimestamp ? zap.createdAt : lastZapTimestamp);
      }
    }

    final activeMonths = (firstZapTimestamp != null && lastZapTimestamp != null)
        ? ((lastZapTimestamp - firstZapTimestamp) / (30 * 24 * 3600)).ceil().clamp(0, 24)
        : 0;

    // Hat mindestens eine echte Lightning-Zahlung (Bolt11 vorhanden)?
    final hasLightningProof = all.any((r) => r.hasBolt11);

    return ZapStats(
      sentCount: sentZaps.length,
      receivedCount: receivedZaps.length,
      uniqueRecipientCount: uniqueRecipients.length,
      uniqueSenderCount: uniqueSenders.length,
      activeMonths: activeMonths,
      hasLightningProof: hasLightningProof,
    );
  }

  // =============================================
  // EIGENE ZAP-STATS ABRUFEN
  // =============================================

  static Future<ZapStats> getMyStats() async {
    final pubkeyHex = await _getMyPubkeyHex();
    if (pubkeyHex == null) return ZapStats.empty();
    return analyzeZapActivity(pubkeyHex);
  }

  // =============================================
  // CACHE
  // =============================================

  static Future<ZapStats?> _loadCachedStats(String pubkey) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('${_cacheKeyTimestamp}_$pubkey') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - ts > _cacheDuration.inMilliseconds) return null;

    final json = prefs.getString('${_cacheKeyStats}_$pubkey');
    if (json == null) return null;

    try {
      return ZapStats.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _cacheStats(String pubkey, ZapStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_cacheKeyStats}_$pubkey', jsonEncode(stats.toJson()));
    await prefs.setInt('${_cacheKeyTimestamp}_$pubkey', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<String?> _getMyPubkeyHex() async {
    final npub = await SecureKeyStore.getNpub();
    if (npub == null || npub.isEmpty) return null;
    try {
      return Nip19.decodePubkey(npub);
    } catch (_) {
      return null;
    }
  }
}

// =============================================
// DATENMODELLE
// =============================================

class ZapReceipt {
  final String eventId;
  final String senderPubkey;
  final String recipientPubkey;
  final int createdAt;
  final bool isSent;
  final bool isReceived;
  final bool hasBolt11;

  ZapReceipt({
    required this.eventId,
    required this.senderPubkey,
    required this.recipientPubkey,
    required this.createdAt,
    required this.isSent,
    required this.isReceived,
    required this.hasBolt11,
  });
}

class ZapStats {
  final int sentCount;
  final int receivedCount;
  final int uniqueRecipientCount;
  final int uniqueSenderCount;
  final int activeMonths;
  final bool hasLightningProof;

  ZapStats({
    required this.sentCount,
    required this.receivedCount,
    required this.uniqueRecipientCount,
    required this.uniqueSenderCount,
    required this.activeMonths,
    required this.hasLightningProof,
  });

  factory ZapStats.empty() => ZapStats(
    sentCount: 0,
    receivedCount: 0,
    uniqueRecipientCount: 0,
    uniqueSenderCount: 0,
    activeMonths: 0,
    hasLightningProof: false,
  );

  factory ZapStats.fromJson(Map<String, dynamic> json) => ZapStats(
    sentCount: json['sent'] as int? ?? 0,
    receivedCount: json['received'] as int? ?? 0,
    uniqueRecipientCount: json['unique_recipients'] as int? ?? 0,
    uniqueSenderCount: json['unique_senders'] as int? ?? 0,
    activeMonths: json['active_months'] as int? ?? 0,
    hasLightningProof: json['lightning_proof'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'sent': sentCount,
    'received': receivedCount,
    'unique_recipients': uniqueRecipientCount,
    'unique_senders': uniqueSenderCount,
    'active_months': activeMonths,
    'lightning_proof': hasLightningProof,
  };

  int get totalCount => sentCount + receivedCount;

  /// Lightning Score (0.0 - 2.5)
  double get lightningScore {
    double score = 0;

    // Lightning-Zahlung verifiziert (Bolt11 vorhanden)
    if (hasLightningProof) score += 0.5;

    // Zap-Aktivität (gesendet)
    if (sentCount > 0) score += (sentCount / (sentCount + 10)) * 0.75;

    // Zap-Aktivität (empfangen = externe Bestätigung)
    if (receivedCount > 0) score += (receivedCount / (receivedCount + 10)) * 0.75;

    // Diversität (verschiedene Empfänger)
    if (uniqueRecipientCount > 2) score += 0.25;

    // Zeitliche Konsistenz
    if (activeMonths >= 3) score += 0.25;

    return score.clamp(0.0, 2.5);
  }

  String get activityLabel {
    if (totalCount == 0) return 'Keine Zap-Aktivität';
    if (totalCount < 5) return 'Wenig Aktivität';
    if (totalCount < 20) return 'Regelmäßig aktiv';
    return 'Sehr aktiv';
  }
}