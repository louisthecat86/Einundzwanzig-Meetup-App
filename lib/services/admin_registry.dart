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
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'nostr_service.dart';
import 'secure_key_store.dart';
import 'app_logger.dart';

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
  // NEU: Separate Speicherung für MEINE persönlichen Bürgschaften
  // (getrennt vom Netzwerk-Cache, der ALLE Admins enthält)
  static const String _myVouchesKey = 'my_personal_vouches';
  // NEU: Zählt einzigartige Autoren die Admin-Listen publiziert haben
  // Sunset wird NUR durch verschiedene Autoren ausgelöst, nicht durch
  // einen einzelnen Admin der 20 npubs auf seine Liste setzt.
  static const String _uniqueAuthorsKey = 'admin_unique_authors_count';

  // Timeout für Relay-Verbindung
  static const Duration _relayTimeout = Duration(seconds: 8);

  // =============================================
  // SUNSET LOGIK (Sonnenuntergang für Super-Admin)
  // =============================================

  /// Prüft und setzt den Sunset-Status. Wird nie wieder 'false', wenn einmal 'true'.
  ///
  /// SUNSET wird ausgelöst wenn genug VERSCHIEDENE Autoren eigene
  /// Admin-Listen auf den Relays publiziert haben.
  ///
  /// VORHER (Bug): Zählte Cache-Einträge → Super-Admin fügt 20 npubs hinzu → sofort Sunset
  /// JETZT:  Zählt einzigartige Autoren → 20 verschiedene Admins müssen publizieren
  static Future<bool> isSunsetActive() async {
    final prefs = await SharedPreferences.getInstance();

    // Wenn Sunset schon mal erreicht wurde, bleibt es für immer true
    if (prefs.getBool(_sunsetFlagKey) == true) {
      // Security Audit 2, Fund #6: Konsistenzprüfung.
      // Sunset-Flag darf nur true sein wenn uniqueAuthors >= threshold.
      // Falls manipuliert (z.B. auf gerooteten Geräten): Flag zurücksetzen.
      final int uniqueAuthors = prefs.getInt(_uniqueAuthorsKey) ?? 0;
      if (uniqueAuthors < sunsetThreshold) {
        AppLogger.security('AdminRegistry',
          'Sunset-Flag inkonsistent! Flag=true aber uniqueAuthors='
          '$uniqueAuthors < threshold=$sunsetThreshold. Flag zurückgesetzt.');
        await prefs.setBool(_sunsetFlagKey, false);
        return false;
      }
      return true;
    }

    // Zähle einzigartige Autoren die Admin-Listen publiziert haben
    final int uniqueAuthors = prefs.getInt(_uniqueAuthorsKey) ?? 0;

    // Wenn Schwellenwert erreicht, aktiviere Sunset permanent
    if (uniqueAuthors >= sunsetThreshold) {
      await prefs.setBool(_sunsetFlagKey, true);
      AppLogger.debug('AdminRegistry',
          'BOOTSTRAP SUNSET AKTIVIERT! $uniqueAuthors verschiedene Admins publizieren. '
          'Web of Trust ist nun dezentral.');
      return true;
    }

    return false;
  }

  /// Aktualisiert die Anzahl einzigartiger Autoren (wird nach Relay-Fetch aufgerufen)
  static Future<void> _updateUniqueAuthorsCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_uniqueAuthorsKey, count);
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
      AppLogger.debug('AdminRegistry', 'Relay-Fetch Fehler: $e');

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
        AppLogger.debug('AdminRegistry', 'Bootstrap Phase: Frage Relays nach Super-Admin ($superAdminHex)');

      } catch (e) {
        AppLogger.debug('AdminRegistry', 'Ungültiger Super-Admin npub: $e');

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
      AppLogger.debug('AdminRegistry', 'Sunset Phase: Frage Relays nach Updates von ${authorsToQuery.length} bekannten Admins.');

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
          // Einzigartige Autoren für Sunset-Berechnung aktualisieren
          await _updateUniqueAuthorsCount(result.uniqueAuthors);
          
          // Wenn Sunset aktiv ist, mergen wir die Ergebnisse mit dem Cache
          if (isSunset) {
            return await _mergeWithCache(result.admins);
          } else {
            // In der Bootstrap-Phase überschreibt das Super-Admin-Event alles
            return result.admins;
          }
        }
      } catch (e) {
        AppLogger.debug('AdminRegistry', '$relayUrl fehlgeschlagen: $e');
        continue; // Nächsten Relay versuchen
      }
    }

    AppLogger.debug('AdminRegistry', 'Kein Relay erreichbar');

    return null;
  }

  // Hilfsfunktion: Fügt neu gefundene Admins aus dem Web of Trust dem Cache hinzu
  // =============================================
  // Security Audit M1: Merge mit Revocation-Support
  // =============================================
  // VORHER: Nur additiv (einmal Admin → immer Admin)
  // JETZT:  Relay-Daten haben Vorrang über Cache.
  //         Wenn ein Admin aus dem neuesten Relay-Fetch
  //         fehlt, wird er auch aus dem Cache entfernt.
  //
  //   - Relay-Daten = Wahrheit (signierte Events)
  //   - Cache = nur Offline-Fallback
  //   - Neue Admins werden hinzugefügt
  //   - Fehlende Admins werden entfernt (= Revocation)
  // =============================================
  static Future<List<AdminEntry>> _mergeWithCache(List<AdminEntry> relayEntries) async {
    final cachedList = await _loadFromCache() ?? [];
    
    if (relayEntries.isEmpty) {
      // Relay hatte keine Daten → Cache behalten (Offline-Fallback)
      return cachedList;
    }
    
    // Relay-Daten ersetzen den Cache für bekannte Autoren
    // Neue Einträge aus Relay kommen dazu, fehlende werden entfernt
    final relayNpubs = relayEntries.map((e) => e.npub).toSet();
    
    // Behalte nur Cache-Einträge die AUCH im Relay-Fetch vorhanden sind
    // (oder die ein neueres addedAt haben als der Relay-Fetch)
    final merged = <String, AdminEntry>{};
    
    // Relay-Daten haben Vorrang
    for (final entry in relayEntries) {
      merged[entry.npub] = entry;
    }
    
    // Cache-Einträge die im Relay-Fetch NICHT vorkamen → revoked
    // (werden nicht in die merged Map aufgenommen)
    
    return merged.values.toList();
  }

  // =============================================
  // EINZELNEN RELAY ABFRAGEN (MEHRERE AUTHORS)
  // =============================================

  /// Ergebnis eines Relay-Fetchs (Admin-Liste + Anzahl einzigartiger Autoren)
  static Future<({List<AdminEntry> admins, int uniqueAuthors})?> _fetchFromSingleRelay(
    String relayUrl, 
    List<String> authorsHex,
  ) async {
    WebSocket? ws;
    List<AdminEntry> collectedAdmins = [];
    final Set<String> seenAuthors = {}; // Einzigartige Autoren tracken

    try {
      ws = await WebSocket.connect(relayUrl).timeout(_relayTimeout);
      final completer = Completer<List<AdminEntry>?>();
      // Security Audit M4: Kryptographisch sichere Subscription-ID
      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subscriptionId = 'admin-$subIdHex';

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

              // Einzigartigen Autor tracken (für Sunset-Berechnung)
              seenAuthors.add(event.pubkey);

              try {
                final content = jsonDecode(event.content) as Map<String, dynamic>;
                final adminsInEvent = (content['admins'] as List<dynamic>?)
                    ?.map((e) => AdminEntry.fromJson(e as Map<String, dynamic>))
                    .toList() ?? [];

                // Sammeln aller Admins aus allen Events
                collectedAdmins.addAll(adminsInEvent);
              } catch (e) {
                AppLogger.debug('AdminRegistry', 'Content-Parse Fehler: $e');

              }
            } 
            else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(collectedAdmins);
            }
          } catch (e) {
            AppLogger.debug('AdminRegistry', 'Message-Parse Fehler: $e');

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
        return (admins: uniqueMap.values.toList(), uniqueAuthors: seenAuthors.length);
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
        AppLogger.debug('AdminRegistry', 'Cache im Hintergrund aktualisiert. Total Admins: ${relayList.length}');

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

  /// Netzwerk-Cache: Alle bekannten Admins (von ALLEN Relay-Listen)
  /// ACHTUNG: Nicht für Publish verwenden! Nur für Admin-Checks.
  static Future<List<AdminEntry>> getAdminList() async {
    final cached = await _loadFromCache();
    return cached ?? [];
  }

  // =============================================
  // MEINE BÜRGSCHAFTEN (persönlich, getrennt vom Netzwerk-Cache)
  // =============================================
  //
  // TRENNUNG:
  //   _cacheKey       = Netzwerk-Cache (ALLE Admins von ALLEN Relay-Listen)
  //   _myVouchesKey   = NUR meine persönlichen Bürgschaften
  //
  // WARUM?
  //   Vorher: addAdmin() schrieb in den Netzwerk-Cache
  //           → publish() schickte den gesamten Netzwerk-Cache als "meine" Liste
  //           → Du bürgtest versehentlich für ALLER ANDERER Admins Bürgschaften
  //
  //   Jetzt:  addVouch() schreibt in _myVouchesKey
  //           → publish() sendet NUR deine persönlichen Bürgschaften
  //           → Jeder kontrolliert ausschließlich seine eigene Stimme
  // =============================================

  /// Lädt MEINE persönlichen Bürgschaften (nicht den Netzwerk-Cache!)
  static Future<List<AdminEntry>> getMyVouches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_myVouchesKey);
      if (json == null) {
        // Migration: Wenn _myVouchesKey leer ist aber _cacheKey Daten hat,
        // könnte das ein Erststart nach dem Update sein.
        // Wir starten mit leerer Liste — der Admin muss seine Bürgschaften
        // bewusst neu vergeben. Das ist sicherer als die alte gemischte Liste
        // zu übernehmen.
        return [];
      }
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => AdminEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Speichert MEINE persönlichen Bürgschaften
  static Future<void> _saveMyVouches(List<AdminEntry> vouches) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(vouches.map((e) => e.toJson()).toList());
    await prefs.setString(_myVouchesKey, json);
  }

  /// Fügt eine Bürgschaft zu MEINER Liste hinzu
  static Future<void> addVouch(AdminEntry admin) async {
    final list = await getMyVouches();
    if (list.any((e) => e.npub == admin.npub)) {
      throw Exception('Du bürgst bereits für diesen npub.');
    }
    if (!NostrService.isValidNpub(admin.npub)) {
      throw Exception('Ungültiger npub.');
    }
    // Eigenen npub prüfen — man kann nicht für sich selbst bürgen
    final myNpub = await NostrService.getNpub();
    if (myNpub == admin.npub) {
      throw Exception('Du kannst nicht für dich selbst bürgen.');
    }
    list.add(AdminEntry(
      npub: admin.npub,
      meetup: admin.meetup,
      name: admin.name,
      addedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ));
    await _saveMyVouches(list);
  }

  /// Entzieht eine Bürgschaft aus MEINER Liste
  static Future<void> removeVouch(String npub) async {
    final list = await getMyVouches();
    list.removeWhere((e) => e.npub == npub);
    await _saveMyVouches(list);
  }

  /// Legacy: addAdmin → Netzwerk-Cache (für promotion_claim_service, backup_service)
  /// ACHTUNG: NICHT für persönliches Bürgen verwenden! Dafür → addVouch()
  static Future<void> addAdmin(AdminEntry admin) async {
    final list = await getAdminList();
    if (list.any((e) => e.npub == admin.npub)) return; // Duplikat ignorieren
    if (!NostrService.isValidNpub(admin.npub)) {
      throw Exception('Ungültiger npub.');
    }
    list.add(AdminEntry(
      npub: admin.npub,
      meetup: admin.meetup,
      name: admin.name,
      addedAt: admin.addedAt > 0 ? admin.addedAt : DateTime.now().millisecondsSinceEpoch ~/ 1000,
    ));
    await _saveToCache(list);
  }

  /// Legacy: removeAdmin → Netzwerk-Cache
  static Future<void> removeAdmin(String npub) async {
    final list = await getAdminList();
    list.removeWhere((e) => e.npub == npub);
    await _saveToCache(list);
  }

  // =============================================
  // NOSTR EVENT ERSTELLEN + PUBLISHEN
  // =============================================
  /// Publiziert MEINE persönlichen Bürgschaften (nicht den Netzwerk-Cache!)
  static Future<String> createAndPublishAdminListEvent() async {
    final privHex = await SecureKeyStore.getPrivHex();

    if (privHex == null) {
      throw Exception('Kein Nostr-Key vorhanden.');
    }

    // KRITISCH: Nur MEINE Bürgschaften publishen, nicht den gesamten Netzwerk-Cache!
    final list = await getMyVouches();
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

        // Security Audit M8: Auf OK-Response warten statt blind delay
        bool confirmed = false;
        try {
          await for (final data in ws.timeout(const Duration(seconds: 5))) {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg[0] == 'OK' && msg.length >= 3) {
              confirmed = msg[2] == true;
              break;
            }
          }
        } catch (_) {
          // Timeout → nicht bestätigt
        }
        ws.close();
        if (confirmed) {
          successCount++;
          AppLogger.debug('AdminRegistry', 'Event an $relayUrl bestätigt ✓');
        } else {
          errors.add('$relayUrl: Keine Bestätigung erhalten');
          AppLogger.debug('AdminRegistry', '$relayUrl: Event gesendet aber nicht bestätigt');
        }

      } catch (e) {
        errors.add('$relayUrl: $e');
        AppLogger.debug('AdminRegistry', '$relayUrl fehlgeschlagen: $e');
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

    // MEINE Bürgschaften, nicht den Netzwerk-Cache
    final list = await getMyVouches();
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
