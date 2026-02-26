// ============================================
// SOCIAL GRAPH SERVICE — Nostr Web of Trust
// ============================================
// Analysiert soziale Verbindungen über Nostr:
//
//   1. Contact-List abrufen (Kind 3 Events)
//   2. Gegenseitige Follows erkennen (Mutuals)
//   3. Organisator-Follows identifizieren
//   4. Gemeinsame Kontakte mit Verifizierer berechnen
//   5. Transitive Vertrauensketten (Hops)
//
// Alles passiert lokal — kein Server, keine Datenbank.
// Die App fragt Nostr-Relays nach öffentlichen Daten
// und berechnet den Social Score auf dem Gerät.
//
// Privacy: Nur aggregierte Zahlen werden publiziert.
// NICHT: Wer wem folgt, welche Kontakte, welche Orgs.
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'relay_config.dart';
import 'secure_key_store.dart';
import 'admin_registry.dart';
import 'dart:math';

class SocialGraphService {
  // Cache-Keys
  static const String _cacheKeyMyFollows = 'social_my_follows';
  static const String _cacheKeyTimestamp = 'social_cache_ts';
  static const Duration _cacheDuration = Duration(hours: 2);

  // =============================================
  // EIGENE FOLLOW-LISTE ABRUFEN
  // =============================================
  // Kind 3 Event = Contact List (NIP-02)
  // Enthält alle pubkeys denen der Nutzer folgt.
  // =============================================

  static Future<Set<String>> getMyFollows({bool forceRefresh = false}) async {
    // Cache prüfen
    if (!forceRefresh) {
      final cached = await _loadCachedFollows();
      if (cached != null) return cached;
    }

    final pubkeyHex = await _getMyPubkeyHex();
    if (pubkeyHex == null) return {};

    final follows = await fetchContactList(pubkeyHex);

    // Cache speichern
    await _cacheFollows(follows);
    return follows;
  }

  // =============================================
  // CONTACT LIST EINES BELIEBIGEN NUTZERS ABRUFEN
  // =============================================

  static Future<Set<String>> fetchContactList(String pubkeyHex) async {
    final relays = await RelayConfig.getActiveRelays();
    Set<String> allFollows = {};

    for (final relayUrl in relays) {
      try {
        final follows = await _fetchContactListFromRelay(relayUrl, pubkeyHex);
        if (follows.isNotEmpty) {
          allFollows = follows; // Neuestes Event gewinnt
          break; // Ein Relay reicht für Kind 3
        }
      } catch (e) {
        // Nächstes Relay versuchen
      }
    }

    return allFollows;
  }

