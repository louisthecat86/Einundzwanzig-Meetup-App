// ============================================
// REPUTATION PUBLISHER — Automatisches Relay-Publishing
// ============================================
// Publiziert die Reputation als Nostr-Event auf Relays.
// Passiert automatisch im Hintergrund nach jedem Badge.
//
// DATENSCHUTZ:
//   - NUR aggregierte Zahlen auf Relays (Score, Anzahl Badges, etc.)
//   - KEINE Meetup-Namen, Orte, Besuchsdaten
//   - badge_proof_hash beweist kryptographisch ohne Details zu verraten
//   - Plattform-Proofs nur wenn Nutzer explizit erstellt
//
// Nostr Event: Kind 30078 (Parameterized Replaceable)
//   d-Tag: "einundzwanzig-reputation"
//   → Überschreibt sich bei jedem Update automatisch
//
// Abhängigkeiten:
//   - nostr Package (Event, Nip19)
//   - SecureKeyStore (privater Schlüssel)
//   - MeetupBadge (Badge-Daten)
//   - RelayConfig (Relay-URLs)
//   - BadgeSecurity (Kanonisierung)
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import '../models/badge.dart';
import '../models/user.dart';
import 'badge_security.dart';
import 'relay_config.dart';
import 'secure_key_store.dart';
import 'social_graph_service.dart';
import 'zap_verification_service.dart';
import 'humanity_proof_service.dart';
import 'app_logger.dart';

class ReputationPublisher {
  // Nostr Event Konfiguration
  static const int _eventKind = 30078;
  static const String _eventDTag = 'einundzwanzig-reputation';
  static const int _protocolVersion = 2;

  // Cache Keys (letzter Publish-Status)
  static const String _lastPublishKey = 'reputation_last_publish';
  static const String _lastPublishHashKey = 'reputation_last_hash';

  // Minimum-Intervall zwischen Publishes (Spam-Schutz)
  static const Duration _minPublishInterval = Duration(minutes: 5);

  // =============================================
  // REPUTATION PUBLIZIEREN
  // =============================================
  // Erstellt ein Nostr-Event mit der aktuellen Reputation
  // und sendet es an alle aktiven Relays.
  //
  // Wird aufgerufen:
  //   - Nach jedem Badge-Scan (automatisch)
  //   - Nach Profil-Änderungen
  //   - Manuell über Reputation-Screen
  //
  // Returns: Anzahl der Relays an die gesendet wurde
  // =============================================

  static Future<PublishResult> publish({
    required List<MeetupBadge> badges,
    Map<String, PlatformProof>? platformProofs,
    bool force = false,
  }) async {
    try {
      // Privaten Schlüssel laden
      final privHex = await SecureKeyStore.getPrivHex();
      if (privHex == null || privHex.isEmpty) {
        return PublishResult(
          success: false,
          relayCount: 0,
          message: 'Kein Schlüssel vorhanden',
        );
      }

      // Keine Badges → nichts zu publizieren
      if (badges.isEmpty) {
        return PublishResult(
          success: false,
          relayCount: 0,
          message: 'Keine Badges vorhanden',
        );
      }

      // Spam-Schutz: Nicht öfter als alle 5 Minuten
      if (!force) {
        final shouldPublish = await _shouldPublish(badges);
        if (!shouldPublish) {
          return PublishResult(
            success: true,
            relayCount: 0,
            message: 'Reputation ist aktuell — kein Update nötig',
          );
        }
      }

      // User-Profil laden
      final user = await UserProfile.load();

      // Social & Lightning Stats im Hintergrund laden (optional, best-effort)
      SocialStats? socialStats;
      ZapStats? zapStats;
      try {
        socialStats = await SocialGraphService.getMyStats()
            .timeout(const Duration(seconds: 10), onTimeout: () => SocialStats.empty());
      } catch (_) {}
      try {
        zapStats = await ZapVerificationService.getMyStats()
            .timeout(const Duration(seconds: 10), onTimeout: () => ZapStats.empty());
      } catch (_) {}

      // Humanity-Proof laden (lokal gespeichert)
      Map<String, dynamic>? humanityProof;
      try {
        humanityProof = await HumanityProofService.getProofForPublishing();
      } catch (_) {}

      // Event-Content erstellen (datenschutzkonform!)
      final content = _buildContent(
        badges: badges,
        user: user,
        platformProofs: platformProofs,
        socialStats: socialStats,
        zapStats: zapStats,
        humanityProof: humanityProof,
      );

      // Nostr-Event signieren
      final event = Event.from(
        kind: _eventKind,
        tags: [
          ['d', _eventDTag],
          ['v', _protocolVersion.toString()],
          ['client', 'einundzwanzig-meetup-app'],
        ],
        content: jsonEncode(content),
        privkey: privHex,
      );

      // An Relays senden
      final relayCount = await _publishToRelays(event);

      // Letzten Publish-Status speichern
      await _savePublishStatus(badges);

      return PublishResult(
        success: relayCount > 0,
        relayCount: relayCount,
        eventId: event.id,
        message: relayCount > 0
            ? 'Reputation auf $relayCount Relays aktualisiert'
            : 'Konnte an keinen Relay senden',
      );
    } catch (e) {
      return PublishResult(
        success: false,
        relayCount: 0,
        message: 'Publish-Fehler: $e',
      );
    }
  }

