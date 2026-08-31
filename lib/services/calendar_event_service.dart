// VERANSTALTUNGSKALENDER — NIP-52 Calendar Events
// ============================================
// Liest und publiziert Kalender-Events über Nostr (NIP-52):
//   - kind 31923: zeitbasiertes Event (mit Start/Ende als Unix-Zeit)
//   - kind 31922: datumsbasiertes Event (ganztägig, nur Datum)
// Damit eingetragene Events (z.B. BTC Prag, Zitadelle) für ALLE sichtbar
// werden, die denselben Relays folgen.
//
// Quelle/Ziel: dieselben Relays wie der Rest der App. Signiert über den
// bestehenden SigningService (lokaler nsec ODER Amber, transparent).
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'relay_config.dart';
import 'signing_service.dart';
import 'app_logger.dart';
import 'relay_socket.dart';

const String _tag = 'Calendar';
const int kTimeEventKind = 31923; // zeitbasiert
const int kDateEventKind = 31922; // datumsbasiert (ganztägig)

/// Ein Kalender-Event (aus einem NIP-52-Event).
class NostrCalendarEvent {
  final String id;
  final String pubkey;
  final String dTag;
  final String title;
  final String description;
  final String location;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final int kind;
  final bool fromApp; // true, wenn via dieser App erstellt (client-Tag)

  /// Status nach NIP-52: leer, `planned` oder `cancelled`.
  ///
  /// Abgesagte Termine bleiben im Netz stehen — Nostr kennt kein Loeschen,
  /// nur Ersetzen. Sie tragen dieses Merkmal und werden nicht mehr
  /// angezeigt.
  final String status;

  bool get isCancelled => status == 'cancelled';

  // =============================================
  // EVENT-BADGE (Zusatz-Tags, NIP-52 erlaubt beliebige weitere Tags —
  // fremde Clients ignorieren sie einfach)
  // =============================================

  /// Soll es fuer dieses Event ein Badge geben? Tag ['badge','true'].
  final bool badgeEnabled;

  /// Bild fuers Badge. Tag `['badge_image','<url>']`.
  final String badgeImageUrl;

  /// Koordinaten des Veranstaltungsorts. Tag `['g','<lat>','<lng>']`.
  /// 0/0 bedeutet "nicht hinterlegt" — dann kann die Ortspruefung beim
  /// Sessionstart nicht greifen.
  final double lat;
  final double lng;

  /// Wer darf fuer dieses Event Badges ausstellen? Je ein Tag
  /// `['p','<pubkey-hex>','','issuer']`. Hex, nicht npub — so verlangt es
  /// NIP-01 fuer p-Tags, und andere Clients zeigen die Leute dann als
  /// Beteiligte an.
  final List<String> issuers;

  /// Darf [pubkeyHex] fuer dieses Event Badges ausstellen?
  ///
  /// Der Ersteller selbst zaehlt immer dazu — er hat das Event signiert und
  /// muss sich nicht zusaetzlich selbst eintragen.
  bool isIssuer(String pubkeyHex) {
    if (pubkeyHex.isEmpty) return false;
    final k = pubkeyHex.toLowerCase();
    return k == pubkey.toLowerCase() ||
        issuers.any((i) => i.toLowerCase() == k);
  }

  /// Laeuft das Zeitfenster gerade? Badges gibt es nur am Termintag —
  /// sonst waere ein einmal angelegtes Event ein Badge-Automat auf Dauer.
  bool get isBadgeWindowOpen {
    if (!badgeEnabled) return false;
    final now = DateTime.now();
    final from = DateTime(start.year, start.month, start.day);
    final until = (end ?? start).add(const Duration(days: 1));
    final to = DateTime(until.year, until.month, until.day);
    return !now.isBefore(from) && now.isBefore(to);
  }

  /// Adresse des Events fuer Verweise aus Badges: `<kind>:<pubkey>:<d>`.
  String get address => '$kind:$pubkey:$dTag';

