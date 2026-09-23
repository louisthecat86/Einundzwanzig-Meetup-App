// EVENT-BADGE-SESSION
// ============================================
// Der Weg, auf dem ein HELFER Badges ausgibt — ohne Organisator-Rolle und
// ohne Zugang zum Organisator-Bereich. Seine Berechtigung steht im
// Kalender-Event, nicht in der Admin-Registry.
//
// Vor dem Start werden drei Dinge geprueft, jedes aus einem eigenen Grund:
//
//   1. Bin ich eingetragen?  — sonst koennte jeder fuer jedes Event Badges
//      ausgeben, und der Ersteller haette keine Kontrolle darueber.
//   2. Ist heute der Tag?    — ohne Zeitfenster waere ein einmal angelegtes
//      Event ein Badge-Automat auf Dauer.
//   3. Bin ich vor Ort?      — sonst haette ein eingetragener Helfer in
//      Muenchen Badges fuer ein Frankfurter Event verteilen koennen.
//
// Der QR selbst wird lokal erzeugt und mit dem EIGENEN Schluessel des
// Helfers signiert. Es gibt nichts zu uebergeben und nichts geheim zu
// halten — die Ausstellerliste im Event macht seine Signatur gueltig.
// ============================================

import 'dart:async';

import 'app_logger.dart';
import 'coattendance_service.dart';
import 'badge_security.dart';
import 'calendar_event_service.dart';
import 'meetup_location_service.dart';
import 'nearby_meetup_service.dart';
import 'rolling_qr_service.dart';
import 'signing_service.dart';

const String _tag = 'EventSession';

/// Warum eine Session nicht starten darf.
enum EventSessionError {
  noIdentity,
  notIssuer,
  outsideWindow,
  noEventLocation,
  locationUnavailable,

  /// Ortungsdienst des Geraets ist aus.
  locationServiceOff,

  /// Berechtigung verweigert — ein erneutes Nachfragen ist moeglich.
  locationDenied,

  /// Berechtigung dauerhaft verweigert — nur ueber die App-Einstellungen
  /// zu aendern.
  locationDeniedForever,

  /// Alles an, aber kein Fix. Typisch drinnen, und besonders auf Geraeten
  /// ohne Google-Dienste (GrapheneOS, LineageOS), denen die WLAN-Ortung
  /// fehlt und die allein auf GPS angewiesen sind.
  locationNoFix,
  tooFarAway,
  sessionFailed,
}

class EventSessionResult {
  final MeetupSession? session;
  final EventSessionError? error;

  /// Entfernung zum Veranstaltungsort in km — nur bei [tooFarAway] gesetzt,
  /// damit die Meldung sagen kann, WIE weit es war.
  final double? distanceKm;

  const EventSessionResult.success(this.session)
      : error = null,
        distanceKm = null;
  const EventSessionResult.failure(this.error, {this.distanceKm})
      : session = null;

  bool get ok => session != null;
}

class EventBadgeSessionService {
  EventBadgeSessionService._();

  /// Wie nah der Aussteller am Veranstaltungsort sein muss.
  ///
  /// 5 km — anders als bei Meetups, wo 50 km gelten. Dort stammen die
  /// Koordinaten aus der Portal-Liste und zeigen bei Regionen wie
  /// "Westerwald" auf einen groben Mittelpunkt. Hier hat der Ersteller den
  /// Punkt selbst auf der Karte gesetzt, der darf also genau sein.
  static const double issuerRadiusKm = 5.0;

  /// Ende des Veranstaltungstags als Unix-Sekunden.
  ///
  /// Geht ein Event ueber mehrere Tage, zaehlt der letzte. Mitternacht ist
  /// bewusst der Schnitt und nicht "Eventende plus Puffer": Das Badge wird
  /// nach Datum zusammengefasst, ein Scan um 23:50 gehoert noch dazu, einer
  /// um 00:10 waere schon ein anderer Tag.
  static int _endOfEventDay(NostrCalendarEvent event) {
    final last = event.end ?? event.start;
    final midnight = DateTime(last.year, last.month, last.day)
        .add(const Duration(days: 1));
    return midnight.millisecondsSinceEpoch ~/ 1000;
  }

