// ============================================
// VOUCHING SERVICE — DEZENTRALER ADMIN-KONSENS
// ============================================
//
// PHILOSOPHIE:
//   Niemand "entfernt" einen Admin. Niemand hat Macht
//   über jemand anderen. Admin-Status ist das ERGEBNIS
//   davon, dass genug Peers für dich bürgen.
//
//   Fällt das Vertrauen weg → fällt der Status weg.
//   Wie Bitcoin: Kein Miner wird "gefeuert" — er verliert
//   einfach relativ an Bedeutung.
//
// MODELL:
//   Jeder Admin publiziert: "Für diese npubs bürge ich."
//   Admin-Status = Anzahl Bürgschaften ≥ minVouches
//
// DISTRUST (Kind 21003):
//   Aktives Warnsignal: "Ich warne vor npub X."
//   Ein einzelner Distrust = Info (kein Effekt).
//   Mehrere Distrusts = automatisches Downgrade.
//
// SCHWELLENWERTE (dynamisch):
//   2-5 Admins  → minVouches = 2
//   6-15 Admins → minVouches = 3
//   16+ Admins  → ceil(N × 0.2)
//
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_registry.dart';
import 'app_logger.dart';
import 'nostr_service.dart';
import 'relay_config.dart';
import 'secure_key_store.dart';

// =============================================
// DATENMODELLE
// =============================================

/// Eine Bürgschaft: "Author bürgt für Target"
class Vouch {
  final String authorNpub;   // Wer bürgt
  final String targetNpub;   // Für wen
  final String meetup;       // Welches Meetup
  final String name;         // Anzeigename
  final int timestamp;       // Wann publiziert

  Vouch({
    required this.authorNpub,
    required this.targetNpub,
    this.meetup = '',
    this.name = '',
    this.timestamp = 0,
  });
}

/// Distrust-Meldung: "Author warnt vor Target"
class DistrustReport {
  final String authorNpub;   // Wer meldet
  final String targetNpub;   // Wen
  final String reason;       // Warum (Freitext)
  final int timestamp;       // Wann
  final String eventId;      // Nostr Event-ID

  DistrustReport({
    required this.authorNpub,
    required this.targetNpub,
    this.reason = '',
    this.timestamp = 0,
    this.eventId = '',
  });
}

/// Konsens-Status eines einzelnen npub
class VouchingStatus {
  final String npub;
  final String name;
  final String meetup;
  final int vouchCount;          // Wie viele bürgen für ihn
  final List<String> vouchers;   // Wer bürgt (npubs)
  final int distrustCount;       // Wie viele warnen
  final List<DistrustReport> distrusts; // Details
  final bool isAdmin;            // Erfüllt Schwellenwert
  final bool isSuspended;
  final double effectiveVouchScore;
  final double liabilityPenalty;        // Durch Distrust suspendiert

  VouchingStatus({
    required this.npub,
    this.name = '',
    this.meetup = '',
    this.vouchCount = 0,
    this.vouchers = const [],
    this.distrustCount = 0,
    this.distrusts = const [],
    this.isAdmin = false,
    this.isSuspended = false,
    this.effectiveVouchScore = 0.0,
    this.liabilityPenalty = 0.0,
  });

  /// Effektiver Admin-Status (Admin UND nicht suspendiert)
  bool get isEffectiveAdmin => isAdmin && !isSuspended;

  /// Vertrauenslevel als Prozent (0.0 - 1.0)
  double get trustLevel {
    if (effectiveVouchScore <= 0) return 0.0;
    final minV = VouchingService.minVouchesForNetwork(vouchCount + 5);
    return min(1.0, effectiveVouchScore / max(minV, 1));
  }
}

/// Haftung für Bürgschaften: Wie viele deiner Schützlinge sind problematisch?
class VouchLiability {
  final int totalVouches;       // Gesamt-Bürgschaften die du vergeben hast
  final int suspendedVouches;   // Davon: suspendiert
  final int warnedVouches;      // Davon: gewarnt (aber nicht suspendiert)

  VouchLiability({
    required this.totalVouches,
    required this.suspendedVouches,
    required this.warnedVouches,
  });