  NostrCalendarEvent({
    required this.id,
    required this.pubkey,
    required this.dTag,
    required this.title,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.allDay,
    required this.kind,
    this.fromApp = false,
    this.status = '',
    this.badgeEnabled = false,
    this.badgeImageUrl = '',
    this.lat = 0,
    this.lng = 0,
    this.issuers = const [],
  });

  /// Tag (ohne Uhrzeit) für die Kalender-Gruppierung.
  DateTime get day => DateTime(start.year, start.month, start.day);

  static NostrCalendarEvent? fromEvent(Map<String, dynamic> e) {
    try {
      final kind = e['kind'] as int? ?? 0;
      if (kind != kTimeEventKind && kind != kDateEventKind) return null;
      final allDay = kind == kDateEventKind;

      final tags = (e['tags'] as List<dynamic>?)
              ?.map((t) => (t as List<dynamic>).map((x) => x.toString()).toList())
              .toList() ??
          [];
      String tagVal(String key) {
        final t = tags.firstWhere((t) => t.isNotEmpty && t[0] == key, orElse: () => const []);
        return t.length >= 2 ? t[1] : '';
      }

      final title = tagVal('title').isNotEmpty ? tagVal('title') : tagVal('name');
      final startRaw = tagVal('start');
      if (title.isEmpty || startRaw.isEmpty) return null;

      DateTime? start, end;
      if (allDay) {
        // start ist ein ISO-Datum (YYYY-MM-DD)
        start = DateTime.tryParse(startRaw);
        final endRaw = tagVal('end');
        if (endRaw.isNotEmpty) end = DateTime.tryParse(endRaw);
      } else {
        // start ist Unix-Sekunden
        final s = int.tryParse(startRaw);
        if (s != null) start = DateTime.fromMillisecondsSinceEpoch(s * 1000);
        final endRaw = tagVal('end');
        final en = int.tryParse(endRaw);
        if (en != null) end = DateTime.fromMillisecondsSinceEpoch(en * 1000);
      }
      if (start == null) return null;

      final client = tagVal('client');
      final fromApp = client == 'einundzwanzig-meetup-app';

      // --- Event-Badge-Tags ---
      final badgeEnabled = tagVal('badge').toLowerCase() == 'true';
      final badgeImageUrl = tagVal('badge_image');

      double lat = 0, lng = 0;
      final geo = tags.firstWhere((x) => x.isNotEmpty && x[0] == 'g',
          orElse: () => const []);
      if (geo.length >= 3) {
        lat = double.tryParse(geo[1]) ?? 0;
        lng = double.tryParse(geo[2]) ?? 0;
      }

      // Nur p-Tags mit der Rolle "issuer" — ein blosses p-Tag heisst bei
      // NIP-52 lediglich "beteiligt" und darf keine Badge-Berechtigung sein.
      final issuers = tags
          .where((x) => x.length >= 4 && x[0] == 'p' && x[3] == 'issuer')
          .map((x) => x[1])
          .where((x) => x.length == 64)
          .toList();

      return NostrCalendarEvent(
        id: (e['id'] ?? '').toString(),
        pubkey: (e['pubkey'] ?? '').toString(),
        dTag: tagVal('d'),
        title: title,
        description: (e['content'] ?? '').toString(),
        location: tagVal('location'),
        start: start,
        end: end,
        allDay: allDay,
        kind: kind,
        fromApp: fromApp,
        status: tagVal('status'),
        badgeEnabled: badgeEnabled,
        badgeImageUrl: badgeImageUrl,
        lat: lat,
        lng: lng,
        issuers: issuers,
      );
    } catch (_) {
      return null;
    }
  }
}

class CalendarEventService {
  static const Duration _timeout = Duration(seconds: 8);

  /// Das Community-Relay für App-Events. Im Community-Modus werden nur
  /// Events von diesem Relay geladen (überschaubar). Im Weltweit-Modus
  /// werden alle aktiven Relays abgefragt.
  static const String kCommunityRelay = 'wss://nostr.einundzwanzig.space';

