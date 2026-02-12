// ============================================
// ADMIN REGISTRY v2 - MIT ECHTEM RELAY-FETCH
// ============================================
//
// Ablauf:
//   1. App startet → checkAdmin(npub)
//   2. Cache prüfen (sofort, offline-fähig)
//   3. Relay kontaktieren (im Hintergrund)
//   4. Signiertes Event empfangen → Admin-Liste extrahieren
//   5. Cache aktualisieren
//
// Das Admin-Event (Kind 30078) wird vom Super-Admin
// auf Relays publiziert. Es enthält die Liste aller
// vertrauenswürdigen Admin-npubs.
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'nostr_service.dart';

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
  // SUPER-ADMIN NPUB
  // Das ist die EINZIGE hardcoded Konstante.
  // Wer diesen npub kontrolliert, kontrolliert die Admin-Liste.
  // =============================================
  static const String superAdminNpub = "DEIN_NPUB_HIER"; // ← DEINEN npub hier einsetzen!

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

  // Timeout für Relay-Verbindung
  static const Duration _relayTimeout = Duration(seconds: 8);

  // =============================================
  // ADMIN-CHECK (Hauptfunktion)
  // =============================================
  static Future<AdminCheckResult> checkAdmin(String userNpub) async {
    if (userNpub.isEmpty) {
      return AdminCheckResult(isAdmin: false, source: 'no_key');
    }

    // 1. Super-Admin ist IMMER Admin
    if (userNpub == superAdminNpub) {
      return AdminCheckResult(
        isAdmin: true,
        meetup: 'Alle Meetups',
        name: 'Super-Admin',
        source: 'super_admin',
      );
    }

    // 2. Cache prüfen (schnell, offline)
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

    // 3. Kein Cache-Treffer → Relay fragen (blockierend, mit Timeout)
    try {
      final relayList = await fetchFromRelays();
      if (relayList != null && relayList.isNotEmpty) {
        await _saveToCache(relayList);
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
  // RELAY FETCH (das Herzstück!)
  // Verbindet per WebSocket zu Nostr Relays,
  // fragt nach dem Admin-Listen-Event vom Super-Admin,
  // verifiziert die Signatur, extrahiert die Liste.
  // =============================================
  static Future<List<AdminEntry>?> fetchFromRelays() async {
    // Super-Admin pubkey in Hex (für die Relay-Query)
    String superAdminHex;
    try {
      if (superAdminNpub == "DEIN_NPUB_HIER") {
        print('[AdminRegistry] Super-Admin npub noch nicht konfiguriert!');
        return null;
      }
      superAdminHex = Nip19.decodePubkey(superAdminNpub);
    } catch (e) {
      print('[AdminRegistry] Ungültiger Super-Admin npub: $e');
      return null;
    }

    // Versuche jeden Relay der Reihe nach
    for (final relayUrl in _relays) {
      try {
        final result = await _fetchFromSingleRelay(relayUrl, superAdminHex);
        if (result != null) {
          print('[AdminRegistry] Admin-Liste von $relayUrl geladen (${result.length} Admins)');
          return result;
        }
      } catch (e) {
        print('[AdminRegistry] $relayUrl fehlgeschlagen: $e');
        continue; // Nächsten Relay versuchen
      }
    }

    print('[AdminRegistry] Kein Relay erreichbar');
    return null;
  }

  // =============================================
  // EINZELNEN RELAY ABFRAGEN
  // =============================================
  static Future<List<AdminEntry>?> _fetchFromSingleRelay(
    String relayUrl, 
    String authorHex,
  ) async {
    WebSocket? ws;
    
    try {
      // 1. WebSocket verbinden
      ws = await WebSocket.connect(relayUrl).timeout(_relayTimeout);
      
      final completer = Completer<List<AdminEntry>?>();
      final subscriptionId = 'admin-list-${DateTime.now().millisecondsSinceEpoch}';

      // 2. Listener für Antworten
      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3) {
              // Event empfangen!
              final eventData = message[2] as Map<String, dynamic>;
              
              // Signatur prüfen
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

              // Ist das Event vom richtigen Author?
              if (event.pubkey != authorHex) {
                print('[AdminRegistry] Event von falschem Author: ${event.pubkey}');
                return;
              }

              // Signatur valid?
              if (!event.isValid()) {
                print('[AdminRegistry] Ungültige Event-Signatur!');
                return;
              }

              // Content parsen
              try {
                final content = jsonDecode(event.content) as Map<String, dynamic>;
                final admins = (content['admins'] as List<dynamic>?)
                    ?.map((e) => AdminEntry.fromJson(e as Map<String, dynamic>))
                    .toList() ?? [];
                
                if (!completer.isCompleted) {
                  completer.complete(admins);
                }
              } catch (e) {
                print('[AdminRegistry] Content-Parse Fehler: $e');
              }
            } 
            else if (type == 'EOSE') {
              // End of Stored Events - keine weiteren Events
              if (!completer.isCompleted) {
                completer.complete(null); // Kein Event gefunden
              }
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

      // 3. Subscription Request senden
      // Fragt: "Gib mir das neueste Kind-30078 Event vom Super-Admin mit Tag d=einundzwanzig-admins"
      final request = jsonEncode([
        'REQ',
        subscriptionId,
        {
          'kinds': [_eventKind],
          'authors': [authorHex],
          '#d': [_eventDTag],
          'limit': 1,
        }
      ]);
      
      ws.add(request);

      // 4. Auf Antwort warten (mit Timeout)
      final result = await completer.future.timeout(
        _relayTimeout,
        onTimeout: () => null,
      );

      // 5. Subscription beenden
      ws.add(jsonEncode(['CLOSE', subscriptionId]));
      
      return result;

    } catch (e) {
      rethrow;
    } finally {
      // WebSocket immer schließen
      try { ws?.close(); } catch (_) {}
    }
  }

  // =============================================
  // HINTERGRUND-REFRESH
  // Aktualisiert Cache ohne zu blockieren
  // =============================================
  static void _refreshFromRelaysInBackground() async {
    try {
      final age = await cacheAge();
      // Nur refreshen wenn Cache älter als 1 Stunde
      if (age != null && age.inHours < 1) return;
      
      final relayList = await fetchFromRelays();
      if (relayList != null) {
        await _saveToCache(relayList);
        print('[AdminRegistry] Cache im Hintergrund aktualisiert');
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
  }

  static Future<void> removeAdmin(String npub) async {
    final list = await getAdminList();
    list.removeWhere((e) => e.npub == npub);
    await _saveToCache(list);
  }

  // =============================================
  // NOSTR EVENT ERSTELLEN + PUBLISHEN
  // Erstellt das signierte Event UND sendet es an Relays
  // =============================================
  static Future<String> createAndPublishAdminListEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex');

    if (privHex == null) {
      throw Exception('Kein Nostr-Key vorhanden.');
    }

    final list = await getAdminList();
    final content = jsonEncode({
      'admins': list.map((e) => e.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Signiertes Nostr Event erstellen
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

    // An alle Relays senden
    int successCount = 0;
    List<String> errors = [];

    for (final relayUrl in _relays) {
      try {
        final ws = await WebSocket.connect(relayUrl).timeout(
          const Duration(seconds: 5),
        );
        ws.add(eventJson);
        
        // Kurz warten auf OK-Antwort
        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        successCount++;
        print('[AdminRegistry] Event an $relayUrl gesendet ✓');
      } catch (e) {
        errors.add('$relayUrl: $e');
        print('[AdminRegistry] $relayUrl fehlgeschlagen: $e');
      }
    }

    // JSON des Events für Anzeige/Kopieren
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

  // Legacy: Nur Event JSON erzeugen ohne zu publishen
  static Future<String> createAdminListEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex');

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

  /// Cache manuell leeren (z.B. bei Logout)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }

  /// Admin-Liste manuell von Relays neu laden
  static Future<int> forceRefresh() async {
    final relayList = await fetchFromRelays();
    if (relayList != null) {
      await _saveToCache(relayList);
      return relayList.length;
    }
    return -1; // Fehler
  }
}