  static Future<Set<String>> _fetchContactListFromRelay(
    String relayUrl,
    String pubkeyHex,
  ) async {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(relayUrl).timeout(RelayConfig.relayTimeout);
      final completer = Completer<Set<String>>();
      // Security Audit M4: Kryptographisch sichere Subscription-ID
      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId = 'contacts-$subIdHex';
      Set<String> follows = {};

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3) {
              final eventData = message[2] as Map<String, dynamic>;
              final tags = eventData['tags'] as List<dynamic>? ?? [];

              // Kind 3: Tags sind [["p", "pubkey_hex", "relay_url", "petname"], ...]
              for (final tag in tags) {
                final t = tag as List<dynamic>;
                if (t.isNotEmpty && t[0] == 'p' && t.length >= 2) {
                  final followPubkey = t[1] as String;
                  if (followPubkey.length == 64) {
                    follows.add(followPubkey);
                  }
                }
              }
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(follows);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete({});
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(follows);
        },
      );

      final request = jsonEncode([
        'REQ', subId,
        {
          'kinds': [3],
          'authors': [pubkeyHex],
          'limit': 1, // Nur das neueste Kind 3 Event
        }
      ]);
      ws.add(request);

      final result = await completer.future.timeout(
        RelayConfig.relayTimeout,
        onTimeout: () => follows,
      );

      return result;
    } finally {
      ws?.close();
    }
  }

  // =============================================
  // SOCIAL ANALYSE
  // =============================================
  // Vergleicht zwei Nutzer und berechnet:
  //   - Mutual Follows (gegenseitig)
  //   - Gemeinsame Kontakte
  //   - Organisator-Follows
  //   - Transitive Hops
  // =============================================

  static Future<SocialAnalysis> analyze(String targetPubkeyHex) async {
    final myPubkeyHex = await _getMyPubkeyHex();
    if (myPubkeyHex == null || myPubkeyHex == targetPubkeyHex) {
      return SocialAnalysis.empty();
    }

    // 1. Meine Follows laden (cached)
    final myFollows = await getMyFollows();

    // 2. Ziel-Follows laden
    final targetFollows = await fetchContactList(targetPubkeyHex);

    // 3. Folge ich dem Ziel?
    final iFollow = myFollows.contains(targetPubkeyHex);

    // 4. Folgt das Ziel mir?
    final followsMe = targetFollows.contains(myPubkeyHex);

    // 5. Gegenseitig?
    final isMutual = iFollow && followsMe;

    // 6. Gemeinsame Kontakte (Intersection)
    final commonContacts = myFollows.intersection(targetFollows);

    // 7. Organisator-Follows
    // Prüfe ob bekannte Admins dem Ziel folgen
    final orgFollowers = await _countOrgFollowers(targetPubkeyHex, targetFollows);

    // 8. Hop-Distanz
    int hops;
    if (isMutual) {
      hops = 1; // Direkte gegenseitige Verbindung
    } else if (iFollow || followsMe) {
      hops = 1; // Einseitige direkte Verbindung
    } else if (commonContacts.isNotEmpty) {
      hops = 2; // Über gemeinsame Kontakte erreichbar
    } else {
      hops = -1; // Keine Verbindung gefunden
    }

    return SocialAnalysis(
      targetPubkey: targetPubkeyHex,
      myFollowCount: myFollows.length,
      targetFollowCount: targetFollows.length,
      iFollow: iFollow,
      followsMe: followsMe,
      isMutual: isMutual,
      commonContactCount: commonContacts.length,
      orgFollowerCount: orgFollowers,
      hops: hops,
    );
  }

  // =============================================
  // SOCIAL STATS FÜR EIGENES PROFIL
  // =============================================
  // Für das Reputation-Event: aggregierte Zahlen
  // über das eigene soziale Netzwerk.
  // =============================================

  static Future<SocialStats> getMyStats() async {
    final myPubkeyHex = await _getMyPubkeyHex();
    if (myPubkeyHex == null) return SocialStats.empty();

    final myFollows = await getMyFollows();

    // Stichprobe: Wie viele meiner Follows folgen mir zurück?
    // Wir prüfen max. 20 für Performance
    int mutualCount = 0;
    final sample = myFollows.take(20).toList();

    for (final followPubkey in sample) {
      try {
        final theirFollows = await fetchContactList(followPubkey);
        if (theirFollows.contains(myPubkeyHex)) {
          mutualCount++;
        }
      } catch (_) {}
    }

    // Hochrechnung
    final estimatedMutuals = myFollows.isEmpty ? 0
        : (mutualCount / sample.length * myFollows.length).round();

    // Org-Follows zählen
    final orgCount = await _countOrgFollowers(myPubkeyHex, null);

    return SocialStats(
      followCount: myFollows.length,
      estimatedMutualCount: estimatedMutuals,
      orgFollowerCount: orgCount,
    );
  }

  // =============================================
  // ORGANISATOR-FOLLOWS ZÄHLEN
  // =============================================

  static Future<int> _countOrgFollowers(
    String targetPubkeyHex,
    Set<String>? preloadedTargetFollowers,
  ) async {
    // Admin-Registry laden
    final admins = await AdminRegistry.fetchFromRelays();
    if (admins == null || admins.isEmpty) return 0;

    int count = 0;
    for (final admin in admins.take(10)) { // Max 10 Admins prüfen
      try {
        final adminPubkeyHex = Nip19.decodePubkey(admin.npub);
        final adminFollows = await fetchContactList(adminPubkeyHex);
        if (adminFollows.contains(targetPubkeyHex)) {
          count++;
        }
      } catch (_) {}
    }

    return count;
  }

  // =============================================
  // HILFSFUNKTIONEN
  // =============================================

  static Future<String?> _getMyPubkeyHex() async {
    final npub = await SecureKeyStore.getNpub();
    if (npub == null || npub.isEmpty) return null;
    try {
      return Nip19.decodePubkey(npub);
    } catch (_) {
      return null;
    }
  }

  static Future<Set<String>?> _loadCachedFollows() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cacheKeyTimestamp) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - ts > _cacheDuration.inMilliseconds) return null;

    final json = prefs.getString(_cacheKeyMyFollows);
    if (json == null) return null;

    try {
      final list = (jsonDecode(json) as List<dynamic>).cast<String>();
      return list.toSet();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _cacheFollows(Set<String> follows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKeyMyFollows, jsonEncode(follows.toList()));
    await prefs.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
  }
}