  /// Haftungs-Score: 0.0 = sauber, 1.0 = alle Bürgschaften problematisch
  double get score {
    if (totalVouches == 0) return 0.0;
    return ((suspendedVouches * 2 + warnedVouches) / (totalVouches * 2))
        .clamp(0.0, 1.0);
  }

  /// Hat Haftung (mindestens eine problematische Bürgschaft)
  bool get hasLiability => suspendedVouches > 0 || warnedVouches > 0;
}

/// Gesamtbild des Netzwerks
class NetworkConsensus {
  final List<VouchingStatus> allAdmins;
  final int totalVoters;         // Wie viele publizieren Listen
  final int minVouches;          // Aktueller Schwellenwert
  final int distrustThreshold;   // Ab wie vielen Distrusts → Suspension
  final bool isSunset;           // Bootstrap-Phase vorbei?
  final DateTime fetchedAt;

  NetworkConsensus({
    required this.allAdmins,
    required this.totalVoters,
    required this.minVouches,
    required this.distrustThreshold,
    required this.isSunset,
    required this.fetchedAt,
  });

  /// Nur effektive Admins (genug Vouches, nicht suspendiert)
  List<VouchingStatus> get effectiveAdmins =>
      allAdmins.where((a) => a.isEffectiveAdmin).toList();

  /// Suspendierte Admins
  List<VouchingStatus> get suspendedAdmins =>
      allAdmins.where((a) => a.isSuspended).toList();

  /// Admins mit Warnungen (aber noch nicht suspendiert)
  List<VouchingStatus> get warnedAdmins =>
      allAdmins.where((a) => a.distrustCount > 0 && !a.isSuspended).toList();
}

// =============================================
// VOUCHING SERVICE
// =============================================

class VouchingService {
  static const String _tag = 'VouchingService';

  // Nostr Event Kinds
  static const int _adminListKind = 30078;    // Bestehend: Admin-Liste
  static const int _distrustKind = 21003;     // NEU: Distrust-Report
  static const String _adminDTag = 'einundzwanzig-admins';
  static const String _distrustDTag = 'einundzwanzig-distrust';

  // Cache Keys
  static const String _consensusCacheKey = 'vouching_consensus_cache';
  static const String _consensusTimestampKey = 'vouching_consensus_ts';
  static const String _distrustCacheKey = 'distrust_reports_cache';

  // Timeouts
  static const Duration _relayTimeout = Duration(seconds: 8);

  // =============================================
  // SCHWELLENWERT-BERECHNUNG
  // =============================================

  /// Berechnet minVouches basierend auf Netzwerkgröße
  static int minVouchesForNetwork(int totalAdmins) {
    if (totalAdmins <= 1) return 1;    // Allein → Selbstvouch reicht
    if (totalAdmins <= 5) return 2;    // Klein → 2 Bürgen
    if (totalAdmins <= 15) return 3;   // Mittel → 3 Bürgen
    return (totalAdmins * 0.2).ceil(); // Groß → 20% des Netzwerks
  }

  /// Ab wie vielen Distrusts wird jemand suspendiert?
  static int distrustThresholdForNetwork(int totalAdmins) {
    if (totalAdmins <= 5) return 2;    // Klein → 2 Meldungen
    if (totalAdmins <= 15) return 3;   // Mittel → 3 Meldungen
    return (totalAdmins * 0.15).ceil(); // Groß → 15% melden
  }

  // =============================================
  // KONSENS BERECHNEN (Hauptfunktion)
  // =============================================

  /// Sammelt alle Vouching-Listen + Distrust-Reports und berechnet Konsens
  static Future<NetworkConsensus> calculateConsensus({
    bool forceRefresh = false,
  }) async {
    final isSunset = await AdminRegistry.isSunsetActive();

    // 1. Alle Admin-Listen von Relays holen
    final vouchingLists = await _fetchAllVouchingLists();

    // 2. Alle Distrust-Reports holen
    final distrusts = await _fetchAllDistrustReports();

    // 3. Konsens berechnen
    return _buildConsensus(vouchingLists, distrusts, isSunset);
  }

