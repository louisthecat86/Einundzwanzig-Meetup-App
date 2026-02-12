// ============================================
// ADMIN REGISTRY
// Verwaltet die Liste vertrauenswürdiger Admins
// ============================================
//
// Konzept:
//   Ein "Super-Admin" (z.B. der Einundzwanzig Verein) pflegt eine Liste
//   von npubs die als Meetup-Organisatoren anerkannt sind.
//
//   Diese Liste wird als signiertes Nostr-Event auf Relays publiziert.
//   Die App lädt die Liste, prüft die Signatur, und cached sie lokal.
//
// Ablauf:
//   1. App startet → Admin-Liste laden (Cache → Relay → Fallback)
//   2. User hat Nostr-Key? → Ist sein npub in der Liste?
//   3. Ja → Automatisch Admin. Kein Passwort, kein NFC-Tag nötig.
//
// Admin-Event Format (Nostr Kind 30078):
//   {
//     "kind": 30078,
//     "tags": [["d", "einundzwanzig-admins"]],
//     "content": "{\"admins\": [{\"npub\": \"...\", \"meetup\": \"München\", \"name\": \"Max\"}]}"
//   }
// ============================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'nostr_service.dart';

class AdminEntry {
  final String npub;
  final String meetup;
  final String name;
  final int addedAt; // Unix timestamp

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
  final String? meetup;    // Für welches Meetup ist er Admin
  final String? name;      // Admin-Name aus der Registry
  final String source;     // 'nostr_relay', 'local_cache', 'hardcoded', 'password'

  AdminCheckResult({
    required this.isAdmin,
    this.meetup,
    this.name,
    required this.source,
  });
}

class AdminRegistry {
  // =============================================
  // SUPER-ADMIN: Wer darf die Admin-Liste pflegen?
  // Das ist DEIN npub (der App-Ersteller)
  // =============================================
  static const String superAdminNpub = "npub1lf0rga7j66uj6enae2mxezamz5nsz3vechhvmh25tcarn4u8qf5q534jzc"; // TODO: Eigenen npub einsetzen!

  // Nostr Relays zum Laden der Admin-Liste
  static const List<String> _relays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.nostr.band',
  ];

  // Cache Key
  static const String _cacheKey = 'admin_registry_cache';
  static const String _cacheTimestampKey = 'admin_registry_timestamp';

  // =============================================
  // ADMIN-CHECK: Ist dieser npub ein Admin?
  // =============================================
  static Future<AdminCheckResult> checkAdmin(String userNpub) async {
    if (userNpub.isEmpty) {
      return AdminCheckResult(isAdmin: false, source: 'no_key');
    }

    // 1. Super-Admin ist immer Admin
    if (userNpub == superAdminNpub) {
      return AdminCheckResult(
        isAdmin: true,
        meetup: 'Alle Meetups',
        name: 'Super-Admin',
        source: 'super_admin',
      );
    }

    // 2. Lokalen Cache prüfen (schnell, offline-fähig)
    final cachedList = await _loadFromCache();
    if (cachedList != null) {
      final entry = cachedList.where((e) => e.npub == userNpub).firstOrNull;
      if (entry != null) {
        return AdminCheckResult(
          isAdmin: true,
          meetup: entry.meetup,
          name: entry.name,
          source: 'local_cache',
        );
      }
    }

    // 3. Von Nostr Relays laden (wenn online)
    try {
      final relayList = await _fetchFromRelays();
      if (relayList != null) {
        // Cache aktualisieren
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
      // Offline → Cache-Ergebnis gilt (oben schon geprüft)
      print('[AdminRegistry] Relay-Fetch fehlgeschlagen: $e');
    }

    return AdminCheckResult(isAdmin: false, source: 'not_found');
  }

  // =============================================
  // ADMIN-LISTE LADEN (Cache)
  // =============================================
  static Future<List<AdminEntry>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json == null) return null;

      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => AdminEntry.fromJson(e)).toList();
    } catch (e) {
      return null;
    }
  }

  // =============================================
  // ADMIN-LISTE SPEICHERN (Cache)
  // =============================================
  static Future<void> _saveToCache(List<AdminEntry> admins) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(admins.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, json);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  // =============================================
  // ADMIN-LISTE VON NOSTR RELAYS LADEN
  // Sucht nach Kind 30078 Events vom Super-Admin
  // =============================================
  static Future<List<AdminEntry>?> _fetchFromRelays() async {
    // TODO: Relay-Verbindung implementieren
    // Für den MVP nutzen wir die lokale Liste
    // 
    // Die Implementierung würde so aussehen:
    //
    // 1. WebSocket zu Relay öffnen
    // 2. REQ senden: {"kinds": [30078], "authors": [superAdminPubkeyHex], "#d": ["einundzwanzig-admins"]}
    // 3. Event empfangen
    // 4. Signatur prüfen (event.isValid())
    // 5. Content parsen → Admin-Liste
    //
    // Für jetzt: null zurückgeben → Cache wird genutzt
    return null;
  }

  // =============================================
  // ADMIN-LISTE LOKAL VERWALTEN
  // Für den Super-Admin: Admins hinzufügen/entfernen
  // =============================================

  /// Alle gecachten Admins laden (für Anzeige)
  static Future<List<AdminEntry>> getAdminList() async {
    final cached = await _loadFromCache();
    return cached ?? [];
  }

  /// Admin hinzufügen (lokal + optional auf Relay publishen)
  static Future<void> addAdmin(AdminEntry admin) async {
    final list = await getAdminList();

    // Duplikat-Check
    if (list.any((e) => e.npub == admin.npub)) {
      throw Exception('Dieser npub ist bereits in der Admin-Liste.');
    }

    // Validierung
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

  /// Admin entfernen
  static Future<void> removeAdmin(String npub) async {
    final list = await getAdminList();
    list.removeWhere((e) => e.npub == npub);
    await _saveToCache(list);
  }

  // =============================================
  // NOSTR EVENT ERSTELLEN (für Super-Admin)
  // Erstellt ein signiertes Event mit der Admin-Liste
  // Kann dann auf Relays gepublished werden
  // =============================================
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

    // Nostr Event Kind 30078 (Parameterized Replaceable Event)
    // Tag "d" = "einundzwanzig-admins" → wird beim Update überschrieben
    final event = Event.from(
      kind: 30078,
      tags: [
        ['d', 'einundzwanzig-admins'],
      ],
      content: content,
      privkey: privHex,
    );

    // JSON des Events zum Kopieren/Publishen
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
  // CACHE-ALTER PRÜFEN
  // =============================================
  static Future<Duration?> cacheAge() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return null;
    return DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}