  /// Lädt Kalender-Events (NIP-52).
  /// [worldwide]=false (Standard): nur das Community-Relay, und nur Events,
  ///   die über diese App erstellt wurden (client-Tag) -> überschaubar.
  /// [worldwide]=true: alle aktiven Relays, alle Events (die ganze Nostr-Welt).
  /// Dedupliziert (pubkey:dTag -> neueste Version) und nach Startdatum sortiert.
  static Future<List<NostrCalendarEvent>> fetchEvents({int limit = 200, bool worldwide = false}) async {
    final List<String> relays;
    if (worldwide) {
      relays = await RelayConfig.getActiveRelays();
    } else {
      relays = [kCommunityRelay];
    }

    final byKey = <String, NostrCalendarEvent>{};
    for (final relayUrl in relays) {
      final list = await _fetchFromRelay(relayUrl, limit);
      if (list == null) continue;
      for (final ev in list) {
        // Community-Modus: nur Events, die über die App erstellt wurden.
        if (!worldwide && !ev.fromApp) continue;
        final key = '${ev.pubkey}:${ev.dTag}:${ev.kind}';
        byKey[key] = ev;
      }
    }

    final all = byKey.values.toList()..sort((a, b) => a.start.compareTo(b.start));
    return all;
  }

  /// Holt EIN Kalender-Event ueber seine Adresse `<kind>:<pubkey>:<dTag>`.
  ///
  /// Gebraucht beim Scannen eines Event-Badges: Der Payload nennt nur die
  /// Adresse; wer ausstellen darf und wer das Event angelegt hat, steht im
  /// Event selbst. Ohne diesen Abruf waere die Ausstellerliste nicht
  /// pruefbar.
  ///
  /// Sucht auf ALLEN aktiven Relays, nicht nur auf dem Community-Relay: Ein
  /// Event kann von woanders stammen, und ein Badge abzulehnen, weil man am
  /// falschen Ort gesucht hat, waere das schlechteste Ergebnis.
  static Future<NostrCalendarEvent?> fetchByAddress(String address) async {
    final parts = address.split(':');
    if (parts.length < 3) return null;
    final kind = int.tryParse(parts[0]);
    final author = parts[1];
    final dTag = parts.sublist(2).join(':');
    if (kind == null || author.length != 64 || dTag.isEmpty) return null;

    final relays = <String>{
      kCommunityRelay,
      ...await RelayConfig.getActiveRelays(),
    };

    NostrCalendarEvent? newest;
    for (final relayUrl in relays) {
      RelaySocket? ws;
      try {
        ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
        final completer = Completer<void>();
        final random = Random.secure();
        final subId = 'cal1-${List.generate(6, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

        ws.listen((data) {
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg.length >= 3 && msg[0] == 'EVENT') {
              final ev = NostrCalendarEvent.fromEvent(msg[2] as Map<String, dynamic>);
              // Ersetzbare Events: Die neueste Fassung gewinnt.
              if (ev != null && !ev.isCancelled &&
                  (newest == null || ev.start.isAfter(newest!.start))) {
                newest = ev;
              }
            } else if (msg.isNotEmpty && msg[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete();
            }
          } catch (_) {}
        }, onError: (_) {
          if (!completer.isCompleted) completer.complete();
        }, onDone: () {
          if (!completer.isCompleted) completer.complete();
        });

        ws.add(jsonEncode([
          'REQ',
          subId,
          {
            'kinds': [kind],
            'authors': [author],
            '#d': [dTag],
            'limit': 1,
          }
        ]));
        await completer.future.timeout(_timeout, onTimeout: () {});
      } catch (e) {
        AppLogger.debug(_tag, 'fetchByAddress $relayUrl: $e');
      } finally {
        try {
          ws?.close();
        } catch (_) {}
      }
      // Gefunden reicht — weitere Relays wuerden dasselbe liefern.
      if (newest != null) break;
    }