 /// Berechnet Konsens aus gesammelten Daten
  /// NEU: Vouches werden nach Liability des Vouchers gewichtet
  static NetworkConsensus _buildConsensus(
    Map<String, List<AdminEntry>> vouchingLists,
    List<DistrustReport> distrusts,
    bool isSunset,
  ) {
    // Alle einzigartigen npubs die irgendwo gebürgt werden
    final allNpubs = <String>{};
    final vouchMap = <String, List<Vouch>>{}; // npub → wer bürgt für ihn

    for (final entry in vouchingLists.entries) {
      final authorNpub = entry.key;
      for (final admin in entry.value) {
        allNpubs.add(admin.npub);
        vouchMap.putIfAbsent(admin.npub, () => []);
        vouchMap[admin.npub]!.add(Vouch(
          authorNpub: authorNpub,
          targetNpub: admin.npub,
          meetup: admin.meetup,
          name: admin.name,
          timestamp: admin.addedAt,
        ));
      }
    }

    // Auch die Authors selbst sind Teil des Netzwerks
    for (final author in vouchingLists.keys) {
      allNpubs.add(author);
    }

    final totalVoters = vouchingLists.length;
    final totalAdmins = allNpubs.length;
    final minV = minVouchesForNetwork(totalAdmins);
    final distrustThresh = distrustThresholdForNetwork(totalAdmins);

    // Distrust-Reports pro npub gruppieren
    final distrustMap = <String, List<DistrustReport>>{};
    for (final report in distrusts) {
      distrustMap.putIfAbsent(report.targetNpub, () => []);
      distrustMap[report.targetNpub]!.add(report);
    }

    // =============================================
    // NEU: Liability-Berechnung pro Voucher (Phase 1)
    // =============================================
    // Erst alle Suspensionen berechnen (benötigt für Liability)
    final suspendedNpubs = <String>{};
    final warnedNpubs = <String>{};
    for (final npub in allNpubs) {
      final npubDistrusts = distrustMap[npub] ?? [];
      final uniqueDistrusters = npubDistrusts.map((d) => d.authorNpub).toSet();
      if (uniqueDistrusters.length >= distrustThresh) {
        suspendedNpubs.add(npub);
      } else if (uniqueDistrusters.isNotEmpty) {
        warnedNpubs.add(npub);
      }
    }

    // Jetzt Liability pro Voucher berechnen
    // "Wie viele deiner Schützlinge sind suspendiert/gewarnt?"
    final voucherLiability = <String, double>{}; // npub → penalty (0.0 = sauber, 1.0 = alles suspendiert)
    for (final authorNpub in vouchingLists.keys) {
      final myVouches = vouchingLists[authorNpub] ?? [];
      if (myVouches.isEmpty) {
        voucherLiability[authorNpub] = 0.0;
        continue;
      }

      int suspendedCount = 0;
      int warnedCount = 0;
      for (final admin in myVouches) {
        if (suspendedNpubs.contains(admin.npub)) {
          suspendedCount++;
        } else if (warnedNpubs.contains(admin.npub)) {
          warnedCount++;
        }
      }

      // Penalty: suspendiert zählt doppelt
      final penalty = ((suspendedCount * 2 + warnedCount) / (myVouches.length * 2))
          .clamp(0.0, 1.0);
      voucherLiability[authorNpub] = penalty;
    }
    // =============================================
    // ENDE Liability-Berechnung
    // =============================================

    // Status für jeden npub berechnen
    final statuses = <VouchingStatus>[];

    for (final npub in allNpubs) {
      final vouches = vouchMap[npub] ?? [];
      final npubDistrusts = distrustMap[npub] ?? [];

      // Unique Voucher zählen (gleicher Author zählt nur 1x)
      final uniqueVouchers = vouches.map((v) => v.authorNpub).toSet();

      // Unique Distrust-Reporter zählen
      final uniqueDistrusters = npubDistrusts.map((d) => d.authorNpub).toSet();

      // =============================================
      // NEU: Gewichtete Vouch-Stärke berechnen
      // =============================================
      // Ein Voucher mit hoher Liability zählt weniger.
      // Beispiel:
      //   3 Voucher, davon 1 mit 50% Liability
      //   → effectiveScore = 1.0 + 1.0 + 0.5 = 2.5 statt 3.0
      double effectiveVouchScore = 0.0;
      double totalLiabilityPenalty = 0.0;
      for (final voucherNpub in uniqueVouchers) {
        final penalty = voucherLiability[voucherNpub] ?? 0.0;
        final weight = (1.0 - penalty).clamp(0.0, 1.0);
        effectiveVouchScore += weight;
        totalLiabilityPenalty += penalty;
      }
      final avgLiabilityPenalty = uniqueVouchers.isNotEmpty
          ? totalLiabilityPenalty / uniqueVouchers.length
          : 0.0;

      // Admin wenn genug GEWICHTETE Vouches ODER Super-Admin in Pre-Sunset
      // NEU: Verwende effectiveVouchScore statt uniqueVouchers.length
      final hasEnoughVouches = effectiveVouchScore >= minV;
      final isSuperAdmin = !isSunset && npub == AdminRegistry.superAdminNpub;
      final isAdmin = hasEnoughVouches || isSuperAdmin;

      // Suspendiert wenn genug Distrust-Meldungen
      final isSuspended = uniqueDistrusters.length >= distrustThresh;

      // Name + Meetup aus dem neuesten Vouch
      String bestName = '';
      String bestMeetup = '';
      if (vouches.isNotEmpty) {
        final newest = vouches.reduce((a, b) =>
            a.timestamp > b.timestamp ? a : b);
        bestName = newest.name;
        bestMeetup = newest.meetup;
      }

      statuses.add(VouchingStatus(
        npub: npub,
        name: bestName,
        meetup: bestMeetup,
        vouchCount: uniqueVouchers.length,
        vouchers: uniqueVouchers.toList(),
        distrustCount: uniqueDistrusters.length,
        distrusts: npubDistrusts,
        isAdmin: isAdmin,
        isSuspended: isSuspended,
        // NEU: Liability-Daten
        effectiveVouchScore: effectiveVouchScore,
        liabilityPenalty: avgLiabilityPenalty,
      ));
    }

    // Nach effectiveVouchScore sortieren (höchste zuerst)
    statuses.sort((a, b) => b.effectiveVouchScore.compareTo(a.effectiveVouchScore));

    return NetworkConsensus(
      allAdmins: statuses,
      totalVoters: totalVoters,
      minVouches: minV,
      distrustThreshold: distrustThresh,
      isSunset: isSunset,
      fetchedAt: DateTime.now(),
    );
  }