  // =============================================
  // EVENT-CONTENT ERSTELLEN (Datenschutzkonform!)
  // =============================================
  // NUR aggregierte Zahlen, KEINE Meetup-Details!
  // =============================================

  static Map<String, dynamic> _buildContent({
    required List<MeetupBadge> badges,
    required UserProfile user,
    Map<String, PlatformProof>? platformProofs,
    SocialStats? socialStats,
    ZapStats? zapStats,
    Map<String, dynamic>? humanityProof,
  }) {
    // Badge-Statistiken
    final stats = MeetupBadge.getReputationStats(badges);
    final uniqueMeetups = badges.map((b) => b.meetupName).toSet().length;
    final uniqueSigners = badges
        .map((b) => b.adminPubkey)
        .where((p) => p.isNotEmpty)
        .toSet()
        .length;

    // Account-Alter berechnen
    final sortedByDate = List<MeetupBadge>.from(badges)
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstBadge = sortedByDate.first.date;
    final accountAgeDays = DateTime.now().difference(firstBadge).inDays;

    // Account-Alter als Monat/Jahr (Datenschutz: kein genaues Datum)
    final sinceStr = '${firstBadge.year}-${firstBadge.month.toString().padLeft(2, '0')}';

    // Trust Score berechnen (Import nicht nötig, wir rechnen die Basics selbst)
    // Der vollständige Score wird vom Verifizierer lokal berechnet
    final double score = _calculateBasicScore(
      totalBadges: badges.length,
      boundBadges: stats['claimed'] ?? 0,
      uniqueMeetups: uniqueMeetups,
      uniqueSigners: uniqueSigners,
      accountAgeDays: accountAgeDays,
    );

    final String level = _scoreToLevel(score);

    // Badge-Proof-Hash (datenschutzkonform)
    final badgeProofV2 = MeetupBadge.generateBadgeProofV2(badges);
    final badgeProofV1 = MeetupBadge.generateBadgeProof(badges);

    // Content zusammenbauen
    final content = <String, dynamic>{
      'version': _protocolVersion,
      'identity': {
        'nickname': user.nickname.isEmpty ? 'Anon' : user.nickname,
      },
      'stats': {
        'score': double.parse(score.toStringAsFixed(1)),
        'level': level,
        'total_badges': badges.length,
        'verified_badges': stats['crypto_proof'] ?? 0,
        'bound_badges': stats['claimed'] ?? 0,
        'retroactive_badges': stats['retroactive'] ?? 0,
        'meetup_count': uniqueMeetups,
        'signer_count': uniqueSigners,
        'account_age_days': accountAgeDays,
        'since': sinceStr,
      },
      'proof': {
        'badge_proof_hash': badgeProofV2.isNotEmpty ? badgeProofV2 : badgeProofV1,
        'proof_version': badgeProofV2.isNotEmpty ? 2 : 1,
      },
      'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    // Social-Layer (nur wenn Daten vorhanden)
    if (socialStats != null && socialStats.followCount > 0) {
      content['social'] = socialStats.toJson();
    }

    // Lightning-Layer (nur wenn Daten vorhanden)
    if (zapStats != null && zapStats.totalCount > 0) {
      content['lightning'] = zapStats.toJson();
    }

    // Humanity-Proof (Lightning-Zahlung als Anti-Bot)
    if (humanityProof != null) {
      content['humanity_proof'] = humanityProof;
    }

    // Plattform-Proofs (nur wenn vorhanden)
    if (platformProofs != null && platformProofs.isNotEmpty) {
      content['platform_proofs'] = platformProofs.map(
        (key, proof) => MapEntry(key, proof.toJson()),
      );
    }

    return content;
  }

  // =============================================
  // BASIC SCORE (vereinfacht, für Relay-Event)
  // Der echte Score wird vom Verifizierer berechnet.
  // =============================================
  static double _calculateBasicScore({
    required int totalBadges,
    required int boundBadges,
    required int uniqueMeetups,
    required int uniqueSigners,
    required int accountAgeDays,
  }) {
    double score = 0;

    // Badges (max 3.0)
    score += (boundBadges * 0.3).clamp(0, 3.0);

    // Diversität: Meetups (max 2.0)
    score += (uniqueMeetups * 0.5).clamp(0, 2.0);

    // Diversität: Organisatoren (max 2.0)
    score += (uniqueSigners * 0.7).clamp(0, 2.0);

    // Account-Alter (max 2.0)
    score += ((accountAgeDays / 30) * 0.3).clamp(0, 2.0);

    // Binding-Bonus: Alle Badges gebunden? (max 1.0)
    if (totalBadges > 0 && boundBadges == totalBadges) {
      score += 1.0;
    }

    return score.clamp(0, 10.0);
  }

  static String _scoreToLevel(double score) {
    if (score >= 8.0) return 'VETERAN';
    if (score >= 5.0) return 'ETABLIERT';
    if (score >= 2.0) return 'AKTIV';
    if (score > 0) return 'STARTER';
    return 'NEU';
  }

  // =============================================
  // AN RELAYS SENDEN
  // =============================================
  static Future<int> _publishToRelays(Event event) async {
    final relays = await RelayConfig.getActiveRelays();
    if (relays.isEmpty) return 0;

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

    for (final relayUrl in relays) {
      try {
        final ws = await WebSocket.connect(relayUrl)
            .timeout(RelayConfig.publishTimeout);
        ws.add(eventJson);
        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        successCount++;
        AppLogger.debug('ReputationPublisher', 'Event an $relayUrl gesendet ✓');

      } catch (e) {
        AppLogger.debug('ReputationPublisher', '$relayUrl fehlgeschlagen: $e');
      }
    }

    return successCount;
  }

  // =============================================
  // REPUTATION VON RELAY ABRUFEN (per npub)
  // =============================================
  // Wird vom Verifizierer aufgerufen um die Reputation
  // eines anderen Nutzers zu prüfen.
  // =============================================

  static Future<ReputationEvent?> fetchByNpub(String npub) async {
    if (npub.isEmpty) return null;

    String pubkeyHex;
    try {
      pubkeyHex = Nip19.decodePubkey(npub);
    } catch (e) {
      return null;
    }

    return await fetchByPubkeyHex(pubkeyHex);
  }

  static Future<ReputationEvent?> fetchByPubkeyHex(String pubkeyHex) async {
    if (pubkeyHex.isEmpty) return null;

    final relays = await RelayConfig.getActiveRelays();

    for (final relayUrl in relays) {
      try {
        final result = await _fetchFromSingleRelay(relayUrl, pubkeyHex);
        if (result != null) return result;
      } catch (e) {
        AppLogger.debug('ReputationPublisher', '$relayUrl Fetch fehlgeschlagen: $e');
        continue;
      }
    }

    return null;
  }

  static Future<ReputationEvent?> _fetchFromSingleRelay(
    String relayUrl,
    String pubkeyHex,
  ) async {
    WebSocket? ws;

    try {
      ws = await WebSocket.connect(relayUrl)
          .timeout(RelayConfig.relayTimeout);
      final completer = Completer<ReputationEvent?>();
      final subscriptionId = 'rep-fetch-${DateTime.now().millisecondsSinceEpoch}';

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3) {
              final eventData = message[2] as Map<String, dynamic>;

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

              // Signatur prüfen
              if (!event.isValid()) {
                AppLogger.debug('ReputationPublisher', 'Ungültige Signatur von $relayUrl');

                return;
              }

              // Pubkey muss übereinstimmen
              if (event.pubkey != pubkeyHex) return;

              try {
                final content = jsonDecode(event.content) as Map<String, dynamic>;
                final repEvent = ReputationEvent.fromNostrEvent(
                  event: event,
                  content: content,
                );
                if (!completer.isCompleted) completer.complete(repEvent);
              } catch (e) {
                AppLogger.debug('ReputationPublisher', 'Content-Parse Fehler: $e');

              }
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(null);
            }
          } catch (e) {
            AppLogger.debug('ReputationPublisher', 'Message-Parse Fehler: $e');

          }
        },
        onError: (e) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      // Request senden
      final request = jsonEncode([
        'REQ',
        subscriptionId,
        {
          'kinds': [_eventKind],
          'authors': [pubkeyHex],
          '#d': [_eventDTag],
          'limit': 1,
        }
      ]);
      ws.add(request);

