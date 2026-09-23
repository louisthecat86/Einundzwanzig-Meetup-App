import 'package:geolocator/geolocator.dart';
import '../models/meetup.dart';
import '../models/calendar_event.dart';
import 'meetup_service.dart';
import 'meetup_calendar_service.dart';
import 'app_logger.dart';

/// Ein Meetup mit (optional) zugeordnetem nächsten Termin und Entfernung
/// zum gewählten Suchzentrum.
class NearbyMeetup {
  final Meetup meetup;
  final CalendarEvent? nextEvent; // nächster passender Termin im Zeitfenster
  final List<CalendarEvent> allEvents; // alle passenden Termine
  final double? distanceKm; // Luftlinie vom Suchzentrum (oder null)

  NearbyMeetup({
    required this.meetup,
    this.nextEvent,
    this.allEvents = const [],
    this.distanceKm,
  });

  bool get hasCoords => meetup.lat != 0 || meetup.lng != 0;
}

/// Ergebnis der Standortabfrage.
/// Ergebnis der Ortung.
///
/// [deniedForever] und [noFix] sind eigene Faelle, weil sie eigene Abhilfen
/// brauchen: Bei "fuer immer verweigert" hilft nur der Gang in die
/// App-Einstellungen, bei "kein Fix" ein Schritt ans Fenster. Frueher lief
/// beides unter "error" und bekam denselben Rat — der dann nicht half.
enum LocationStatus { ok, denied, deniedForever, serviceDisabled, noFix, error }

class LocationResult {
  final LocationStatus status;
  final Position? position;
  const LocationResult(this.status, [this.position]);
}

/// Wie der Zeitpunkt eingegrenzt wird.
enum DateMode { any, singleDay, range }

class NearbyMeetupService {
  // Caches, damit beim Verschieben des Reglers nicht neu geladen wird
  static List<Meetup>? _meetupCache;
  static List<CalendarEvent>? _eventCache;

