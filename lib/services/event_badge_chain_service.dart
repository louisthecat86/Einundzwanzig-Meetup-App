// EVENT-BADGE — PRUEFKETTE BEIM SCANNEN
// ============================================
// Ein Event-Badge ist nicht von einem eingetragenen Organisator signiert,
// sondern von einem HELFER. Die Admin-Registry kennt ihn nicht, und ohne
// diese Kette meldete die App deshalb "unbekannter Signierer" — obwohl
// alles korrekt ist.
//
// Vertrauen wird hier weitergereicht statt aufgezaehlt:
//
//   Badge  --(m-Feld: Event-Adresse)-->  Kalender-Event
//   Kalender-Event  --(Signatur)-->      Ersteller
//   Ersteller  --(Admin-Registry)-->     berechtigt, Badges zu stiften
//   Kalender-Event  --(p/issuer)-->      Helfer darf ausstellen
//
// Jedes Glied ist kryptographisch oder ueber eine signierte Liste gedeckt.
// Faellt eines aus, gilt das Badge als ungedeckt — nicht als gefaelscht:
// Es kann auch schlicht sein, dass gerade kein Relay erreichbar ist.
// ============================================

import 'admin_registry.dart';
import 'app_logger.dart';
import 'calendar_event_service.dart';

const String _tag = 'EventChain';

/// Ergebnis der Kettenpruefung.
enum EventChainStatus {
  /// Kette vollstaendig: Ersteller berechtigt, Signierer eingetragen.
  verified,

  /// Event gefunden, aber der Signierer steht nicht in der Ausstellerliste.
  signerNotListed,

  /// Event gefunden, aber der Ersteller ist kein eingetragener Organisator.
  creatorNotAuthorized,

  /// Event traegt gar kein Badge — jemand hat die Adresse angehaengt,
  /// ohne dass es dafuer ein Badge geben soll.
  eventHasNoBadge,

  /// Event nicht auffindbar. Kann Boeswilligkeit sein, kann aber auch
  /// heissen: kein Netz, Relay langsam, Event geloescht.
  eventNotFound,
}

class EventChainResult {
  final EventChainStatus status;

  /// Titel des Events — fuer die Anzeige beim Scannen.
  final String eventTitle;

  /// Wer das Event angelegt hat (Hex).
  final String creatorPubkey;

  /// Name des Erstellers aus der Admin-Registry, sofern bekannt.
  final String? creatorName;

  /// Bild des Event-Badges. Kommt aus dem Kalender-Event und wird beim
  /// Scannen ins Badge uebernommen — sonst haette der Sammler ein Badge
  /// ohne das Bild, das der Veranstalter extra hochgeladen hat.
  final String badgeImageUrl;

  const EventChainResult({
    required this.status,
    this.eventTitle = '',
    this.creatorPubkey = '',
    this.creatorName,
    this.badgeImageUrl = '',
  });

  bool get ok => status == EventChainStatus.verified;
}

class EventBadgeChainService {
  EventBadgeChainService._();

  /// Prueft, ob [signerPubkey] fuer das Event unter [eventAddress] Badges
  /// ausstellen darf.
  ///
  /// [issuedAt] ist der SIGNIERTE Ausstellungszeitpunkt des Badges. Mit ihm
  /// zaehlen auch ehemalige Helfer — fuer Badges aus der Zeit, in der sie
  /// es noch waren. Ohne ihn waere jedes Badge eines inzwischen entfernten
  /// Helfers ungueltig, auch wenn es ordentlich vor Ort ausgegeben wurde.
  static Future<EventChainResult> verify({
    required String eventAddress,
    required String signerPubkey,
    int? issuedAt,
  }) async {
    final event = await CalendarEventService.fetchByAddress(eventAddress);
    if (event == null) {
      AppLogger.warn(_tag, 'Event $eventAddress nicht auffindbar.');
      return const EventChainResult(status: EventChainStatus.eventNotFound);
    }

    if (!event.badgeEnabled) {
      AppLogger.warn(_tag, 'Event "${event.title}" vergibt gar keine Badges.');
      return EventChainResult(
        status: EventChainStatus.eventHasNoBadge,
        eventTitle: event.title,
        creatorPubkey: event.pubkey,
        badgeImageUrl: event.badgeImageUrl,
      );
    }

    // Reihenfolge mit Bedacht: Erst die Ausstellerliste, dann der Ersteller.
    // Die Liste steht schon im geladenen Event, die Registry kostet
    // moeglicherweise einen weiteren Abruf.
    if (!event.isIssuer(signerPubkey, atEpoch: issuedAt)) {
      AppLogger.warn(_tag,
          'Signierer ${signerPubkey.substring(0, 8)}… steht nicht in der Ausstellerliste von "${event.title}".');
      return EventChainResult(
        status: EventChainStatus.signerNotListed,
        eventTitle: event.title,
        creatorPubkey: event.pubkey,
        badgeImageUrl: event.badgeImageUrl,
      );
    }

    // Wer das Event angelegt hat, muss berechtigt gewesen sein — sonst
    // koennte sich jeder ein Event mit sich selbst als Aussteller bauen und
    // Badges aus dem Nichts erzeugen.
    //
    // Geprueft wird ausschliesslich die Admin-Registry. Die Portal-Leader
    // aus F4c lassen sich hier NICHT pruefen: Diese Liste beantwortet nur
    // "bin ICH Leader", nicht "ist diese fremde Person Leader". Wer ein
    // Event mit Badge anlegt, sollte deshalb in der Admin-Registry stehen.
    try {
      final admin = await AdminRegistry.checkAdminByPubkey(event.pubkey);
      if (!admin.isAdmin) {
        AppLogger.warn(_tag,
            'Ersteller ${event.pubkey.substring(0, 8)}… ist kein eingetragener Organisator.');
        return EventChainResult(
          status: EventChainStatus.creatorNotAuthorized,
          eventTitle: event.title,
          creatorPubkey: event.pubkey,
          badgeImageUrl: event.badgeImageUrl,
        );
      }

      AppLogger.debug(_tag,
          'Kette vollstaendig fuer "${event.title}" (Ersteller ${admin.name ?? admin.meetup ?? "?"}).');
      return EventChainResult(
        status: EventChainStatus.verified,
        eventTitle: event.title,
        creatorPubkey: event.pubkey,
        creatorName: admin.name ?? admin.meetup,
        badgeImageUrl: event.badgeImageUrl,
      );
    } catch (e) {
      // Registry nicht erreichbar: Das Badge ist nicht falsch, nur
      // ungeprueft. Es als ungedeckt zu melden ist ehrlicher, als es
      // durchzuwinken.
      AppLogger.warn(_tag, 'Admin-Registry nicht abfragbar', e);
      return EventChainResult(
        status: EventChainStatus.creatorNotAuthorized,
        eventTitle: event.title,
        creatorPubkey: event.pubkey,
        badgeImageUrl: event.badgeImageUrl,
      );
    }
  }
}
