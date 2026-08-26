import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meetup.dart';
import 'package:nostr/nostr.dart';

import 'app_logger.dart';

class MeetupService {
  /// Die schlanke Liste fuer die App.
  ///
  /// Frueher /api/meetups — der Karten-Endpunkt mit allen Feldern. Diese
  /// Fassung liefert nur, was Liste und Karte brauchen, und ist spuerbar
  /// schneller. Feldnamen sind dieselben, deshalb aendert sich am Einlesen
  /// nichts.
  static const String _url =
      "https://portal.einundzwanzig.space/api/mobile/meetups";

  /// Erste brauchbare Zahl aus mehreren moeglichen Feldnamen.
  /// Das Portal liefert Koordinaten je nach Endpunkt als
  /// 'latitude'/'longitude' ODER 'lat'/'lon'/'lng'.
  static double _firstNum(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c is num) return c.toDouble();
      if (c is String) {
        final v = double.tryParse(c);
        if (v != null) return v;
      }
    }
    return 0.0;
  }

  /// Zwischengespeicherte Liste — fuer das Aufloesen von Favoriten.
  ///
  /// Favoriten werden als Portal-ID gespeichert. Um daraus Stadt, Wappen
  /// oder Land zu bekommen, braucht es das Meetup-Objekt; ohne Cache waere
  /// das je Kachel ein Netzabruf.
  static List<Meetup> _cache = const [];

  /// Zuletzt geladene Meetups, moeglicherweise leer.
  static List<Meetup> get cached => _cache;

  /// Loest einen gespeicherten Favoriten auf.
  ///
  /// Nimmt zuerst die Portal-ID. Schlaegt das fehl, wird der Wert als
  /// STADTNAME gedeutet — so bleiben Favoriten aus aelteren Fassungen
  /// nutzbar, die noch Staedte gespeichert haben. Bei mehreren Meetups in
  /// derselben Stadt gewinnt dann das erste; genau diese Mehrdeutigkeit ist
  /// der Grund fuer die Umstellung auf die ID.
  static Meetup? resolveFavorite(String stored) {
    if (stored.isEmpty || _cache.isEmpty) return null;
    for (final m in _cache) {
      if (m.id == stored) return m;
    }
    // Rueckfall auf den Stadtnamen — nur fuer Favoriten aus aelteren
    // Fassungen. Gibt es in der Stadt MEHRERE Meetups, ist die Antwort
    // geraten; das gehoert ins Log, damit man den Ursprung eines falschen
    // Wappens oder Termins wiederfindet.
    final sameCity = _cache
        .where((m) => m.city.toLowerCase() == stored.toLowerCase())
        .toList();
    if (sameCity.isEmpty) return null;
    if (sameCity.length > 1) {
      AppLogger.debug('Meetups',
          'Favorit "$stored" ist mehrdeutig (${sameCity.length} Meetups) — genommen: ${sameCity.first.name}');
    }
    return sameCity.first;
  }

  /// Anzeigename eines gespeicherten Favoriten.
  ///
  /// Bei mehreren Meetups in einer Stadt der GRUPPENNAME ("BitcoinWalk
  /// Würzburg"), sonst die Stadt. Zwei Karten mit derselben Aufschrift
  /// waeren sonst nicht auseinanderzuhalten.
  static String labelFor(String stored) {
    final m = resolveFavorite(stored);
    if (m == null) return stored;
    final sameCity =
        _cache.where((x) => x.city.toLowerCase() == m.city.toLowerCase()).length;
    if (sameCity > 1 && m.name.isNotEmpty) return m.name;
    return m.city;
  }

  /// Stadt eines gespeicherten Favoriten — fuer Terminsuche und Wappen.
  static String cityFor(String stored) => resolveFavorite(stored)?.city ?? stored;

  /// Ist dieser Pubkey der im Portal hinterlegte Schluessel eines Meetups?
  ///
  /// Das Portal fuehrt je Meetup ein `nostr`-Feld — den Schluessel der Gruppe
  /// beziehungsweise ihres Betreuers. Wer dort eingetragen ist, betreut ein
  /// Meetup; genau das wollte die Admin-Registry wissen und konnte es bisher
  /// nicht beantworten.
  ///
  /// Der Grund, warum es das braucht: Die Registry kennt in der Anfangsphase
  /// NUR die vom Super-Admin veroeffentlichte Liste. Ein Organisator, der
  /// sein Meetup im Portal betreut, war fuer jedes fremde Geraet ein
  /// Unbekannter — und der Weg ueber gesammelte Badges scheitert daran, dass
  /// dafuer schon bekannte Aussteller noetig waeren.
  ///
  /// Nimmt hex ODER npub, weil beide Schreibweisen im Umlauf sind.
  /// Laedt die Liste bei Bedarf nach.
  ///
  /// Beim Scannen kann sie noch fehlen — dann waere die Antwort "unbekannt",
  /// obwohl nur die Daten fehlten. Genau diese Verwechslung von "nicht
  /// gefunden" und "nicht nachgesehen" hat uns hier schon zweimal Zeit
  /// gekostet.
  /// Meetup zu einem Anzeigenamen, wie er auf dem Badge steht.
  ///
  /// Vergleicht Name UND Stadt, weil Badges mal das eine und mal das andere
  /// tragen ("Einundzwanzig Aschaffenburg" gegen "Aschaffenburg").
  static Meetup? byName(String name) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty || _cache.isEmpty) return null;
    for (final m in _cache) {
      if (m.name.trim().toLowerCase() == n) return m;
    }
    for (final m in _cache) {
      if (m.city.trim().toLowerCase() == n) return m;
    }
    return null;
  }

  static Future<Meetup?> organizerMeetupFor(String pubkeyHexOrNpub) async {
    if (pubkeyHexOrNpub.isEmpty) return null;
    if (_cache.isEmpty) {
      try {
        await fetchMeetups();
      } catch (_) {
        return null;
      }
    }
    if (_cache.isEmpty) return null;

    // Auf npub bringen: Das Portal speichert npub, der Scanner hat hex.
    String npub = pubkeyHexOrNpub;
    if (!npub.startsWith('npub')) {
      try {
        npub = Nip19.encodePubkey(pubkeyHexOrNpub);
      } catch (_) {
        return null;
      }
    }

    for (final m in _cache) {
      if (m.nostrNpub.isNotEmpty && m.nostrNpub.trim() == npub) return m;
    }
    return null;
  }

  static Future<List<Meetup>> fetchMeetups() async {
    try {
      final response = await http.get(Uri.parse(_url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final list = data.map((json) {
          // Bestes verfügbares Bild auswählen (Cover > Image > Logo)
          String image = "";
          if (json['cover'] != null && json['cover'].toString().isNotEmpty) {
            image = json['cover'];
          } else if (json['image'] != null && json['image'].toString().isNotEmpty) {
            image = json['image'];
          } else if (json['logo'] != null && json['logo'].toString().isNotEmpty) {
            image = json['logo'];
          }

          return Meetup(
            id: json['id']?.toString() ?? json['name'] ?? "unknown",
            name: json['name']?.toString() ?? "",
            city: json['city'] ?? json['name'] ?? "Unbekannt",
            country: json['country'] ?? "DE",
            telegramLink: json['url'] ?? "",
            logoUrl: json['logo'] ?? "",
            description: json['intro'] ?? "",
            website: json['website'] ?? "",
            portalLink: json['portalLink'] ?? "",
            twitterUsername: json['twitter_username'] ?? "",
            nostrNpub: json['nostr'] ?? "",
            // ROBUST gegen beide Portal-Feldnamen: die API nutzt teils
            // 'latitude'/'longitude', teils 'lat'/'lon'/'lng'. Wird nur EINE
            // Variante geparst und die API liefert die andere, sind alle
            // Koordinaten 0 -> die "In der Nähe"-Suche findet nichts, weil
            // sie Meetups ohne Koordinaten aussortiert.
            lat: _firstNum([json['latitude'], json['lat']]),
            lng: _firstNum([json['longitude'], json['lon'], json['lng']]),
            coverImagePath: image,
          );
        }).toList();

        // ---- DIAGNOSE: doppelte Eintraege sichtbar machen ----
        // Die App bildet jeden API-Datensatz 1:1 ab und zeigt davon nur die
        // Stadt an. Liefert das Portal zwei Datensaetze fuer denselben Ort
        // (zwei Gruppen ODER ein Altbestand), sehen sie in der Liste
        // identisch aus. Das Log nennt Ross und Reiter.
        final byCity = <String, List<Meetup>>{};
        for (final m in list) {
          byCity.putIfAbsent(m.city.trim().toLowerCase(), () => []).add(m);
        }
        // EINE Zeile statt einer pro Stadt: beim letzten Feldlauf waren das
        // 18 von rund 50 Zeilen — ein Drittel des Ringpuffers fuer einen
        // Umstand, der sich in einem Satz sagen laesst. Der Puffer haelt
        // 800 Eintraege und soll einen ganzen Meetup-Abend abdecken.
        final dupes = byCity.entries.where((e) => e.value.length > 1).toList();
        if (dupes.isNotEmpty) {
          // Nur die ersten acht nennen: mit allen 28 wurde die Zeile 432
          // Zeichen lang und im Log-Screen unlesbar. Die vollstaendige Liste
          // steht darunter auf debug-Ebene.
          const maxNamed = 8;
          final named = dupes
              .take(maxNamed)
              .map((e) => '${e.value.first.city} ${e.value.length}x')
              .join(', ');
          final rest = dupes.length - maxNamed;
          AppLogger.diag('Meetups',
              '${dupes.length} Stadt/Staedte kommen mehrfach vom Portal: $named'
              '${rest > 0 ? ' … und $rest weitere' : ''}');
          // Die Portal-IDs braucht man erst, wenn man einem Fall nachgeht —
          // deshalb debug (nur im Ausfuehrlich-Modus im Puffer).
          for (final e in dupes) {
            AppLogger.debug('Meetups',
                '"${e.value.first.city}" IDs: ${e.value.map((m) => m.id).join(", ")}');
          }
        }

        // ---- Nur EXAKTE Doubletten entfernen (identische Portal-ID) ----
        // Zwei verschiedene Gruppen in derselben Stadt bleiben erhalten —
        // das sind echte, unterschiedliche Meetups.
        final seenIds = <String>{};
        final unique = <Meetup>[];
        for (final m in list) {
          if (seenIds.add(m.id)) unique.add(m);
        }
        if (unique.length != list.length) {
          AppLogger.warn('Meetups',
              '${list.length - unique.length} Eintrag/Eintraege mit identischer ID entfernt.');
        }
        // Cache fuellen — resolveFavorite() lebt davon.
        _cache = unique;
        return unique;
      } else {
        AppLogger.warn('Meetups', 'Portal antwortete mit HTTP ${response.statusCode}.');
        return [];
      }
    } catch (e) {
      AppLogger.warn('App', "Fehler beim Laden der Meetups: $e");
      return [];
    }
  }
}