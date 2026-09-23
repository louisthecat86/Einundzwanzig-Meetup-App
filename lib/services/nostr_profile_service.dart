// ============================================
// NOSTR PROFILE SERVICE
// Lädt Profilbild (picture) aus kind:0 Metadata
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';
import 'relay_config.dart';
import 'relay_socket.dart';

class NostrProfileService {
  static const Duration _timeout = Duration(seconds: 6);
  static const String _cacheKey = 'nostr_profile_picture';
  static const String _cacheTimeKey = 'nostr_profile_picture_time';
  static const String _localPicKey = 'local_profile_picture'; // Eigenes Bild (Base64 oder Pfad)
  static const Duration _cacheDuration = Duration(hours: 12);

  /// Lädt das Profilbild-URL für einen pubkey hex.
  /// Cached das Ergebnis für 12 Stunden.
  static Future<String?> fetchProfilePicture(String pubkeyHex) async {
    if (pubkeyHex.isEmpty) return null;

    // Cache prüfen (pubkey-spezifisch, damit ein Identitätswechsel
    // — z.B. nsec → Amber mit anderem npub — nicht das alte Bild zeigt)
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '${_cacheKey}_$pubkeyHex';
    final cacheTimeKey = '${_cacheTimeKey}_$pubkeyHex';
    final cached = prefs.getString(cacheKey);
    final cachedTime = prefs.getInt(cacheTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cached != null && cached.isNotEmpty && (now - cachedTime) < _cacheDuration.inMilliseconds) {
      return cached;
    }

    // Von Relays laden — die KONFIGURIERTEN Relays der App nutzen
    // (inkl. nostr.einundzwanzig.space), nicht nur Standard-Relays.
    List<String> relays;
    try {
      relays = await RelayConfig.getActiveRelays();
      if (relays.isEmpty) relays = RelayConfig.defaultRelays;
    } catch (_) {
      relays = const [
        'wss://relay.damus.io',
        'wss://nos.lol',
        'wss://relay.nostr.band',
        'wss://nostr.einundzwanzig.space',
      ];
    }

    // Parallel über alle Relays abfragen — das erste Treffer-Bild gewinnt.
    // Die Fehlerbehandlung muss BEIM ERSTELLEN im Future stecken, nicht erst
    // in der Schleife weiter unten: die Abfragen laufen ab hier gleichzeitig,
    // und bricht eine ab, bevor die sequentielle Schleife bei ihr angekommen
    // ist, hat noch niemand zugehört — Dart meldet das dann als unbehandelten
    // Fehler und die App stuerzt ab.
    final futures = relays.map((r) async {
      try {
        return await _fetchFromRelay(r, pubkeyHex);
      } catch (e) {
        AppLogger.debug('NostrProfile', 'Relay-Abfrage fehlgeschlagen: $e');
        return null;
      }
    }).toList();
    for (final f in futures) {
      final picture = await f;
      if (picture != null && picture.isNotEmpty) {
        await prefs.setString(cacheKey, picture);
        await prefs.setInt(cacheTimeKey, now);
        return picture;
      }
    }
    return null;
  }

  /// Anzeigename zu einem Pubkey, null wenn keiner hinterlegt ist.
  ///
  /// Eigener Zwischenspeicher und eigene Abfrage neben dem Profilbild: Die
  /// Bildsuche bricht beim ersten Relay ab, das ein Bild liefert — ein Relay
  /// kann aber ein Bild kennen und den Namen nicht. Zwei getrennte Wege sind
  /// hier weniger fehleranfaellig als ein gemeinsamer mit Sonderfaellen.
  static final Map<String, String?> _nameCache = {};

  static Future<String?> fetchDisplayName(String pubkeyHex) async {
    if (pubkeyHex.isEmpty) return null;
    if (_nameCache.containsKey(pubkeyHex)) return _nameCache[pubkeyHex];

    String? found;
    try {
      final relays = await RelayConfig.getActiveRelays();

      // 1. Das Nostr-Profil (kind 0) — der uebliche Ort fuer einen Namen.
      for (final r in relays) {
        found = await _fetchNameFromRelay(r, pubkeyHex);
        if (found != null && found.isNotEmpty) break;
      }

      // 2. Der Spitzname aus dem Reputations-Ereignis.
      //
      // Die App veroeffentlicht KEIN Nostr-Profil. Wer sich in der App einen
      // Namen gibt, hat ihn nur hier stehen — unter identity.nickname. Ohne
      // diesen zweiten Weg blieben ausgerechnet die Leute namenlos, die ihre
      // Identitaet in der App angelegt haben: also fast alle. Im
      // Vertrauensnetzwerk standen deshalb nur npubs.
      if (found == null || found.isEmpty) {
        for (final r in relays) {
          found = await _fetchNicknameFromRelay(r, pubkeyHex);
          if (found != null && found.isNotEmpty) break;
        }
      }
    } catch (_) {
      // Ohne Namen bleibt der gekuerzte npub — kein Grund zu scheitern.
    }
    _nameCache[pubkeyHex] = found;
    return found;
  }