      final result = await completer.future.timeout(
        RelayConfig.relayTimeout,
        onTimeout: () => null,
      );

      ws.add(jsonEncode(['CLOSE', subscriptionId]));
      return result;
    } catch (e) {
      rethrow;
    } finally {
      try { ws?.close(); } catch (_) {}
    }
  }

  // =============================================
  // PUBLISH-STATUS (Spam-Schutz + Change-Detection)
  // =============================================

  static Future<bool> _shouldPublish(List<MeetupBadge> badges) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Zeitcheck: Nicht öfter als _minPublishInterval
    final lastPublish = prefs.getInt(_lastPublishKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastPublish < _minPublishInterval.inMilliseconds) {
      return false;
    }

    // 2. Content-Check: Hat sich etwas geändert?
    final currentHash = _computeContentHash(badges);
    final lastHash = prefs.getString(_lastPublishHashKey) ?? '';
    if (currentHash == lastHash) {
      return false; // Nichts hat sich geändert
    }

    return true;
  }

  static Future<void> _savePublishStatus(List<MeetupBadge> badges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPublishKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(_lastPublishHashKey, _computeContentHash(badges));
  }

  static String _computeContentHash(List<MeetupBadge> badges) {
    final data = '${badges.length}'
        '|${MeetupBadge.countBoundBadges(badges)}'
        '|${badges.map((b) => b.meetupName).toSet().length}'
        '|${badges.map((b) => b.adminPubkey).where((p) => p.isNotEmpty).toSet().length}';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 16);
  }

  // =============================================
  // PUBLISH IM HINTERGRUND (Fire-and-Forget)
  // =============================================
  // Für Aufrufe nach Badge-Scan wo das Ergebnis
  // nicht abgewartet werden muss.
  // =============================================

  static void publishInBackground(List<MeetupBadge> badges) {
    publish(badges: badges).then((result) {
      if (result.success && result.relayCount > 0) {
        AppLogger.debug('ReputationPublisher', 'Hintergrund-Publish: ${result.message}');

      }
    }).catchError((e) {
      AppLogger.debug('ReputationPublisher', 'Hintergrund-Publish fehlgeschlagen: $e');

    });
  }
}