  // =============================================
  // RELAY FETCH: VOUCHING-LISTEN
  // =============================================

  /// Holt alle Admin-Listen (Kind 30078) von bekannten Autoren
  static Future<Map<String, List<AdminEntry>>> _fetchAllVouchingLists() async {
    final result = <String, List<AdminEntry>>{};

    // Alle bekannten Admin-Pubkeys sammeln
    final cachedList = await AdminRegistry.getAdminList();
    final authorsHex = <String>[];

    // Super-Admin immer dabei
    try {
      authorsHex.add(Nip19.decodePubkey(AdminRegistry.superAdminNpub));
    } catch (_) {}

    // Alle bekannten Admins
    for (final admin in cachedList) {
      try {
        final hex = Nip19.decodePubkey(admin.npub);
        if (!authorsHex.contains(hex)) authorsHex.add(hex);
      } catch (_) {}
    }

    if (authorsHex.isEmpty) return result;

    final relays = await RelayConfig.getActiveRelays();

    for (final relayUrl in relays) {
      try {
        final relayResult = await _fetchVouchingFromRelay(relayUrl, authorsHex);
        if (relayResult != null) {
          // Merge: Neueste Version pro Author gewinnt
          for (final entry in relayResult.entries) {
            if (!result.containsKey(entry.key)) {
              result[entry.key] = entry.value;
            }
          }
        }
      } catch (e) {
        AppLogger.debug(_tag, 'Relay $relayUrl Fehler: $e');
      }
    }

    return result;
  }