  /// Holt den aktuellen Standort inkl. Permission-Handling.
  static Future<LocationResult> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.denied);
      }
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            // 12s waren zu knapp: In Gebaeuden (Kneipe, Restaurant, Keller)
            // braucht ein frischer Fix regelmaessig laenger — beim Feldtest
            // sind daran zwei Teilnehmer gescheitert, OBWOHL der Standort
            // aktiviert und freigegeben war.
            timeLimit: Duration(seconds: 25),
          ),
        );
        AppLogger.diag('Standort',
            'Frische Position ermittelt (Genauigkeit ${pos.accuracy.toStringAsFixed(0)} m).');
        return LocationResult(LocationStatus.ok, pos);
      } catch (e) {
        // ZWEITER VERSUCH direkt ueber den Android-LocationManager.
        //
        // Der erste Versuch laeuft ueber den Standard-Weg, auf Geraeten mit
        // Google-Diensten also ueber den "Fused Location Provider". Auf
        // GrapheneOS, LineageOS oder mit microG ist dieser Weg mal gar nicht
        // da, mal umgeleitet und mal eigenwillig. Der LocationManager ist
        // das, was Android selbst mitbringt — auf entgoogelten Geraeten oft
        // der einzige Weg, der zuverlaessig einen Fix liefert.
        AppLogger.warn('Standort',
            'Erster Versuch ohne Fix — zweiter ueber den LocationManager.', e);
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.high,
              forceLocationManager: true,
              timeLimit: const Duration(seconds: 20),
            ),
          );
          AppLogger.diag('Standort',
              'Position ueber LocationManager (Genauigkeit ${pos.accuracy.toStringAsFixed(0)} m).');
          return LocationResult(LocationStatus.ok, pos);
        } catch (e2) {
          AppLogger.warn('Standort', 'Auch der LocationManager lieferte keinen Fix.', e2);
        }

        // RUECKFALLEBENE: Kein frischer Fix (meist Timeout drinnen). Eine
        // KUERZLICH bekannte Position ist fuer den Praesenz-Nachweis voellig
        // ausreichend — der Umkreis betraegt 5 km, in 10 Minuten kommt man
        // nicht plausibel von ausserhalb. Aeltere Positionen werden bewusst
        // NICHT akzeptiert, sonst waere der Nachweis wertlos.
        AppLogger.warn('Standort',
            'Kein frischer GPS-Fix — versuche letzte bekannte Position.', e);
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final age = DateTime.now().difference(last.timestamp);
          if (age.inMinutes <= 10) {
            AppLogger.diag('Standort',
                'Letzte bekannte Position akzeptiert (${age.inMinutes} Min alt).');
            return LocationResult(LocationStatus.ok, last);
          }
          AppLogger.warn('Standort',
              'Letzte bekannte Position ist ${age.inMinutes} Min alt — zu alt, verworfen.');
        } else {
          AppLogger.warn('Standort', 'Keine letzte bekannte Position vorhanden.');
        }
        // Dienst an, Berechtigung da — nur kein Fix. Das ist ein EIGENER
        // Fall: Der Rat "Ortungsdienst pruefen" waere hier falsch.
        return const LocationResult(LocationStatus.noFix);
      }
    } catch (e) {
      AppLogger.warn('Nearby', 'Standortfehler: $e');
      return const LocationResult(LocationStatus.error);
    }
  }

  /// Lädt Meetups + Termine (mit Cache). [forceReload] umgeht den Cache.
  static Future<void> preload({bool forceReload = false}) async {
    if (!forceReload && _meetupCache != null && _eventCache != null) return;

    final meetupsFuture = MeetupService.fetchMeetups();
    final eventsFuture = MeetupCalendarService().fetchMeetupsPortalFirst();
    List<Meetup> meetups = await meetupsFuture;
    final events = await eventsFuture;

    if (meetups.isEmpty) meetups = allMeetups; // Offline-Fallback
    // Duplikate vermeiden: dasselbe Meetup (gleiche Stadt) nur einmal,
    // sonst erscheint dieselbe Kachel mehrfach in der Trefferliste.
    final seenCities = <String>{};
    final deduped = <Meetup>[];
    for (final m in meetups) {
      final key = m.city.toLowerCase().trim();
      if (key.isEmpty || seenCities.add(key)) deduped.add(m);
    }
    _meetupCache = deduped;
    _eventCache = events;
  }

  /// Hauptsuche: Meetups im [radiusKm] um [centerLat]/[centerLng], gefiltert
  /// nach Zeit. Liefert nach Entfernung sortierte Liste.
  static Future<List<NearbyMeetup>> search({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    required DateMode dateMode,
    DateTime? dayFrom,
    DateTime? dayTo,
  }) async {
    await preload();
    final meetups = _meetupCache ?? [];
    final events = _eventCache ?? [];

    final now = DateTime.now();

    final List<NearbyMeetup> out = [];
    for (final m in meetups) {
      if (m.lat == 0 && m.lng == 0) continue;
      final distKm = Geolocator.distanceBetween(
            centerLat,
            centerLng,
            m.lat,
            m.lng,
          ) /
          1000.0;
      if (distKm > radiusKm) continue;

      final matchingRaw = _eventsFor(m, events).where((e) {
        switch (dateMode) {
          case DateMode.any:
            return e.startTime.isAfter(now.subtract(const Duration(hours: 12)));
          case DateMode.singleDay:
            return dayFrom != null && _sameDay(e.startTime, dayFrom);
          case DateMode.range:
            if (dayFrom == null || dayTo == null) return false;
            final start = DateTime(dayFrom.year, dayFrom.month, dayFrom.day);
            final end = DateTime(dayTo.year, dayTo.month, dayTo.day, 23, 59, 59);
            return e.startTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
                e.startTime.isBefore(end.add(const Duration(seconds: 1)));
        }
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // Duplikate entfernen: derselbe Termin (Titel + Startzeit + Ort) kann
      // aus dem Kalender-Feed mehrfach kommen (z.B. wiederkehrende Einträge).
      final seen = <String>{};
      final matching = <CalendarEvent>[];
      for (final e in matchingRaw) {
        final key = '${e.title}|${e.startTime.toIso8601String()}|${e.location}';
        if (seen.add(key)) matching.add(e);
      }

      // "any": auch Meetups OHNE Termin zeigen (sind ja in der Nähe).
      // Datums-Modi: nur Meetups MIT passendem Termin.
      if (dateMode != DateMode.any && matching.isEmpty) continue;

      out.add(NearbyMeetup(
        meetup: m,
        nextEvent: matching.isNotEmpty ? matching.first : null,
        allEvents: matching,
        distanceKm: distKm,
      ));
    }

    out.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    return out;
  }

  /// Alle Termine, die zu einem Meetup gehören (Ortsname-Match).
  static List<CalendarEvent> _eventsFor(Meetup m, List<CalendarEvent> events) {
    final city = m.city.toLowerCase().trim();
    if (city.isEmpty) return [];
    return events.where((e) {
      final loc = e.location.toLowerCase();
      final title = e.title.toLowerCase();
      return loc.contains(city) ||
          title.contains(city) ||
          (loc.isNotEmpty && city.contains(loc.split(',').first.trim()));
    }).toList();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
