// ============================================
// NOSTR PROFILE SERVICE
// Lädt Profilbild (picture) aus kind:0 Metadata
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_logger.dart';

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

    // Cache prüfen
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    final cachedTime = prefs.getInt(_cacheTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cached != null && cached.isNotEmpty && (now - cachedTime) < _cacheDuration.inMilliseconds) {
      return cached;
    }

    // Von Relays laden
    final relays = ['wss://relay.damus.io', 'wss://nos.lol', 'wss://relay.nostr.band'];
    for (final relay in relays) {
      try {
        final picture = await _fetchFromRelay(relay, pubkeyHex);
        if (picture != null && picture.isNotEmpty) {
          // Cache speichern
          await prefs.setString(_cacheKey, picture);
          await prefs.setInt(_cacheTimeKey, now);
          return picture;
        }
      } catch (e) {
        AppLogger.debug('NostrProfile', 'Relay $relay fehlgeschlagen: $e');
      }
    }
    return null;
  }

  static Future<String?> _fetchFromRelay(String relayUrl, String pubkeyHex) async {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<String?>();
      final random = Random.secure();
      final subId = 'pfp-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

      ws.listen(
        (data) {
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
          } catch (_) {}
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
        onDone: () { if (!completer.isCompleted) completer.complete(null); },
      );

      ws.add(jsonEncode(['REQ', subId, {'kinds': [0], 'authors': [pubkeyHex], 'limit': 1}]));
      return await completer.future.timeout(_timeout, onTimeout: () => null);
    } finally {
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
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimeKey);
    await prefs.remove(_localPicKey);
  }
}