import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import '../models/calendar_event.dart'; // Importiere das neue Modell
import 'recurrence_expander.dart';
import 'portal_api_service.dart';
import 'app_logger.dart';

class MeetupCalendarService {
  static bool _loggedStartFormat = false;

  /// Zeitzonensicheres Parsen der Portal-'start'-Angabe.
  /// Ohne Zone ("2026-07-21 18:00") -> ist bereits lokale Portal-Zeit.
  /// Mit 'Z'/Offset -> als UTC parsen und in Geraetezeit umrechnen.
  /// Loggt einmal pro Session Rohformat UND Ergebnis ins Diagnose-Log.
  static DateTime? portalStart(String rawIn) {
    final s = rawIn.trim();
    if (s.isEmpty) return null;
    final logThis = !_loggedStartFormat;
    _loggedStartFormat = true;
    final hasZone = s.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    // BEWIESEN durch Log-Kreuzvergleich mit dem Portal-Web (Hildesheim
    // 18:00 CEST kam als "16:00" an, Bad Kissingen 18:30 als "16:30", …):
    // Die Live-Instanz liefert ALLE Zeiten als UTC — aber OHNE Kennung.
    // Deshalb: ohne Zone -> als UTC interpretieren und in Geraetezeit
    // umrechnen. Mit Z/Offset -> normal umrechnen.
    final result = hasZone
        ? dt.toLocal()
        : DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
            .toLocal();
    if (logThis) {
      AppLogger.diag('Portal',
          'start-Rohformat "$s" (als UTC gedeutet) -> angezeigt ${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}');
    }
    return result;
  }

  static bool _loggedUtcFormat = false;

  /// Fuer Endpunkte, die die ROHE Datenbank-Zeit liefern (z.B.
  /// /my-meetup-events im Organisator-Bereich): Laravel speichert UTC,
  /// dieser Endpunkt gibt sie OHNE Zonenkennung heraus ("2026-07-21 16:00"
  /// = 16:00 UTC = 18:00 MESZ). Deshalb hier: ohne Kennung -> als UTC
  /// interpretieren und in Geraetezeit umrechnen. Mit Z/Offset -> normal.
  /// (Gegenstueck: /meetup-events/{datum} liefert bereits Berlin-Zeit ->
  /// dafuer gilt portalStart, NICHT diese Funktion.)
  static DateTime? portalStartUtc(String rawIn) {
    final s = rawIn.trim();
    if (s.isEmpty) return null;
    if (!_loggedUtcFormat) {
      _loggedUtcFormat = true;
      AppLogger.diag('Portal', 'my-meetup-events Rohformat: "$s"');
    }
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    if (dt.isUtc) return dt.toLocal(); // hatte Z/Offset
    return DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        .toLocal();
  }

  /// WAPPEN-REGISTRY: Meetup-Name ODER Stadt -> Logo-URL.
  ///
  /// Gefuellt beim Portal-Laden. Der Name allein reicht nicht: Ein Badge
  /// traegt die Stadt ("Ostwestfalen-Lippe"), das Portal die Gruppe
  /// ("Einundzwanzig OWL"). Ohne den zweiten Schluessel findet die Suche
  /// das vorhandene Logo nicht.
  static final Map<String, String> portalLogos = {};

  /// Merkt ein Wappen unter einem Namen oder einer Stadt.
  /// Leere Werte werden ignoriert. Dieselbe URL darf unter mehreren
  /// Schluesseln stehen.
  static void rememberLogo(String label, String logo) {
    final key = label.trim();
    final url = logo.trim();
    if (key.isEmpty || url.isEmpty) return;
    portalLogos[key] = url;
  }

  /// Macht relative Portal-Bildpfade absolut ("/storage/x.png" ->
  /// "https://portal.einundzwanzig.space/storage/x.png"). Image.network
  /// scheitert an relativen Pfaden STILL — das Wappen fehlte dann einfach.
  static String absoluteImageUrl(String url) {
    final u = url.trim();
    if (u.isEmpty || u.startsWith('http://') || u.startsWith('https://')) return u;
    return 'https://portal.einundzwanzig.space${u.startsWith('/') ? '' : '/'}$u';
  }

  /// Liefert das Wappen zu einem Gruppennamen oder einer Stadt, nur exakt.
  ///
  /// Keine Teilstring-Suche: "Ulm" fand damit das Wappen von Neu-Ulm, "Au"
  /// das von Augsburg. Beide Schluessel liegen hier, der Kalender fragt mit
  /// dem Gruppennamen, das Badge mit der Stadt. Was nicht exakt passt,
  /// bekommt lieber kein Wappen als ein fremdes.
  static String logoFor(String titleOrCity) {
    final q = titleOrCity.trim().toLowerCase();
    if (q.isEmpty) return '';
    for (final entry in portalLogos.entries) {
      if (entry.key.toLowerCase() == q) return absoluteImageUrl(entry.value);
    }
    return '';
  }