  /// Prueft alles und legt die Session an.
  static Future<EventSessionResult> start(NostrCalendarEvent event) async {
    final myPubkey = await SigningService.pubkeyHex();
    if (myPubkey == null || myPubkey.isEmpty) {
      return const EventSessionResult.failure(EventSessionError.noIdentity);
    }

    if (!event.isIssuer(myPubkey)) {
      AppLogger.warn(_tag, 'Nicht als Aussteller eingetragen.');
      return const EventSessionResult.failure(EventSessionError.notIssuer);
    }

    if (!event.isBadgeWindowOpen) {
      AppLogger.debug(_tag, 'Ausserhalb des Zeitfensters (${event.start}).');
      return const EventSessionResult.failure(EventSessionError.outsideWindow);
    }

    if (event.lat == 0 && event.lng == 0) {
      return const EventSessionResult.failure(
          EventSessionError.noEventLocation);
    }

    // Direkt die Ortung — NICHT resolveLocation().
    //
    // resolveLocation laedt nach der Ortung zusaetzlich die komplette
    // Meetup-Liste, um Kandidaten in der Naehe zu finden. Fuer ein Event ist
    // das ueberfluessig; es verlaengerte nur die Wartezeit. Und es gab den
    // genauen Grund eines Fehlschlags nicht weiter — aus "kein GPS-Fix
    // drinnen" wurde derselbe Rat wie bei "Ortungsdienst aus".
    final loc = await NearbyMeetupService.getCurrentLocation();
    if (loc.status != LocationStatus.ok || loc.position == null) {
      final err = switch (loc.status) {
        LocationStatus.serviceDisabled => EventSessionError.locationServiceOff,
        LocationStatus.denied => EventSessionError.locationDenied,
        LocationStatus.deniedForever => EventSessionError.locationDeniedForever,
        LocationStatus.noFix => EventSessionError.locationNoFix,
        _ => EventSessionError.locationUnavailable,
      };
      AppLogger.warn(_tag, 'Standort nicht verfuegbar: ${loc.status.name}');
      return EventSessionResult.failure(err);
    }
    final pos = loc.position!;

    final distance = MeetupLocationService.distanceKm(
        pos.latitude, pos.longitude, event.lat, event.lng);
    if (distance > issuerRadiusKm) {
      AppLogger.warn(_tag,
          'Zu weit weg: ${distance.toStringAsFixed(1)} km (erlaubt $issuerRadiusKm).');
      return EventSessionResult.failure(EventSessionError.tooFarAway,
          distanceKm: distance);
    }

    try {
      final session = await RollingQRService.getOrCreateSession(
        // Die Event-Adresse steckt im meetupId und wandert damit in den
        // signierten Payload — daran haengt spaeter die Pruefkette.
        meetupId: BadgeSecurity.eventMeetupId(
          eventAddress: event.address,
          title: event.title,
        ),
        meetupName: event.title,
        meetupCountry: '',
        blockHeight: 0,
        // Der EVENT-Ort, nicht der gemessene: Teilnehmer sollen am
        // Veranstaltungsort gemessen werden, nicht an dem Punkt, an dem der
        // Helfer zufaellig stand, als er die Session startete.
        lat: event.lat,
        lng: event.lng,
        // Bis zum Ende des Veranstaltungstags statt der ueblichen vier
        // Stunden. Ein Event dauert laenger als ein Meetup, mehrere Helfer
        // starten zu verschiedenen Zeiten, und das Badge traegt ohnehin nur
        // das Datum — es ist also gleichgueltig, wann am Tag jemand scannt.
        validUntilEpoch: _endOfEventDay(event),
      );
      if (session == null) {
        return const EventSessionResult.failure(
            EventSessionError.sessionFailed);
      }
      // Der Helfer war selbst da. Ohne diesen Eintrag saesse er ausserhalb
      // des Event-Graphen, waehrend alle, die bei ihm gescannt haben, darin
      // sind — er waere von seinen eigenen Teilnehmern getrennt.
      //
      // Der Aufruf laeuft im Hintergrund: Er kostet einen Relay-Versand, und
      // der QR soll nicht darauf warten.
      unawaited(CoAttendanceService.recordOrganizerAttendance(
        meetupName: event.title,
        date: DateTime.now(),
        blockHeight: session.blockHeight,
        lat: event.lat,
        lng: event.lng,
        isEvent: true,
      ));

      AppLogger.debug(_tag,
          'Session fuer "${event.title}" gestartet, ${distance.toStringAsFixed(2)} km entfernt.');
      return EventSessionResult.success(session);
    } catch (e) {
      AppLogger.warn(_tag, 'Session konnte nicht erstellt werden', e);
      return const EventSessionResult.failure(EventSessionError.sessionFailed);
    }
  }
}
