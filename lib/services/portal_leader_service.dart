// PORTAL-LEADER
// ============================================
// Beantwortet die Frage, die der Scanner braucht: Betreut dieser npub DIESES
// Meetup?
//
// Quelle: GET /api/meetup-leaders — oeffentlich, ohne Token, gruppiert nach
// Meetup:
//
//   [ { "meetup_id": 2, "npubs": ["npub1…", "npub1…"] }, … ]
//
// ============================================
// WARUM DIE PRUEFUNG JE MEETUP LAEUFT — und niemals ueber alle
// ============================================
//
// Wer im Portal ein Meetup ANLEGT, wird dessen Leader. Und anlegen darf
// jeder Angemeldete. Wuerde diese App die Antwort zu einer flachen Menge
// "das sind alle Organisatoren" einebnen, koennte sich jeder in zwei
// Minuten selbst zum bestaetigten Organisator machen: Meetup anlegen,
// fertig — und dann Badges fuer FREMDE Meetups ausgeben, die als echt
// durchgehen.
//
// Gegen die npubs des GESCANNTEN Meetups geprueft, ist das zu: Dort
// eintragen kann jemanden nur ein bestehender Leader dieses Meetups.
//
// Deshalb gibt es hier bewusst KEINE Methode, die alle npubs zurueckgibt.
// Die Versuchung waere zu gross, und die Luecke waere lautlos.
// ============================================

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';

const String _tag = 'PortalLeader';

class PortalLeaderService {
  PortalLeaderService._();

  static const String _url =
      'https://portal.einundzwanzig.space/api/meetup-leaders';

  static const String _cacheKey = 'portal_leaders_cache';
  static const String _cacheTsKey = 'portal_leaders_cache_ts';

  /// Einen Tag. Leader aendern sich selten, und die Liste soll auch offline
  /// tragen — beim Scannen vor Ort ist oft kein Netz.
  static const Duration _ttl = Duration(hours: 24);

  /// meetup_id -> npubs. Leer, solange nichts geladen wurde.
  static Map<int, Set<String>> _leaders = {};
  static DateTime? _loadedAt;

  /// Laedt die Liste, wenn noetig. [force] umgeht Zwischenspeicher und Alter.
  static Future<void> ensureLoaded({bool force = false}) async {
    final at = _loadedAt;
    if (!force && _leaders.isNotEmpty && at != null &&
        DateTime.now().difference(at) < _ttl) {
      return;
    }

    // Zuerst der lokale Zwischenspeicher: Er macht die Pruefung offline
    // moeglich und haelt den Scanner schnell.
    if (_leaders.isEmpty) await _loadFromCache();

    try {
      final r = await http.get(Uri.parse(_url))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) {
        AppLogger.warn(_tag, 'Portal antwortete mit HTTP ${r.statusCode}.');
        return;
      }
      final data = jsonDecode(r.body) as List<dynamic>;
      final parsed = <int, Set<String>>{};
      for (final e in data) {
        if (e is! Map) continue;
        final id = e['meetup_id'];
        final npubs = e['npubs'];
        if (id is! int || npubs is! List) continue;
        final set = npubs
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet();
        if (set.isNotEmpty) parsed[id] = set;
      }

      // Eine leere Antwort NICHT uebernehmen: Sie kann auch eine Stoerung
      // sein, und dann stuenden ploetzlich alle Organisatoren als
      // unbekannt da.
      if (parsed.isEmpty) {
        AppLogger.warn(_tag, 'Leere Leader-Liste — alter Stand bleibt.');
        return;
      }

      _leaders = parsed;
      _loadedAt = DateTime.now();
      await _saveToCache(r.body);
      AppLogger.info(_tag,
          '${parsed.length} Meetups mit Leadern geladen '
          '(${parsed.values.fold<int>(0, (s, v) => s + v.length)} Eintraege).');
    } catch (e) {
      AppLogger.warn(_tag, 'Leader-Liste nicht abrufbar: $e');
    }
  }

  /// Betreut [npub] das Meetup [meetupId]?
  ///
  /// Gibt null zurueck, wenn keine Auskunft moeglich war — das ist NICHT
  /// dasselbe wie "nein". Der Scanner muss beides unterscheiden, sonst wird
  /// aus einer Netzstoerung ein Vorwurf gegen eine Person.
  static Future<bool?> isLeaderOf(int meetupId, String npub) async {
    if (npub.isEmpty) return null;
    await ensureLoaded();
    if (_leaders.isEmpty) return null;

    final set = _leaders[meetupId];
    // Meetups ohne Leader liefert das Portal gar nicht mit. Fehlt der
    // Eintrag, ist die Antwort ein klares Nein — nicht "unbekannt".
    if (set == null) return false;
    return set.contains(npub.trim());
  }

  /// Wie viele Meetups betreut dieser npub? Nur fuer Anzeige und Diagnose.
  ///
  /// Ausdruecklich NICHT fuer die Pruefung: Dass jemand irgendwo Leader ist,
  /// sagt nichts ueber das Meetup, dessen Badge gerade gescannt wurde.
  static int meetupCountFor(String npub) {
    if (npub.isEmpty || _leaders.isEmpty) return 0;
    final n = npub.trim();
    return _leaders.values.where((s) => s.contains(n)).length;
  }

  // ── Zwischenspeicher ───────────────────────────────────────────────────

  static Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      final ts = prefs.getInt(_cacheTsKey);
      if (raw == null || ts == null) return;

      final data = jsonDecode(raw) as List<dynamic>;
      final parsed = <int, Set<String>>{};
      for (final e in data) {
        if (e is! Map) continue;
        final id = e['meetup_id'];
        final npubs = e['npubs'];
        if (id is! int || npubs is! List) continue;
        parsed[id] = npubs.whereType<String>().toSet();
      }
      if (parsed.isEmpty) return;

      _leaders = parsed;
      _loadedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      AppLogger.debug(_tag, '${parsed.length} Meetups aus dem Speicher.');
    } catch (_) {
      // Ein unlesbarer Zwischenspeicher ist kein Grund zu scheitern.
    }
  }

  static Future<void> _saveToCache(String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, body);
      await prefs.setInt(
          _cacheTsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}