  /// ZENTRALE QUELLE für Meetup-Termine (Anzeige): PORTAL ZUERST
  /// (/api/meetup-events — exakte Meetup-Namen, saubere Daten),
  /// Fallback iCal-Feed. Alle Screens sollen DIESE Methode nutzen,
  /// damit überall dasselbe, konsistente Bild entsteht.
  Future<List<CalendarEvent>> fetchMeetupsPortalFirst() async {
    try {
      final portal = await PortalApiService.getAllMeetupEvents();
      final cutoff = DateTime.now().subtract(const Duration(hours: 6));
      final events = <CalendarEvent>[];
      for (final e in portal) {
        final start = portalStart((e['start'] ?? '').toString());
        if (start == null || start.isBefore(cutoff)) continue;
        // WICHTIG: Die API liefert die Meetup-Felder FLACH mit Punkt-
        // Schlüsseln ("meetup.name", "meetup.logo") — nicht verschachtelt!
        String mv(String key) {
          final nested = e['meetup'];
          if (nested is Map && nested[key] != null) return nested[key].toString();
          final flat = e['meetup.$key'];
          return flat == null ? '' : flat.toString();
        }
        final name = mv('name').trim().isNotEmpty ? mv('name').trim() : 'Meetup';
        final logo = mv('logo');
        // Name UND Stadt. Das Badge sucht spaeter mit der Stadt, der
        // Kalender mit dem Gruppennamen.
        rememberLogo(name, logo);
        rememberLogo(mv('city'), logo);
        final link = (e['link'] ?? '').toString();
        events.add(CalendarEvent(
          title: name,
          description: (e['description'] ?? '').toString(),
          location: (e['location'] ?? '').toString(),
          startTime: start,
          url: link.isNotEmpty ? link : mv('portalLink'),
          // Die Portal-ID kommt ueber denselben flachen Schluessel wie Name
          // und Logo. Damit laesst sich ein Termin eindeutig einem Meetup
          // zuordnen, statt ueber Namensvergleiche zu raten.
          meetupId: mv('id'),
          meetupPortalLink: mv('portalLink'),
          // Achtung, zwei verschiedene Nummern: mv('id') ist das MEETUP,
          // e['id'] der einzelne TERMIN. Die Zusage haengt am Termin.
          portalEventId: e['id'] is int ? e['id'] as int : null,
        ));
      }
      if (events.isNotEmpty) {
        events.sort((a, b) => a.startTime.compareTo(b.startTime));
        final f = events.first;
        AppLogger.diag('Calendar',
            'QUELLE=PORTAL (${events.length} Termine). Erster: "${f.title}" -> ${f.startTime.hour.toString().padLeft(2, '0')}:${f.startTime.minute.toString().padLeft(2, '0')}');
        return events;
      }
    } catch (e) {
      AppLogger.debug('Calendar', 'Portal-Termine fehlgeschlagen, iCal-Fallback: $e');
    }
    return fetchMeetups(); // iCal-Fallback
  }

  static const String calendarUrl = 'https://portal.einundzwanzig.space/stream-calendar';

  Future<List<CalendarEvent>> fetchMeetups() async {
    try {
      final response = await http.get(Uri.parse(calendarUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final iCalString = utf8.decode(response.bodyBytes);
        // DIAGNOSE: rohe DTSTART-Zeile des ICS einmalig festhalten —
        // beweist, ob die Quelle UTC ('Z') oder lokale Zeit liefert.
        final m = RegExp(r'DTSTART[^:\n]*:[^\r\n]+').firstMatch(iCalString);
        AppLogger.diag('Calendar', 'QUELLE=ICS. Roh: "${m?.group(0) ?? 'kein DTSTART gefunden'}"');
        final iCalendar = ICalendar.fromString(iCalString);
        
        List<CalendarEvent> events = [];
        
        for (var item in iCalendar.data) {
          if (item['type'] == 'VEVENT') {
            // Basis-Event parsen
            final base = CalendarEvent.fromMap(item);
            // Wiederkehrende Termine (RRULE) in einzelne Vorkommen expandieren.
            // Ohne RRULE liefert expand() einfach nur [base].
            final rrule = item['rrule']?.toString();
            events.addAll(RecurrenceExpander.expand(base, rrule));
          }
        }
        
        // Sortieren: Nächste Termine zuerst
        events.sort((a, b) => a.startTime.compareTo(b.startTime));

        // Nur Termine in der Zukunft anzeigen (optional)
        // events = events.where((e) => e.startTime.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();

        return events;
      } else {
        throw Exception('Server Fehler: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('App', "Fehler im CalendarService: $e");
      return [];
    }
  }
}