    AppLogger.debug(_tag,
        'fetchByAddress $address -> ${newest == null ? "nicht gefunden" : "gefunden"}');
    return newest;
  }

  static Future<List<NostrCalendarEvent>?> _fetchFromRelay(String relayUrl, int limit) async {
    RelaySocket? ws;
    final tally = RelayParseTally('Calendar', 'Nostr-Kalender von $relayUrl');
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<List<NostrCalendarEvent>?>();
      final results = <NostrCalendarEvent>[];

      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId = 'cal-$subIdHex';

      ws.listen(
        (data) {
          tally.message();
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;
            if (type == 'EVENT' && message.length >= 3) {
              final ev = NostrCalendarEvent.fromEvent(message[2] as Map<String, dynamic>);
              // Abgesagte Termine gar nicht erst aufnehmen. Sie bleiben im
              // Netz stehen — Nostr kennt kein Loeschen —, gehoeren aber in
              // keinen Kalender.
              if (ev != null && !ev.isCancelled) results.add(ev);
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(results);
            }
          } catch (e) { tally.failed(e); }
        },
        onError: (_) { if (!completer.isCompleted) completer.complete(results); },
        onDone: () { if (!completer.isCompleted) completer.complete(results); },
      );

      ws.add(jsonEncode(['REQ', subId, {'kinds': [kTimeEventKind, kDateEventKind], 'limit': limit}]));
      final res = await completer.future.timeout(_timeout, onTimeout: () => results);
      return res;
    } catch (e) {
      AppLogger.debug(_tag, '$relayUrl Lesefehler: $e');
      return null;
    } finally {
      tally.report();
      try { ws?.close(); } catch (_) {}
    }
  }

  /// Publiziert ein zeitbasiertes Kalender-Event (kind 31923).
  /// Gibt die Anzahl Relays zurück, die akzeptiert haben (0 = Fehler).
  static Future<int> publishEvent({
    required String title,
    required String description,
    required String location,
    required DateTime start,
    DateTime? end,
    bool allDay = false,
    // --- Event-Badge (optional) ---
    bool badgeEnabled = false,
    String badgeImageUrl = '',
    double lat = 0,
    double lng = 0,
    List<String> issuers = const [],
  }) async {
    try {
      final random = Random.secure();
      final dTag = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

      // Die Badge-Tags sind fuer beide Event-Arten gleich. Sie stehen hier
      // einmal, damit sie nicht in zwei Zweigen auseinanderlaufen koennen.
      final badgeTags = <List<String>>[
        if (badgeEnabled) ['badge', 'true'],
        if (badgeEnabled && badgeImageUrl.trim().isNotEmpty)
          ['badge_image', badgeImageUrl.trim()],
        if (badgeEnabled && (lat != 0 || lng != 0))
          ['g', lat.toStringAsFixed(6), lng.toStringAsFixed(6)],
        if (badgeEnabled)
          for (final hex in issuers)
            if (hex.length == 64) ['p', hex, '', 'issuer'],
      ];

      final List<List<String>> tags;
      final int kind;
      if (allDay) {
        kind = kDateEventKind;
        String ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        tags = [
          ['d', dTag],
          ['title', title],
          ['start', ymd(start)],
          if (end != null) ['end', ymd(end)],
          if (location.trim().isNotEmpty) ['location', location.trim()],
          ['client', 'einundzwanzig-meetup-app'],
          ...badgeTags,
        ];
      } else {
        kind = kTimeEventKind;
        final startUnix = (start.toUtc().millisecondsSinceEpoch ~/ 1000).toString();
        tags = [
          ['d', dTag],
          ['title', title],
          ['start', startUnix],
          if (end != null) ['end', (end.toUtc().millisecondsSinceEpoch ~/ 1000).toString()],
          if (location.trim().isNotEmpty) ['location', location.trim()],
          ['client', 'einundzwanzig-meetup-app'],
          ...badgeTags,
        ];
      }

      final signed = await SigningService.signEvent(kind: kind, tags: tags, content: description.trim());
      return await _publish(signed);
    } catch (e) {
      AppLogger.debug(_tag, 'Event-Publish fehlgeschlagen: $e');
      return 0;
    }
  }

  /// Sagt einen Termin ab.
  ///
  /// ============================================
  /// WARUM "ABSAGEN" UND NICHT "LOESCHEN"
  /// ============================================
  ///
  /// Nostr kennt kein Loeschen. Ein Ereignis, das einmal auf Relays liegt,
  /// laesst sich nicht zurueckholen — man kann nur BITTEN, es zu entfernen
  /// (NIP-09, kind 5), und jedes Relay entscheidet selbst, ob es der Bitte
  /// folgt. Manche tun es, manche nicht, Archive praktisch nie.
  ///
  /// Deshalb zwei Wege gleichzeitig:
  ///
  ///   1. Der Termin wird ERSETZT — gleiche Kennung, gleiche Art, aber mit
  ///      `["status","cancelled"]`. Das ist der verlaessliche Teil: Ersetzbare
  ///      Ereignisse werden von jedem Relay ueberschrieben, und jeder Client,
  ///      der NIP-52 kennt, sieht die Absage.
  ///
  ///   2. Zusaetzlich geht eine Loeschbitte raus. Wo sie befolgt wird,
  ///      verschwindet der Termin ganz.
  ///
  /// Ein reines kind 5 waere zu wenig gewesen: Bei einem Relay, das es
  /// ignoriert, staende der Termin unveraendert weiter da — und der
  /// Veranstalter waere in dem Glauben, abgesagt zu haben.
  ///
  /// Nur der Ersteller kann absagen: Ein ersetzbares Ereignis gehoert zu
  /// seinem Schluessel, eine fremde Ersetzung entstuende gar nicht erst.
  static Future<bool> cancelEvent(NostrCalendarEvent event) async {
    try {
      final me = await SigningService.pubkeyHex();
      if (me == null || me != event.pubkey) {
        AppLogger.warn(_tag, 'Absage abgelehnt: nicht der Ersteller.');
        return false;
      }

      // --- 1. Ersetzen, mit Status "cancelled" ---
      final tags = <List<String>>[
        ['d', event.dTag],
        ['title', event.title],
        ['start', event.allDay
            ? _ymd(event.start)
            : (event.start.millisecondsSinceEpoch ~/ 1000).toString()],
        ['status', 'cancelled'],
        ['client', 'einundzwanzig-meetup-app'],
      ];
      final replaced = await SigningService.signEvent(
        kind: event.kind,
        tags: tags,
        content: event.description,
      );
      final n = await _publish(replaced);

      // --- 2. Loeschbitte hinterher ---
      try {
        final del = await SigningService.signEvent(
          kind: 5,
          tags: [
            ['e', event.id],
            ['a', event.address],
            ['k', event.kind.toString()],
          ],
          content: 'Termin abgesagt',
        );
        await _publish(del);
      } catch (e) {
        // Die Bitte ist die Kuer. Schlaegt sie fehl, steht der Termin
        // trotzdem als abgesagt da.
        AppLogger.debug(_tag, 'Loeschbitte fehlgeschlagen: $e');
      }

      AppLogger.info(_tag,
          'Termin "${event.title}" abgesagt — $n Relay(s) haben die Ersetzung angenommen.');
      return n > 0;
    } catch (e) {
      AppLogger.warn(_tag, 'Absage fehlgeschlagen', e);
      return false;
    }
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<int> _publish(SignedEvent event) async {
    final active = await RelayConfig.getActiveRelays();
    // Community-Relay IMMER einschließen, damit App-Events dort landen und
    // im Community-Modus auffindbar sind (auch wenn der Nutzer es abgewählt hat).
    final relays = <String>{...active, kCommunityRelay}.toList();
    if (relays.isEmpty) return 0;

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

    int ok = 0;
    for (final relayUrl in relays) {
      try {
        final ws = await RelaySocket.connect(relayUrl).timeout(RelayConfig.publishTimeout);
        ws.add(eventJson);
        await Future.delayed(const Duration(seconds: 2));
        ws.close();
        ok++;
      } catch (e) {
        AppLogger.debug(_tag, '$relayUrl Publish fehlgeschlagen: $e');
      }
    }
    return ok;
  }
}