// =============================================
// DATENMODELLE
// =============================================

/// Ergebnis eines Publish-Vorgangs
class PublishResult {
  final bool success;
  final int relayCount;
  final String? eventId;
  final String message;

  PublishResult({
    required this.success,
    required this.relayCount,
    this.eventId,
    required this.message,
  });
}

/// Reputation-Event von einem Relay
class ReputationEvent {
  final String pubkeyHex;
  final String npub;
  final String eventId;
  final String signature;
  final int createdAt;
  final int version;

  // Identity
  final String nickname;

  // Stats
  final double score;
  final String level;
  final int totalBadges;
  final int verifiedBadges;
  final int boundBadges;
  final int retroactiveBadges;
  final int meetupCount;
  final int signerCount;
  final int accountAgeDays;
  final String since;

  // Proof
  final String badgeProofHash;
  final int proofVersion;

  // Plattform-Proofs
  final Map<String, dynamic> platformProofs;

  // Social-Layer (Phase 5)
  final SocialStats? socialStats;

  // Lightning-Layer (Phase 5)
  final ZapStats? zapStats;

  // Humanity-Proof (Phase 5)
  final bool humanityVerified;
  final String? humanityReceiptId;

  // Update-Zeitpunkt
  final int updatedAt;

  ReputationEvent({
    required this.pubkeyHex,
    required this.npub,
    required this.eventId,
    required this.signature,
    required this.createdAt,
    this.version = 2,
    this.nickname = 'Anon',
    this.score = 0,
    this.level = 'NEU',
    this.totalBadges = 0,
    this.verifiedBadges = 0,
    this.boundBadges = 0,
    this.retroactiveBadges = 0,
    this.meetupCount = 0,
    this.signerCount = 0,
    this.accountAgeDays = 0,
    this.since = '',
    this.badgeProofHash = '',
    this.proofVersion = 1,
    this.platformProofs = const {},
    this.socialStats,
    this.zapStats,
    this.humanityVerified = false,
    this.humanityReceiptId,
    this.updatedAt = 0,
  });