  /// Spitzname aus dem Reputations-Ereignis (kind 30078).
  ///
  /// "Anon" ist der Platzhalter fuer "kein Name gesetzt" und wird wie ein
  /// fehlender Name behandelt — sonst hiesse im Netzwerk die Haelfte "Anon".
  static Future<String?> _fetchNicknameFromRelay(
      String relayUrl, String pubkeyHex) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<String?>();
      final random = Random.secure();
      final subId =
          'nick-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            if (message[0] == 'EVENT' && message.length >= 3) {
              final content =
                  (message[2] as Map<String, dynamic>)['content'] as String? ?? '';
              final body = jsonDecode(content) as Map<String, dynamic>;
              final identity = body['identity'];
              final nick = identity is Map
                  ? (identity['nickname'] as String?)?.trim()
                  : null;
              final usable = (nick != null &&
                      nick.isNotEmpty &&
                      nick.toLowerCase() != 'anon')
                  ? nick
                  : null;
              if (!completer.isCompleted) completer.complete(usable);
            } else if (message[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(null);
            }
          } catch (_) {}
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
        onDone: () { if (!completer.isCompleted) completer.complete(null); },
      );

      ws.add(jsonEncode(['REQ', subId, {
        'kinds': [30078],
        'authors': [pubkeyHex],
        '#d': ['einundzwanzig-reputation'],
        'limit': 1,
      }]));
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      ws?.close();
    }
  }

  static Future<String?> _fetchNameFromRelay(
      String relayUrl, String pubkeyHex) async {
    RelaySocket? ws;
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<String?>();
      final random = Random.secure();
      final subId =
          'nam-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            if (message[0] == 'EVENT' && message.length >= 3) {
              final content =
                  (message[2] as Map<String, dynamic>)['content'] as String? ??
                      '';
              final profile = jsonDecode(content) as Map<String, dynamic>;
              // display_name hat Vorrang — das ist der Name, den Leute fuer
              // die Anzeige waehlen; name ist oft der technische Kurzname.
              final n = (profile['display_name'] as String?)?.trim();
              final alt = (profile['name'] as String?)?.trim();
              if (!completer.isCompleted) {
                completer.complete(
                    (n != null && n.isNotEmpty) ? n : (alt ?? ''));
              }
            } else if (message[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(null);
            }
          } catch (_) {}
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
        onDone: () { if (!completer.isCompleted) completer.complete(null); },
      );

      ws.add(jsonEncode(['REQ', subId, {'kinds': [0], 'authors': [pubkeyHex], 'limit': 1}]));
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } catch (_) {
      return null;
    } finally {
      ws?.close();
    }
  }

  static Future<String?> _fetchFromRelay(String relayUrl, String pubkeyHex) async {
    RelaySocket? ws;
    final tally = RelayParseTally('NostrProfile', 'Profil von $relayUrl');
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<String?>();
      final random = Random.secure();
      final subId = 'pfp-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

      ws.listen(
        (data) {
          tally.message();
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            if (message[0] == 'EVENT' && message.length >= 3) {
              final content = (message[2] as Map<String, dynamic>)['content'] as String? ?? '';
              final profile = jsonDecode(content) as Map<String, dynamic>;
              final picture = profile['picture'] as String?;
              if (!completer.isCompleted) completer.complete(picture);
            } else if (message[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(null);
            }
          } catch (e) { tally.failed(e); }
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
        onDone: () { if (!completer.isCompleted) completer.complete(null); },
      );

      ws.add(jsonEncode(['REQ', subId, {'kinds': [0], 'authors': [pubkeyHex], 'limit': 1}]));
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } finally {
      tally.report();
      ws?.close();
    }
  }

  /// Lokales Profilbild speichern (wenn kein Nostr-Bild vorhanden)
  static Future<void> setLocalPicture(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localPicKey, path);
  }

  /// Lokales Profilbild laden
  static Future<String?> getLocalPicture() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localPicKey);
  }

  /// Cache löschen (z.B. bei App-Reset)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    // pubkey-spezifische Einträge (und evtl. alte globale) entfernen
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_cacheKey) || key.startsWith(_cacheTimeKey)) {
        await prefs.remove(key);
      }
    }
    await prefs.remove(_localPicKey);
  }
}