  static Future<Map<String, List<AdminEntry>>?> _fetchVouchingFromRelay(
    String relayUrl,
    List<String> authorsHex,
  ) async {
    WebSocket? ws;
    final result = <String, List<AdminEntry>>{};

    try {
      ws = await WebSocket.connect(relayUrl).timeout(_relayTimeout);

      final random = Random.secure();
      final subIdHex = List.generate(8, (_) =>
          random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subscriptionId = 'vouch-$subIdHex';

      final completer = Completer<Map<String, List<AdminEntry>>?>();

      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;

            if (msg[0] == 'EVENT' && msg.length >= 3) {
              final eventData = msg[2] as Map<String, dynamic>;
              final authorHex = eventData['pubkey'] as String;

              try {
                final authorNpub = Nip19.encodePubkey(authorHex);
                final content = jsonDecode(eventData['content'] as String)
                    as Map<String, dynamic>;
                final admins = (content['admins'] as List<dynamic>?)
                    ?.map((a) => AdminEntry.fromJson(a as Map<String, dynamic>))
                    .toList() ?? [];

                result[authorNpub] = admins;
              } catch (_) {}
            }

            if (msg[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(result);
            }
          } catch (_) {}
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(result);
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      // REQ senden
      ws.add(jsonEncode([
        'REQ', subscriptionId,
        {
          'kinds': [_adminListKind],
          'authors': authorsHex,
          '#d': [_adminDTag],
        }
      ]));

      final response = await completer.future.timeout(
        _relayTimeout,
        onTimeout: () => result.isEmpty ? null : result,
      );

      ws.add(jsonEncode(['CLOSE', subscriptionId]));
      return response;
    } catch (e) {
      AppLogger.debug(_tag, 'Relay fetch error: $e');
      return null;
    } finally {
      ws?.close();
    }
  }

  // =============================================
  // RELAY FETCH: DISTRUST-REPORTS
  // =============================================

  static Future<List<DistrustReport>> _fetchAllDistrustReports() async {
    final reports = <DistrustReport>[];
    final relays = await RelayConfig.getActiveRelays();
    final seen = <String>{};

    for (final relayUrl in relays) {
      try {
        final relayReports = await _fetchDistrustsFromRelay(relayUrl);
        if (relayReports != null) {
          for (final report in relayReports) {
            // Deduplizierung über Event-ID
            if (!seen.contains(report.eventId)) {
              seen.add(report.eventId);
              reports.add(report);
            }
          }
        }
      } catch (e) {
        AppLogger.debug(_tag, 'Distrust fetch $relayUrl: $e');
      }
    }

    return reports;
  }

  static Future<List<DistrustReport>?> _fetchDistrustsFromRelay(
    String relayUrl,
  ) async {
    WebSocket? ws;
    final reports = <DistrustReport>[];

    try {
      ws = await WebSocket.connect(relayUrl).timeout(_relayTimeout);

      final random = Random.secure();
      final subIdHex = List.generate(8, (_) =>
          random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subscriptionId = 'distrust-$subIdHex';

      final completer = Completer<List<DistrustReport>?>();

      ws.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;

            if (msg[0] == 'EVENT' && msg.length >= 3) {
              final event = msg[2] as Map<String, dynamic>;
              final authorHex = event['pubkey'] as String;

              try {
                final content = jsonDecode(event['content'] as String)
                    as Map<String, dynamic>;

                reports.add(DistrustReport(
                  authorNpub: Nip19.encodePubkey(authorHex),
                  targetNpub: content['target_npub'] as String? ?? '',
                  reason: content['reason'] as String? ?? '',
                  timestamp: event['created_at'] as int? ?? 0,
                  eventId: event['id'] as String? ?? '',
                ));
              } catch (_) {}
            }

            if (msg[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(reports);
            }
          } catch (_) {}
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(reports);
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      ws.add(jsonEncode([
        'REQ', subscriptionId,
        {
          'kinds': [_distrustKind],
          '#d': [_distrustDTag],
        }
      ]));

      final response = await completer.future.timeout(
        _relayTimeout,
        onTimeout: () => reports.isEmpty ? null : reports,
      );

      ws.add(jsonEncode(['CLOSE', subscriptionId]));
      return response;
    } catch (e) {
      return null;
    } finally {
      ws?.close();
    }
  }

  // =============================================
  // DISTRUST-REPORT PUBLIZIEREN
  // =============================================

  /// Publiziert einen Distrust-Report für einen npub.
  /// Jeder Admin kann das — aber ein einzelner Report reicht nicht
  /// für eine Suspendierung. Erst bei Konsens (N Meldungen) greift es.
  static Future<int> publishDistrust({
    required String targetNpub,
    required String reason,
  }) async {
    final privHex = await SecureKeyStore.getPrivHex();
    if (privHex == null) throw Exception('Kein Nostr-Key vorhanden.');
    if (!NostrService.isValidNpub(targetNpub)) {
      throw Exception('Ungültiger npub.');
    }
    if (reason.trim().isEmpty) {
      throw Exception('Bitte gib einen Grund an.');
    }

    // Eigenen npub prüfen — man kann sich nicht selbst melden
    final myNpub = await NostrService.getNpub();
    if (myNpub == targetNpub) {
      throw Exception('Du kannst dich nicht selbst melden.');
    }

    final content = jsonEncode({
      'target_npub': targetNpub,
      'reason': reason.trim(),
      'reported_at': DateTime.now().toIso8601String(),
    });

    final event = Event.from(
      kind: _distrustKind,
      tags: [
        ['d', _distrustDTag],
        ['p', Nip19.decodePubkey(targetNpub)],
      ],
      content: content,
      privkey: privHex,
    );

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

    int successCount = 0;
    final relays = await RelayConfig.getActiveRelays();

    for (final relayUrl in relays) {
      try {
        final ws = await WebSocket.connect(relayUrl).timeout(
          const Duration(seconds: 5),
        );
        ws.add(eventJson);

        bool confirmed = false;
        try {
          await for (final data in ws.timeout(const Duration(seconds: 5))) {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg[0] == 'OK' && msg.length >= 3) {
              confirmed = msg[2] == true;
              break;
            }
          }
        } catch (_) {}
        ws.close();

        if (confirmed) successCount++;
      } catch (e) {
        AppLogger.debug(_tag, 'Distrust publish $relayUrl: $e');
      }
    }

    if (successCount == 0) {
      throw Exception('Distrust-Report konnte an keinen Relay gesendet werden.');
    }

    AppLogger.security(_tag,
        'Distrust-Report publiziert für ${NostrService.shortenNpub(targetNpub)} '
        'an $successCount Relays. Grund: ${reason.substring(0, min(50, reason.length))}');

    return successCount;
  }

  // =============================================
  // HILFSFUNKTIONEN
  // =============================================

  /// Prüft ob ein bestimmter npub aktuell effektiver Admin ist
  static Future<bool> isEffectiveAdmin(String npub) async {
    final consensus = await calculateConsensus();
    final status = consensus.allAdmins.where((a) => a.npub == npub).firstOrNull;
    return status?.isEffectiveAdmin ?? false;
  }

  /// Holt den Status eines einzelnen npub
  static Future<VouchingStatus?> getStatus(String npub) async {
    final consensus = await calculateConsensus();
    return consensus.allAdmins.where((a) => a.npub == npub).firstOrNull;
  }

  // =============================================
  // BÜRGSCHAFTS-HAFTUNG (Vouch Liability)
  // =============================================
  //
  // PRINZIP:
  //   Wer für einen bösen Akteur bürgt, trägt Konsequenzen.
  //   Das verhindert, dass jemand leichtfertig 15 Fake-Admins ernennt.
  //
  //   Konsequenz 1: Warnhinweis im Dashboard ("Du bürgst für suspendierte npubs")
  //   Konsequenz 2: Bürgschaften eines Admins mit hohem Liability-Score
  //                 werden in der Konsens-Berechnung niedriger gewichtet
  //   Konsequenz 3: Andere Admins sehen die Liability und können
  //                 ihrerseits das Vertrauen entziehen
  //
  // =============================================

  /// Berechnet die Haftung eines npub: Wie viele seiner Bürgschaften
  /// gehen an suspendierte oder gewarnte Admins?
  static Future<VouchLiability> calculateLiability(String npub) async {
    final consensus = await calculateConsensus();

    // Finde alle npubs für die dieser Admin bürgt
    final myStatus = consensus.allAdmins
        .where((a) => a.npub == npub).firstOrNull;

    if (myStatus == null) {
      return VouchLiability(totalVouches: 0, suspendedVouches: 0, warnedVouches: 0);
    }

    // Finde alle npubs die von diesem Admin eine Bürgschaft haben
    int suspendedCount = 0;
    int warnedCount = 0;
    int totalCount = 0;

    for (final admin in consensus.allAdmins) {
      if (admin.vouchers.contains(npub)) {
        totalCount++;
        if (admin.isSuspended) suspendedCount++;
        else if (admin.distrustCount > 0) warnedCount++;
      }
    }

    return VouchLiability(
      totalVouches: totalCount,
      suspendedVouches: suspendedCount,
      warnedVouches: warnedCount,
    );
  }
}