  /// Erstellt ein ReputationEvent aus einem Nostr-Event
  factory ReputationEvent.fromNostrEvent({
    required Event event,
    required Map<String, dynamic> content,
  }) {
    final identity = content['identity'] as Map<String, dynamic>? ?? {};
    final stats = content['stats'] as Map<String, dynamic>? ?? {};
    final proof = content['proof'] as Map<String, dynamic>? ?? {};
    final platforms = content['platform_proofs'] as Map<String, dynamic>? ?? {};
    final socialJson = content['social'] as Map<String, dynamic>?;
    final lightningJson = content['lightning'] as Map<String, dynamic>?;
    final humanityJson = content['humanity_proof'] as Map<String, dynamic>?;

    String npub = '';
    try { npub = Nip19.encodePubkey(event.pubkey); } catch (_) {}

    return ReputationEvent(
      pubkeyHex: event.pubkey,
      npub: npub,
      eventId: event.id,
      signature: event.sig,
      createdAt: event.createdAt,
      version: content['version'] as int? ?? 1,
      nickname: identity['nickname'] as String? ?? 'Anon',
      score: (stats['score'] as num?)?.toDouble() ?? 0,
      level: stats['level'] as String? ?? 'NEU',
      totalBadges: stats['total_badges'] as int? ?? 0,
      verifiedBadges: stats['verified_badges'] as int? ?? 0,
      boundBadges: stats['bound_badges'] as int? ?? 0,
      retroactiveBadges: stats['retroactive_badges'] as int? ?? 0,
      meetupCount: stats['meetup_count'] as int? ?? 0,
      signerCount: stats['signer_count'] as int? ?? 0,
      accountAgeDays: stats['account_age_days'] as int? ?? 0,
      since: stats['since'] as String? ?? '',
      badgeProofHash: proof['badge_proof_hash'] as String? ?? '',
      proofVersion: proof['proof_version'] as int? ?? 1,
      platformProofs: platforms,
      socialStats: socialJson != null ? SocialStats.fromJson(socialJson) : null,
      zapStats: lightningJson != null ? ZapStats.fromJson(lightningJson) : null,
      humanityVerified: humanityJson?['verified'] as bool? ?? false,
      humanityReceiptId: humanityJson?['receipt_event_id'] as String?,
      updatedAt: content['updated_at'] as int? ?? event.createdAt,
    );
  }

  /// Alter des Events in Stunden
  int get ageInHours {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return ((now - createdAt) / 3600).round();
  }

  /// Ist das Event noch frisch? (< 7 Tage)
  bool get isFresh => ageInHours < (7 * 24);
}

/// Plattform-Proof (wird in Phase 4 vollständig implementiert)
class PlatformProof {
  final String platform;
  final String username;
  final String proofSig;
  final int createdAt;

  PlatformProof({
    required this.platform,
    required this.username,
    required this.proofSig,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'proof_sig': proofSig,
    'created_at': createdAt,
  };

  factory PlatformProof.fromJson(String platform, Map<String, dynamic> json) {
    return PlatformProof(
      platform: platform,
      username: json['username'] as String? ?? '',
      proofSig: json['proof_sig'] as String? ?? '',
      createdAt: json['created_at'] as int? ?? 0,
    );
  }
}