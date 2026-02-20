// ============================================
// ADMIN REGISTRY v4 - FULL WEB OF TRUST
// ============================================
//
// Ablauf:
//   1. App startet → checkAdmin(npub)
//   2. Prüfen: Ist der "Bootstrap Sunset" aktiv?
//   3. Cache prüfen (sofort, offline-fähig)
//   4. Relay kontaktieren (im Hintergrund)
//   5. Signierte Events empfangen
//      - WENN Bootstrap: Lade Liste von Super-Admin
//      - WENN Sunset: Lade Listen von ALLEN aktuell bekannten Admins (Web of Trust)
//   6. Cache aktualisieren und zusammenführen
//
// BOOTSTRAP SUNSET LOGIK:
//   Um einen "Single Point of Failure" zu vermeiden, verliert
//   der Super-Admin automatisch seinen hartcodierten Gott-Modus,
//   sobald das Netzwerk eine kritische Masse an Organic-Admins (z.B. 20)
//   erreicht hat. Danach vertraut das Netzwerk auf Peer-to-Peer Vouching.
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'nostr_service.dart';
import 'secure_key_store.dart';

class AdminEntry {
  final String npub;
  final String meetup;
  final String name;
  final int addedAt;

  AdminEntry({
    required this.npub,
    required this.meetup,
    this.name = '',
    this.addedAt = 0,
  });

  Map<String, dynamic> toJson() => {
    'npub': npub,
    'meetup': meetup,
    'name': name,
    'added_at': addedAt,
  };

  factory AdminEntry.fromJson(Map<String, dynamic> json) => AdminEntry(
    npub: json['npub'] ?? '',
    meetup: json['meetup'] ?? '',
    name: json['name'] ?? '',
    addedAt: json['added_at'] ?? 0,
  );
}

class AdminCheckResult {
  final bool isAdmin;
  final String? meetup;
  final String? name;
  final String source; // 'nostr_relay', 'local_cache', 'super_admin', 'not_found'

  AdminCheckResult({
    required this.isAdmin,
    this.meetup,
    this.name,
    required this.source,
  });
}

class AdminRegistry {
  // =============================================
  // SUPER-ADMIN NPUB & SUNSET CONFIG
  // =============================================
  static const String superAdminNpub = "npub1lf0rga7j66uj6enae2mxezamz5nsz3vechhvmh25tcarn4u8qf5q534jzc"; // ← DEINEN npub hier einsetzen!

  // Ab wie vielen verifizierten Admins soll der Super-Admin entmachtet werden?
  static const int sunsetThreshold = 20; 