// =============================================
// DATENMODELLE
// =============================================

/// Ergebnis der Social-Analyse zwischen zwei Nutzern
class SocialAnalysis {
  final String targetPubkey;
  final int myFollowCount;
  final int targetFollowCount;
  final bool iFollow;
  final bool followsMe;
  final bool isMutual;
  final int commonContactCount;
  final int orgFollowerCount;
  final int hops; // -1 = keine Verbindung

  SocialAnalysis({
    required this.targetPubkey,
    required this.myFollowCount,
    required this.targetFollowCount,
    required this.iFollow,
    required this.followsMe,
    required this.isMutual,
    required this.commonContactCount,
    required this.orgFollowerCount,
    required this.hops,
  });

  factory SocialAnalysis.empty() => SocialAnalysis(
    targetPubkey: '',
    myFollowCount: 0,
    targetFollowCount: 0,
    iFollow: false,
    followsMe: false,
    isMutual: false,
    commonContactCount: 0,
    orgFollowerCount: 0,
    hops: -1,
  );

  /// Social Trust Score (0.0 - 3.0)
  double get socialScore {
    double score = 0;
    // Mutual Follow = stärkste Einzelverbindung
    if (isMutual) score += 1.0;
    else if (iFollow || followsMe) score += 0.3;
    // Gemeinsame Kontakte (log-skaliert)
    if (commonContactCount > 0) {
      score += (commonContactCount / (commonContactCount + 5)) * 1.0;
    }
    // Organisator-Endorsement
    score += (orgFollowerCount * 0.5).clamp(0.0, 1.0);
    return score.clamp(0.0, 3.0);
  }

  String get connectionLabel {
    if (isMutual) return 'Gegenseitig verbunden';
    if (iFollow) return 'Du folgst';
    if (followsMe) return 'Folgt dir';
    if (commonContactCount > 0) return '$commonContactCount gemeinsame Kontakte';
    return 'Keine Verbindung';
  }
}

/// Aggregierte Social-Stats für eigenes Profil
class SocialStats {
  final int followCount;
  final int estimatedMutualCount;
  final int orgFollowerCount;

  SocialStats({
    required this.followCount,
    required this.estimatedMutualCount,
    required this.orgFollowerCount,
  });

  factory SocialStats.empty() => SocialStats(
    followCount: 0,
    estimatedMutualCount: 0,
    orgFollowerCount: 0,
  );

  factory SocialStats.fromJson(Map<String, dynamic> json) => SocialStats(
    followCount: json['follows'] as int? ?? 0,
    estimatedMutualCount: json['mutuals'] as int? ?? 0,
    orgFollowerCount: json['org_followers'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'follows': followCount,
    'mutuals': estimatedMutualCount,
    'org_followers': orgFollowerCount,
  };
}