  // Nostr Relays (die App versucht alle der Reihe nach)
  static const List<String> _relays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://nostr.einundzwanzig.space', // Eigener Relay wenn vorhanden
  ];

  // Nostr Event Tag Identifier
  static const String _eventDTag = 'einundzwanzig-admins';
  static const int _eventKind = 30078; // Parameterized Replaceable Event

  // Cache Keys
  static const String _cacheKey = 'admin_registry_cache';
  static const String _cacheTimestampKey = 'admin_registry_timestamp';
  static const String _sunsetFlagKey = 'bootstrap_permanently_sunset';

  // Timeout für Relay-Verbindung
  static const Duration _relayTimeout = Duration(seconds: 8);

  // =============================================
  // SUNSET LOGIK (Sonnenuntergang für Super-Admin)
  // =============================================

  /// Prüft und setzt den Sunset-Status. Wird nie wieder 'false', wenn einmal 'true'.
  static Future<bool> isSunsetActive() async {
    final prefs = await SharedPreferences.getInstance();

    // Wenn Sunset schon mal erreicht wurde, bleibt es für immer true
    if (prefs.getBool(_sunsetFlagKey) == true) {
      return true;
    }

    // Zählen, wie viele Admins wir lokal im Cache haben
    final cachedList = await _loadFromCache();
    final int currentAdminCount = cachedList?.length ?? 0;

    // Wenn Schwellenwert erreicht, aktiviere Sunset permanent
    if (currentAdminCount >= sunsetThreshold) {
      await prefs.setBool(_sunsetFlagKey, true);
      print('[AdminRegistry] 🌅 BOOTSTRAP SUNSET AKTIVIERT! Web of Trust ist nun völlig dezentral.');
      return true;
    }

    return false;
  }

  // =============================================
  // ADMIN-CHECK (Hauptfunktion)
  // =============================================
  static Future<AdminCheckResult> checkAdmin(String userNpub) async {
    if (userNpub.isEmpty) {
      return AdminCheckResult(isAdmin: false, source: 'no_key');
    }

    // 1. Sunset-Check durchführen
    final bool isSunset = await isSunsetActive();

    // 2. Super-Admin Check (NUR wenn Sunset NICHT aktiv ist)
    if (!isSunset && userNpub == superAdminNpub) {
      return AdminCheckResult(
        isAdmin: true,
        meetup: 'Alle Meetups',
        name: 'Super-Admin',
        source: 'super_admin',
      );
    }

    // 3. Cache prüfen (schnell, offline)
    final cachedList = await _loadFromCache();
    final cacheHit = cachedList?.where((e) => e.npub == userNpub).firstOrNull;
    if (cacheHit != null) {
      // Cache-Treffer! Relay-Update im Hintergrund starten
      _refreshFromRelaysInBackground();
      return AdminCheckResult(
        isAdmin: true,
        meetup: cacheHit.meetup,
        name: cacheHit.name,
        source: 'local_cache',
      );
    }

    // 4. Kein Cache-Treffer → Relay fragen (blockierend, mit Timeout)
    try {
      final relayList = await fetchFromRelays();
      if (relayList != null && relayList.isNotEmpty) {
        await _saveToCache(relayList);

        // Nach Relay-Update erneut Sunset-Check (falls wir den Schwellenwert just überschritten haben)
        await isSunsetActive();

        final entry = relayList.where((e) => e.npub == userNpub).firstOrNull;
        if (entry != null) {
          return AdminCheckResult(
            isAdmin: true,
            meetup: entry.meetup,
            name: entry.name,
            source: 'nostr_relay',
          );
        }
      }
    } catch (e) {
      print('[AdminRegistry] Relay-Fetch Fehler: $e');
    }

    return AdminCheckResult(isAdmin: false, source: 'not_found');
  }

  // =============================================
  // ADMIN-CHECK PER PUBKEY HEX
  // Für den Scanner: Prüft ob ein Signer-Pubkey
  // ein bekannter Admin ist.
  // =============================================
  static Future<AdminCheckResult> checkAdminByPubkey(String pubkeyHex) async {
    if (pubkeyHex.isEmpty) {
      return AdminCheckResult(isAdmin: false, source: 'no_key');
    }

    // Pubkey Hex → npub konvertieren und regulär an Hauptfunktion weitergeben
    try {
      final npub = Nip19.encodePubkey(pubkeyHex);
      return await checkAdmin(npub);
    } catch (e) {
      return AdminCheckResult(isAdmin: false, source: 'invalid_key');
    }
  }

  // =============================================
  // RELAY FETCH (WEB OF TRUST LOGIK)
  // =============================================
  static Future<List<AdminEntry>?> fetchFromRelays() async {
    List<String> authorsToQuery = [];
    final bool isSunset = await isSunsetActive();

    if (!isSunset) {
      // BOOTSTRAP PHASE: Wir vertrauen nur dem Super-Admin
      try {
        final superAdminHex = Nip19.decodePubkey(superAdminNpub);
        authorsToQuery.add(superAdminHex);
        print('[AdminRegistry] Bootstrap Phase: Frage Relays nach Super-Admin ($superAdminHex)');
      } catch (e) {
        print('[AdminRegistry] Ungültiger Super-Admin npub: $e');
        return null;
      }
    } else {
      // SUNSET PHASE (WEB OF TRUST): Wir fragen alle uns bekannten Admins
      final cachedList = await _loadFromCache();
      if (cachedList != null && cachedList.isNotEmpty) {
        for (var admin in cachedList) {
          try {
            authorsToQuery.add(Nip19.decodePubkey(admin.npub));
          } catch (_) {}
        }
      }
      
      // Falls der Cache warum auch immer leer ist, Fallback auf Super-Admin, 
      // um das Netzwerk wieder hochzuziehen
      if (authorsToQuery.isEmpty) {
        try {
          authorsToQuery.add(Nip19.decodePubkey(superAdminNpub));
        } catch (_) {}
      }
      print('[AdminRegistry] Sunset Phase: Frage Relays nach Updates von ${authorsToQuery.length} bekannten Admins.');
    }

    // Aus Nostr-Protokoll-Gründen (Limits bei Filtern) teilen wir große Listen auf
    List<String> queryChunk = authorsToQuery;
    if (authorsToQuery.length > 50) {
      queryChunk = authorsToQuery.sublist(0, 50); // Wir fragen vorerst nur die ersten 50 ab um Timeout zu vermeiden
    }

    // Versuche jeden Relay der Reihe nach
    for (final relayUrl in _relays) {
      try {
        final result = await _fetchFromSingleRelay(relayUrl, queryChunk);
        if (result != null) {
          // Wenn Sunset aktiv ist, mergen wir die Ergebnisse mit dem Cache
          if (isSunset) {
            return await _mergeWithCache(result);
          } else {
            // In der Bootstrap-Phase überschreibt das Super-Admin-Event alles
            return result;
          }
        }
      } catch (e) {
        print('[AdminRegistry] $relayUrl fehlgeschlagen: $e');
        continue; // Nächsten Relay versuchen
      }
    }

    print('[AdminRegistry] Kein Relay erreichbar');
    return null;
  }

  // Hilfsfunktion: Fügt neu gefundene Admins aus dem Web of Trust dem Cache hinzu
  static Future<List<AdminEntry>> _mergeWithCache(List<AdminEntry> newEntries) async {
    final cachedList = await _loadFromCache() ?? [];
    
    // Einfacher Merge: Alles, was wir noch nicht kannten, kommt dazu
    for (var newEntry in newEntries) {
      if (!cachedList.any((e) => e.npub == newEntry.npub)) {
        cachedList.add(newEntry);
      }
    }
    return cachedList;
  }

  // =============================================
  // EINZELNEN RELAY ABFRAGEN (MEHRERE AUTHORS)
  // =============================================
  static Future<List<AdminEntry>?> _fetchFromSingleRelay(
    String relayUrl, 
    List<String> authorsHex,
  ) async {
    WebSocket? ws;
    List<AdminEntry> collectedAdmins = [];

    try {
      ws = await WebSocket.connect(relayUrl).timeout(_relayTimeout);
      final completer = Completer<List<AdminEntry>?>();
      final subscriptionId = 'admin-list-${DateTime.now().millisecondsSinceEpoch}';

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

              // Ist der Author überhaupt jemand, nach dem wir gefragt haben?
              if (!authorsHex.contains(event.pubkey)) return;
              if (!event.isValid()) return;

              try {
                final content = jsonDecode(event.content) as Map<String, dynamic>;
                final adminsInEvent = (content['admins'] as List<dynamic>?)
                    ?.map((e) => AdminEntry.fromJson(e as Map<String, dynamic>))
                    .toList() ?? [];

                // Sammeln aller Admins aus allen Events
                collectedAdmins.addAll(adminsInEvent);
              } catch (e) {
                print('[AdminRegistry] Content-Parse Fehler: $e');
              }
            } 
            else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(collectedAdmins);
            }
          } catch (e) {
            print('[AdminRegistry] Message-Parse Fehler: $e');
          }
        },
        onError: (e) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      final request = jsonEncode([
        'REQ',
        subscriptionId,
        {
          'kinds': [_eventKind],
          'authors': authorsHex,
          '#d': [_eventDTag],
          // Wir holen die letzten 50 Events, falls viele Admins Vouchings gepostet haben
          'limit': 50, 
        }
      ]);

      ws.add(request);

      final result = await completer.future.timeout(
        _relayTimeout,
        onTimeout: () => collectedAdmins.isNotEmpty ? collectedAdmins : null,
      );

      ws.add(jsonEncode(['CLOSE', subscriptionId]));
      
      // Duplikate aus der gesammelten Liste filtern
      if (result != null) {
        final uniqueMap = { for (var e in result) e.npub : e };
        return uniqueMap.values.toList();
      }
      return null;

    } catch (e) {
      rethrow;
    } finally {
      try { ws?.close(); } catch (_) {}
    }
  }

  // =============================================
  // HINTERGRUND-REFRESH
  // =============================================
  static void _refreshFromRelaysInBackground() async {
    try {
      final age = await cacheAge();
      if (age != null && age.inHours < 1) return;

      final relayList = await fetchFromRelays();
      if (relayList != null) {
        await _saveToCache(relayList);
        await isSunsetActive(); // Sunset-Status nach Update prüfen
        print('[AdminRegistry] Cache im Hintergrund aktualisiert. Total Admins: ${relayList.length}');
      }
    } catch (e) {
      // Stilles Scheitern im Hintergrund
    }
  }

  // =============================================
  // CACHE: Laden
  // =============================================
  static Future<List<AdminEntry>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json == null) return null;
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => AdminEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  // =============================================
  // CACHE: Speichern
  // =============================================
  static Future<void> _saveToCache(List<AdminEntry> admins) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(admins.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, json);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // =============================================
  // ADMIN-LISTE VERWALTEN (lokal)
  // =============================================

  static Future<List<AdminEntry>> getAdminList() async {
    final cached = await _loadFromCache();
    return cached ?? [];
  }

  static Future<void> addAdmin(AdminEntry admin) async {
    final list = await getAdminList();
    if (list.any((e) => e.npub == admin.npub)) {
      throw Exception('Dieser npub ist bereits in der Admin-Liste.');
    }
    if (!NostrService.isValidNpub(admin.npub)) {
      throw Exception('Ungültiger npub.');
    }
    list.add(AdminEntry(
      npub: admin.npub,
      meetup: admin.meetup,
      name: admin.name,
      addedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ));
    await _saveToCache(list);

    // Nach Hinzufügen prüfen, ob Sunset erreicht ist
    await isSunsetActive();
  }

  static Future<void> removeAdmin(String npub) async {
    final list = await getAdminList();
    list.removeWhere((e) => e.npub == npub);
    await _saveToCache(list);
  }

  // =============================================
  // NOSTR EVENT ERSTELLEN + PUBLISHEN
  // =============================================
  static Future<String> createAndPublishAdminListEvent() async {
    final privHex = await SecureKeyStore.getPrivHex();

    if (privHex == null) {
      throw Exception('Kein Nostr-Key vorhanden.');
    }

    final list = await getAdminList();
    final content = jsonEncode({
      'admins': list.map((e) => e.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final event = Event.from(
      kind: _eventKind,
      tags: [
        ['d', _eventDTag],
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
    List<String> errors = [];

    for (final relayUrl in _relays) {
      try {
        final ws = await WebSocket.connect(relayUrl).timeout(
          const Duration(seconds: 5),
        );
        ws.add(eventJson);

        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        successCount++;
        print('[AdminRegistry] Event an $relayUrl gesendet ✓');
      } catch (e) {
        errors.add('$relayUrl: $e');
        print('[AdminRegistry] $relayUrl fehlgeschlagen: $e');
      }
    }

    final displayJson = jsonEncode({
      'id': event.id,
      'pubkey': event.pubkey,
      'created_at': event.createdAt,
      'kind': event.kind,
      'tags': event.tags,
      'content': event.content,
      'sig': event.sig,
    });

    if (successCount == 0) {
      throw Exception('Event konnte an keinen Relay gesendet werden.\n${errors.join('\n')}');
    }

    return '{"sent_to": $successCount, "event": $displayJson}';
  }

  static Future<String> createAdminListEvent() async {
    final privHex = await SecureKeyStore.getPrivHex();

    if (privHex == null) {
      throw Exception('Kein Nostr-Key vorhanden.');
    }

    final list = await getAdminList();
    final content = jsonEncode({
      'admins': list.map((e) => e.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final event = Event.from(
      kind: _eventKind,
      tags: [['d', _eventDTag]],
      content: content,
      privkey: privHex,
    );

    return jsonEncode({
      'id': event.id,
      'pubkey': event.pubkey,
      'created_at': event.createdAt,
      'kind': event.kind,
      'tags': event.tags,
      'content': event.content,
      'sig': event.sig,
    });
  }

  // =============================================
  // HILFSFUNKTIONEN
  // =============================================

  static Future<Duration?> cacheAge() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return null;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }

  static Future<int> forceRefresh() async {
    final relayList = await fetchFromRelays();
    if (relayList != null) {
      await _saveToCache(relayList);
      await isSunsetActive(); // Sunset Update
      return relayList.length;
    }
    return -1; // Fehler
  }
}
