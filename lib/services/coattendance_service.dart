import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import '../models/badge.dart';
import 'signing_service.dart';
import 'relay_config.dart';
import 'nostr_service.dart';
import 'mempool.dart';
import 'app_logger.dart';
import 'relay_socket.dart';

/// Eine bestätigte Meetup-Teilnahme einer Person (von Relays geladen).
class CoAttendanceRecord {
  final String npub;          // Teilnehmer
  final String meetupEventId; // Welches Meetup-Event
  final int attendedAt;       // Unix-Sekunden (Event-Zeitpunkt)

  CoAttendanceRecord({
    required this.npub,
    required this.meetupEventId,
    required this.attendedAt,
  });
}

/// Ein Knoten im Co-Attendance-Netzwerk.
class CoAttNode {
  final String npub;

  /// Meetup-Begegnungen. Der Kern des Vertrauensnetzwerks: kleine Runden,
  /// in denen man sich tatsaechlich getroffen hat.
  final Set<String> meetups;

  /// Event-Begegnungen — getrennt gefuehrt.
  ///
  /// Auf einem Meetup mit fuenfzehn Leuten trifft man jeden. Auf einem
  /// Event mit fuenfhundert nicht. Wuerden beide im selben Topf liegen,
  /// machte ein einziges Grossevent Tausende Menschen zu "direkten
  /// Begegnungen" und die Aussage des Netzwerks waere dahin.
  final Set<String> events;

  CoAttNode(this.npub)
      : meetups = <String>{},
        events = <String>{};

  /// Alles zusammen — fuer Ansichten, die beides zeigen wollen.
  Set<String> get all => {...meetups, ...events};
}

/// Ergebnis der Netzwerk-Analyse zwischen mir und einer Zielperson.
class CoAttNetwork {
  final String myNpub;
  final String targetNpub;
  final Set<String> sharedMeetups;          // gemeinsame Meetups (ich + Ziel)
  final List<String> mutualContacts;        // npubs, die sowohl mit mir als auch mit Ziel auf Meetups waren
  final Map<String, CoAttNode> nodes;       // alle bekannten Knoten
  final int targetTotalMeetups;             // wie viele Meetups die Zielperson besucht hat
  final int targetTotalContacts;            // mit wie vielen verschiedenen Leuten

  CoAttNetwork({
    required this.myNpub,
    required this.targetNpub,
    required this.sharedMeetups,
    required this.mutualContacts,
    required this.nodes,
    required this.targetTotalMeetups,
    required this.targetTotalContacts,
  });

  bool get hasDirectOverlap => sharedMeetups.isNotEmpty;
  bool get hasAnyConnection => sharedMeetups.isNotEmpty || mutualContacts.isNotEmpty;
}

/// Verwaltet das opt-in Co-Attendance-Netzwerk über Nostr.
///
/// Prinzip:
///  - Beim Badge-Scan (nach Zustimmung) wird ein signiertes Co-Attendance-Event
///    veröffentlicht: "npub X bestätigt Teilnahme an meetupEventId Y".
///  - Das Event ist an ein ECHTES, organisator-signiertes Badge gekoppelt
///    (badge.isNostrSigned + sigId), daher nicht beliebig fälschbar.
///  - Andere können diese Events laden und das Netzwerk rekonstruieren.
class CoAttendanceService {
  static const int kind = 30079; // Parameterized Replaceable (neben 30078 Reputation)
  static const String _client = 'einundzwanzig-meetup-app';
  static const Duration _timeout = Duration(seconds: 8);
  static const String _tag = 'CoAttendance';

  /// Veröffentlicht EIN Co-Attendance-Event für ein Badge.
  /// Nur aufrufen, wenn der Nutzer aktiv zugestimmt hat (Opt-in)!
  /// Gibt Anzahl erreichter Relays zurück (0 = Fehlschlag).
  /// Der Schluessel, unter dem Anwesenheit veroeffentlicht wird.
  ///
  /// FRUEHER: nur `meetupEventId`, also "name-JJJJ-MM-TT". Der Name stammt
  /// vom Tag des Organisators — und generische Namen kollidieren weltweit.
  /// Im Feldtest verband das vier wildfremde Leute miteinander, weil alle
  /// am selben Tag eine Session namens "test" angelegt hatten. Auch echte
  /// Faelle sind betroffen: Berlin hat vier Gruppen im Portal, Osnabrueck
  /// und Budapest ebenso — treffen sich zwei davon am selben Abend, waren
  /// bisher alle Beteiligten "direkt bekannt".
  ///
  /// JETZT: zusaetzlich der Signierer. Alle Teilnehmer EINER Session haben
  /// denselben Organisator gescannt, teilen also denselben Wert — die
  /// Verknuepfung innerhalb der Session bleibt exakt erhalten. Zwei
  /// verschiedene Sessions koennen sich aber nicht mehr vermischen, selbst
  /// bei identischem Namen und Datum.
  ///
  /// Die Badge-Identitaet (`meetupEventId`) bleibt UNVERAENDERT — sonst
  /// waere der Duplikatschutz betroffen, und ein Teilnehmer koennte an
  /// einem Abend mehrere Badges sammeln.
  /// Praefix fuer Event-Anwesenheiten. Es steht VOR dem Schluessel, damit
  /// beim Einlesen ohne Zusatzwissen erkennbar ist, in welchen Topf ein
  /// Eintrag gehoert — die Relay-Daten tragen sonst keinen Typ.
  static const String eventPrefix = 'ev|';

  static bool isEventKey(String key) => key.startsWith(eventPrefix);

  /// Anwesenheitsschluessel.
  ///
  /// Bei MEETUPS haengt der Signierer mit dran. Grund: Zwei unabhaengige
  /// Sitzungen mit demselben Namen und Datum — jeder Entwickler legt
  /// irgendwann eine "test"-Session an — wuerden sonst Fremde miteinander
  /// verknuepfen. Das ist im Feld passiert und war der Anlass fuer diese
  /// Ergaenzung.
  ///
  /// Bei EVENTS faellt er weg, und zwar aus zwei Gruenden. Erstens ist die
  /// Gefahr nicht gegeben: In der Event-Adresse steckt der Pubkey des
  /// Erstellers, sie ist also von Natur aus eindeutig — ein zweites
  /// "Blocktrainer Event" von jemand anderem hat einen anderen Schluessel.
  /// Zweitens gehoert es zur Sache: Ein Event IST ein Event, egal bei
  /// welchem Helfer man gescannt hat. Ohne diese Zusammenfassung zerfiele
  /// eine Veranstaltung in so viele Gruppen, wie Helfer im Einsatz waren.
  /// Gemeinsame Kennungen zweier Teilnehmer.
  ///
  /// Nicht einfach `intersection`, weil ZWEI FORMATE nebeneinander im Netz
  /// liegen:
  ///
  ///   aschaffenburg-2026-06-03                 (alt, ohne Signierer)
  ///   aschaffenburg-2026-06-03@u8qf5q534jzc    (neu, mit Signierer)
  ///
  /// Der Anhang kam spaeter dazu, um zwei Organisatoren am selben Abend
  /// auseinanderzuhalten. Aeltere Badges tragen keinen Signierer, und ein
  /// exakter Vergleich laesst beide Formate aneinander vorbeilaufen — genau
  /// deshalb blieb das Netzwerk bei Bestaenden aus der Zeit davor leer.
  ///
  /// Regel: Gleich ist gleich. Fehlt EINER Seite der Anhang, entscheidet der
  /// Teil davor. Haben BEIDE einen Anhang, muss er uebereinstimmen — sonst
  /// waren es verschiedene Sessions, und die Unterscheidung bliebe wertlos.
  static Set<String> sharedKeys(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return <String>{};

    String base(String k) {
      final i = k.indexOf('@');
      return i < 0 ? k : k.substring(0, i);
    }

    final out = <String>{};
    for (final x in a) {
      final xb = base(x);
      final xHasSigner = x.length != xb.length;
      for (final y in b) {
        if (x == y) {
          out.add(x);
          continue;
        }
        final yb = base(y);
        if (xb != yb) continue;
        // Nur wenn mindestens eine Seite aus der Zeit ohne Anhang stammt.
        final yHasSigner = y.length != yb.length;
        if (!xHasSigner || !yHasSigner) out.add(xb);
      }
    }
    return out;
  }

  static String attendanceKey(
    String meetupEventId,
    String signerNpub, {
    bool isEvent = false,
  }) {
    if (isEvent) return '$eventPrefix$meetupEventId';

    final signer = signerNpub.trim();
    if (signer.isEmpty) return meetupEventId; // Altformat, besser als nichts
    final short = signer.length > 12 ? signer.substring(signer.length - 12) : signer;
    return '$meetupEventId@$short';
  }

  // ============================================
  // VEROEFFENTLICHUNGSSTATUS (Issue #57, Punkt 5)
  // ============================================
  //
  // Wer beim Scannen zustimmt, dass seine Teilnahme ins Netzwerk geht, soll
  // erfahren, ob das geklappt hat — und es wiederholen koennen.
  //
  // Vorher: Schlug die Veroeffentlichung fehl, zeigte die App NICHTS. Die
  // Erfolgsmeldung kam nur bei Erfolg, der Fehlschlag verschwand still, und
  // es gab keinen Weg, es spaeter nachzuholen. Die Teilnahme fehlte im
  // Netzwerk fuer immer.
  //
  // Gespeichert wird je Badge-Signatur die Zahl der Relays, die angenommen
  // haben. 0 heisst: zugestimmt, aber nicht angekommen. Nicht gespeichert =
  // nie zugestimmt — das bleibt eine freie Entscheidung und wird nicht als
  // Fehler gezaehlt.

  static const String _statusKey = 'coatt_publish_status';

  static Future<Map<String, int>> publishStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_statusKey);
      if (raw == null) return {};
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, v is int ? v : 0));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveStatus(String sigId, int relays) async {
    if (sigId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await publishStatus();
      current[sigId] = relays;
      await prefs.setString(_statusKey, jsonEncode(current));
    } catch (_) {}
  }

  /// Badges, deren Veroeffentlichung zugestimmt wurde, aber fehlschlug.
  static Future<List<MeetupBadge>> failedBadges(List<MeetupBadge> all) async {
    final status = await publishStatus();
    return all.where((b) => status[b.sigId] == 0).toList();
  }

  /// Versucht alle fehlgeschlagenen erneut. Gibt zurueck, wie viele jetzt
  /// angekommen sind.
  static Future<int> retryFailed(List<MeetupBadge> all) async {
    final failed = await failedBadges(all);
    var fixed = 0;
    for (final b in failed) {
      if (await publishAttendance(b) > 0) fixed++;
    }
    AppLogger.info(_tag,
        'Erneut veroeffentlicht: $fixed von ${failed.length} Teilnahmen.');
    return fixed;
  }

  static Future<int> publishAttendance(MeetupBadge badge) async {
    // Sicherheit: nur echte, organisator-signierte Badges qualifizieren
    if (!badge.isNostrSigned || _isDegenerateEventId(badge.meetupEventId)) {
      AppLogger.warn(_tag, 'Badge nicht qualifiziert (nicht Nostr-signiert)');
      return 0;
    }

    try {
      final key = attendanceKey(badge.meetupEventId, badge.signerNpub,
          isEvent: badge.isEvent);

      // Inhalt bewusst minimal (datenschutzbewusst)
      final content = jsonEncode({
        'event': key,
        'meetup': badge.meetupName,
        't': badge.date.millisecondsSinceEpoch ~/ 1000,
      });

      // d-Tag = Schluessel -> pro Session genau EIN ersetzbares Event je npub
      final signed = await SigningService.signEvent(
        kind: kind,
        tags: <List<String>>[
          ['d', key],
          ['e_ref', badge.sigId], // Referenz auf das Badge-Signatur-Event (Kopplung)
          ['client', _client],
        ],
        content: content,
      );

      final n = await _publish(signed);
      await _saveStatus(badge.sigId, n);
      return n;
    } catch (e) {
      AppLogger.warn(_tag, 'Publish-Fehler: $e');
      // Auch der Fehlschlag wird festgehalten — sonst taucht er in der
      // Liste der erneut zu sendenden gar nicht erst auf.
      await _saveStatus(badge.sigId, 0);
      return 0;
    }
  }

  static Future<int> _publish(SignedEvent event) async {
    final relays = await RelayConfig.getActiveRelays();
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

    // Alle Relays GLEICHZEITIG, und gezaehlt wird nur, was ein Relay mit
    // ["OK", <id>, true, …] bestaetigt hat.
    //
    // Vorher: senden, zwei Sekunden warten, schliessen, ok++. Ein Relay, das
    // das Ereignis ABGEWIESEN hatte — falsches Format, Rate-Limit,
    // Anmeldung verlangt —, zaehlte als Erfolg. Die App meldete
    // "veroeffentlicht", und die Teilnahme fehlte danach im Netzwerk ohne
    // jeden Hinweis (Issue #57, Punkt 3).
    final results = await Future.wait(relays.map((relayUrl) async {
      RelaySocket? ws;
      try {
        ws = await RelaySocket.connect(relayUrl)
            .timeout(RelayConfig.publishTimeout);
        final done = Completer<bool>();
        ws.listen((data) {
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg.length >= 3 && msg[0] == 'OK' && msg[1] == event.id) {
              final accepted = msg[2] == true;
              if (!accepted) {
                AppLogger.warn(_tag,
                    '$relayUrl hat abgelehnt: ${msg.length >= 4 ? msg[3] : "ohne Grund"}');
              }
              if (!done.isCompleted) done.complete(accepted);
            }
          } catch (_) {}
        }, onError: (_) {
          if (!done.isCompleted) done.complete(false);
        }, onDone: () {
          if (!done.isCompleted) done.complete(false);
        });
        ws.add(eventJson);
        // Keine Antwort binnen der Frist zaehlt als NICHT angenommen — eine
        // Stille ist keine Zusage.
        return await done.future
            .timeout(const Duration(seconds: 6), onTimeout: () {
          AppLogger.warn(_tag, '$relayUrl: keine Bestaetigung erhalten.');
          return false;
        });
      } catch (e) {
        AppLogger.warn(_tag, '$relayUrl fehlgeschlagen: $e');
        return false;
      } finally {
        try {
          ws?.close();
        } catch (_) {}
      }
    }));

    final ok = results.where((r) => r).length;
    AppLogger.diag(_tag,
        'Teilnahme ${event.id.substring(0, 8)}…: $ok von ${relays.length} Relays haben angenommen.');
    return ok;
  }

  /// Lädt ALLE Co-Attendance-Events von den Relays und baut Knoten auf.
  /// Erkennt Kennungen, die kein echtes Meetup bezeichnen.
  ///
  /// Notwendig fuer BESTEHENDE Daten: Vor dem Fix konnte ein Tag ohne
  /// Meetup-Namen die Kennung "-2026-02-25" erzeugen — nicht leer, aber
  /// weltweit identisch fuer alle, die an dem Tag scannten. Wer solche
  /// Datensaetze veroeffentlicht hat, wuerde sonst dauerhaft mit Fremden
  /// verknuepft. Sie liegen auf den Relays und lassen sich nicht
  /// zurueckholen, also werden sie hier ignoriert.
  ///
  /// Verworfen wird alles, was vor dem Datum keinen Ortsteil hat, sowie
  /// die uebersetzten Platzhalter fuer "unbekanntes Meetup".
  static bool _isDegenerateEventId(String id) {
    final v = id.trim().toLowerCase();
    if (v.isEmpty) return true;
    if (v.startsWith('-')) return true; // "-2026-02-25"
    const placeholders = [
      'unbekanntes-meetup',
      'unknown-meetup',
      'meetup-desconocido',
    ];
    for (final p in placeholders) {
      if (v.startsWith(p)) return true;
    }
    // Reine Datumsangabe ohne Ort.
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return true;

    // GENERISCHE NAMEN aus Altdaten (vor der Signierer-Erweiterung).
    // Im Feldtest verband "test-2026-07-24" vier wildfremde Leute — jeder
    // Entwickler legt irgendwann eine Session namens "test" an, und ohne
    // Signierer im Schluessel landen sie alle im selben Topf. Solche
    // Eintraege liegen auf den Relays und lassen sich nicht zurueckholen.
    //
    // Betrifft NUR Schluessel im Altformat (ohne "@"): Neue tragen den
    // Signierer und koennen selbst bei generischem Namen nicht kollidieren.
    if (!v.contains('@')) {
      final namePart = v.replaceAll(RegExp(r'-\d{4}-\d{2}-\d{2}$'), '');
      const generic = {
        'test', 'test1', 'test2', 'test3', 'testing', 'demo',
        'home', 'garten', 'ab-test', 'probe', 'temp', 'tmp', 'xxx',
      };
      if (generic.contains(namePart)) return true;
    }
    return false;
  }

  /// Obergrenzen je Nachladestufe.
  ///
  /// Ohne sie wuechse jede Stufe mit der Netzwerkgroesse: Wer zwanzig Meetups
  /// besucht hat, bei denen je dreissig Leute waren, deren jeder weitere
  /// zwanzig Meetups hat … Die Grenzen halten Relays und Ladezeit im Rahmen.
  /// Wird eine erreicht, steht es im Log — abgeschnitten wird NIE still.
  static const int _maxMeetupsPerStage = 60;
  static const int _maxPeoplePerStage = 300;

  /// Wie viele Autoren eine Abfrage hoechstens enthaelt. Manche Relays
  /// begrenzen die Filtergroesse und antworten sonst gar nicht.
  static const int _authorBatch = 100;

  /// Baut die Knoten GRADWEISE auf.
  ///
  /// ============================================
  /// WARUM GESTAFFELT (Issue #57, Punkt 1)
  /// ============================================
  ///
  /// Frueher gab es zwei falsche Extreme:
  ///
  ///   - Alles holen, ungefiltert, Limit 500: Bei einem gewachsenen Netzwerk
  ///     kamen irgendwelche fremden Meetups an, aber nicht die eigenen.
  ///   - Nur die EIGENEN Meetups holen (die Korrektur danach): Grad 1
  ///     funktionierte wieder, aber die WEITEREN Meetups der Kontakte fehlten.
  ///     Eine Kette ich – B (gemeinsam bei X) – C (B und C bei Y) liess sich
  ///     so nie bilden, solange ich nicht selbst bei Y war. Grad 2 und 3
  ///     blieben leer, egal wie viele Meetups man besuchte.
  ///
  /// Jetzt wird nur geholt, was fuer die naechste Stufe gebraucht wird:
  ///
  ///   eigene Teilnahmen
  ///     → Teilnehmer dieser Meetups                     (Grad 1)
  ///     → deren weitere Teilnahmen
  ///     → Teilnehmer DIESER Meetups                     (Grad 2)
  ///     → deren weitere Teilnahmen
  ///     → Teilnehmer dieser Meetups                     (Grad 3)
  ///
  /// [extraNpubs] werden wie der eigene Schluessel als Ausgangspunkt
  /// behandelt — fuer die Pruefung einer bestimmten Person muessen DEREN
  /// Teilnahmen dabei sein, auch wenn sie weiter als drei Stufen entfernt ist.
  ///
  /// Veranstaltungen gehen in die Knoten ein, dienen aber NICHT zum
  /// Weiterhangeln: Bei fuenfhundert Besuchern ist gemeinsame Anwesenheit
  /// keine Begegnung, und der Graph wuerde sonst ueber jedes Grossevent
  /// explodieren.
  static Future<Map<String, CoAttNode>> _loadAllNodes({
    required String myNpub,
    List<String> extraNpubs = const [],
    int maxDepth = 3,
  }) async {
    final relays = await RelayConfig.getActiveRelays();
    final nodes = <String, CoAttNode>{};

    void addAll(Iterable<CoAttendanceRecord> recs) {
      for (final r in recs) {
        // Fehl-Kennungen ueberspringen — sonst entstehen Verknuepfungen
        // zwischen Leuten, die sich nie begegnet sind.
        if (_isDegenerateEventId(r.meetupEventId)) continue;
        final node = nodes.putIfAbsent(r.npub, () => CoAttNode(r.npub));
        if (isEventKey(r.meetupEventId)) {
          node.events.add(r.meetupEventId);
        } else {
          node.meetups.add(r.meetupEventId);
        }
      }
    }

    // Holt ueber alle Relays gleichzeitig und entdoppelt.
    Future<List<CoAttendanceRecord>> fetch({
      Set<String>? keys,
      List<String>? authors,
    }) async {
      final batches = <List<String>?>[];
      if (authors != null) {
        for (var k = 0; k < authors.length; k += _authorBatch) {
          batches.add(authors.sublist(
              k, (k + _authorBatch).clamp(0, authors.length)));
        }
      } else {
        batches.add(null);
      }

      final seen = <String>{};
      final out = <CoAttendanceRecord>[];
      for (final batch in batches) {
        final perRelay = await Future.wait(relays.map((url) =>
            _fetchFromRelay(url, myKeys: keys, authorsHex: batch)));
        for (final recs in perRelay) {
          if (recs == null) continue;
          for (final r in recs) {
            if (seen.add('${r.npub}|${r.meetupEventId}')) out.add(r);
          }
        }
      }
      return out;
    }

    String? toHex(String npub) {
      try {
        return Nip19.decodePubkey(npub);
      } catch (_) {
        return null;
      }
    }

    Set<String> meetupKeysOf(Iterable<CoAttendanceRecord> recs) => recs
        .map((r) => r.meetupEventId)
        .where((k) => !_isDegenerateEventId(k) && !isEventKey(k))
        .toSet();

    // --- Stufe 0: eigene Teilnahmen (und die der zu pruefenden Person) ---
    final seedHex = <String>[
      for (final n in [myNpub, ...extraNpubs])
        if (toHex(n) != null) toHex(n)!,
    ];
    if (seedHex.isEmpty) return nodes;

    final own = await fetch(authors: seedHex);
    addAll(own);

    final seenPeople = <String>{myNpub, ...extraNpubs};
    final seenKeys = <String>{};
    var frontierKeys = meetupKeysOf(own);

    AppLogger.diag('Netzwerk',
        'Stufe 0: ${own.length} eigene Teilnahmen, ${frontierKeys.length} Meetups.');

    for (var depth = 1; depth <= maxDepth; depth++) {
      frontierKeys = frontierKeys.difference(seenKeys);
      if (frontierKeys.isEmpty) break;

      var keys = frontierKeys;
      if (keys.length > _maxMeetupsPerStage) {
        AppLogger.warn('Netzwerk',
            'Grad $depth: ${keys.length} Meetups, begrenzt auf $_maxMeetupsPerStage.');
        keys = keys.take(_maxMeetupsPerStage).toSet();
      }
      seenKeys.addAll(keys);

      // Wer war bei diesen Meetups?
      final attendees = await fetch(keys: keys);
      addAll(attendees);

      var newPeople = attendees
          .map((r) => r.npub)
          .where((n) => !seenPeople.contains(n))
          .toSet();
      if (newPeople.length > _maxPeoplePerStage) {
        AppLogger.warn('Netzwerk',
            'Grad $depth: ${newPeople.length} Personen, begrenzt auf $_maxPeoplePerStage.');
        newPeople = newPeople.take(_maxPeoplePerStage).toSet();
      }
      seenPeople.addAll(newPeople);

      AppLogger.diag('Netzwerk',
          'Grad $depth: ${keys.length} Meetups abgefragt, ${newPeople.length} neue Personen.');

      if (depth == maxDepth || newPeople.isEmpty) break;

      // Wo waren diese Personen sonst noch?
      final hexes = newPeople.map(toHex).whereType<String>().toList();
      final theirs = await fetch(authors: hexes);
      addAll(theirs);
      frontierKeys = meetupKeysOf(theirs);
    }

    return nodes;
  }

  static Future<List<CoAttendanceRecord>?> _fetchFromRelay(
    String relayUrl, {
    Set<String>? myKeys,
    List<String>? authorsHex,
  }) async {
    RelaySocket? ws;
    final tally = RelayParseTally('CoAttendance', 'Co-Attendance von $relayUrl');
    final out = <CoAttendanceRecord>[];
    try {
      ws = await RelaySocket.connect(relayUrl).timeout(_timeout);
      final random = Random.secure();
      final subId = 'coatt-${List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
      final completer = Completer<List<CoAttendanceRecord>?>();

      ws.listen(
        (data) {
          tally.message();
          try {
            final msg = jsonDecode(data as String) as List<dynamic>;
            if (msg[0] == 'EVENT' && msg.length >= 3) {
              final ev = msg[2] as Map<String, dynamic>;
              final authorHex = ev['pubkey'] as String;
              final authorNpub = Nip19.encodePubkey(authorHex);
              final content = jsonDecode(ev['content'] as String) as Map<String, dynamic>;
              final meetupEventId = (content['event'] ?? '').toString();
              final t = (content['t'] is int) ? content['t'] as int : 0;
              if (meetupEventId.isNotEmpty) {
                out.add(CoAttendanceRecord(
                  npub: authorNpub,
                  meetupEventId: meetupEventId,
                  attendedAt: t,
                ));
              }
            }
            if (msg[0] == 'EOSE') {
              if (!completer.isCompleted) completer.complete(out);
            }
          } catch (e) { tally.failed(e); }
        },
        onDone: () { if (!completer.isCompleted) completer.complete(out); },
        onError: (_) { if (!completer.isCompleted) completer.complete(null); },
      );

      // Gezielt nach den eigenen Kennungen fragen — und nach denen OHNE
      // Signierer-Anhang gleich mit, weil aeltere Teilnahmen in dem Format
      // veroeffentlicht wurden und sonst durchs Raster fielen.
      final filter = <String, dynamic>{'kinds': [kind]};
      if (authorsHex != null && authorsHex.isNotEmpty) {
        filter['authors'] = authorsHex;
        // Bis zu hundert Personen je Abfrage, jede mit etlichen Teilnahmen —
        // 500 waren dafuer zu knapp und schnitten still ab (Issue #57,
        // Punkt 4). 5000 reicht fuer den Normalfall; wird es erreicht,
        // meldet das Log es weiter unten.
        filter['limit'] = 5000;
      } else if (myKeys != null && myKeys.isNotEmpty) {
        final wanted = <String>{};
        for (final k in myKeys) {
          wanted.add(k);
          final i = k.indexOf('@');
          if (i > 0) wanted.add(k.substring(0, i));
        }
        filter['#d'] = wanted.toList();
        // Grosszuegiges Limit: Bei einem gut besuchten Meetup kommen leicht
        // dreissig Teilnahmen je Termin zusammen.
        filter['limit'] = 1000;
      }
      ws.add(jsonEncode(['REQ', subId, filter]));

      final res = await completer.future.timeout(
        _timeout,
        onTimeout: () {
          // Teilmenge statt nichts — aber NICHT stillschweigend.
          //
          // Vorher kam ein halber Abruf zurueck, als waere er vollstaendig.
          // Im Netzwerk fehlten dann Kontakte, und niemand konnte sehen,
          // dass nur die Zeit abgelaufen war (Issue #57, Punkt 4).
          if (out.isNotEmpty) {
            AppLogger.warn(_tag,
                '$relayUrl: Zeit abgelaufen, ${out.length} Eintraege erhalten — Ergebnis moeglicherweise unvollstaendig.');
          }
          return out.isEmpty ? null : out;
        },
      );
      ws.add(jsonEncode(['CLOSE', subId]));

      // Limit erreicht heisst: Es gibt vermutlich mehr, als geliefert wurde.
      final limit = filter['limit'];
      if (res != null && limit is int && res.length >= limit) {
        AppLogger.warn(_tag,
            '$relayUrl: Limit von $limit erreicht — es gibt vermutlich weitere Eintraege.');
      }
      return res;
    } catch (e) {
      AppLogger.warn(_tag, 'Fetch-Fehler $relayUrl: $e');
      return null;
    } finally {
      tally.report();
      ws?.close();
    }
  }

  /// Analysiert das Netzwerk zwischen [myNpub] und [targetNpub].
  static Future<CoAttNetwork> analyze({
    required String myNpub,
    required String targetNpub,
  }) async {
    final nodes = await _loadAllNodes(myNpub: myNpub, extraNpubs: [targetNpub]);

    final myNode = nodes[myNpub];
    final targetNode = nodes[targetNpub];

    final myMeetups = myNode?.meetups ?? <String>{};
    final targetMeetups = targetNode?.meetups ?? <String>{};

    // Gemeinsame Meetups (ich + Ziel)
    final shared = sharedKeys(myMeetups, targetMeetups);

    // Gemeinsame Kontakte: andere npubs, die mit BEIDEN je ein Meetup teilen
    final mutual = <String>[];
    for (final entry in nodes.entries) {
      final npub = entry.key;
      if (npub == myNpub || npub == targetNpub) continue;
      final m = entry.value.meetups;
      final withMe = sharedKeys(m, myMeetups).isNotEmpty;
      final withTarget = sharedKeys(m, targetMeetups).isNotEmpty;
      if (withMe && withTarget) mutual.add(npub);
    }

    // Reichweite der Zielperson: mit wie vielen verschiedenen Leuten war sie?
    final targetContacts = <String>{};
    for (final entry in nodes.entries) {
      if (entry.key == targetNpub) continue;
      if (sharedKeys(entry.value.meetups, targetMeetups).isNotEmpty) {
        targetContacts.add(entry.key);
      }
    }

    return CoAttNetwork(
      myNpub: myNpub,
      targetNpub: targetNpub,
      sharedMeetups: shared,
      mutualContacts: mutual,
      nodes: nodes,
      targetTotalMeetups: targetMeetups.length,
      targetTotalContacts: targetContacts.length,
    );
  }

  static String npubToHex(String npub) => NostrService.npubToHex(npub);

  /// Prüft die physische Verbindung zu EINER bestimmten Person ("Präsenz-Check").
  ///
  /// Berechnet den kürzesten Pfad über echte Meetup-Begegnungen:
  ///   Grad 0 = das bin ich selbst (npub identisch)
  ///   Grad 1 = direkt auf einem Meetup getroffen
  ///   Grad 2 = jemand, den ich getroffen habe, hat die Person getroffen
  ///   Grad 3+ = noch weiter über die Kette
  /// Gibt den konkreten Pfad (Du -> ... -> Zielperson) zurück.
  static Future<PresenceCheck> verifyPerson({
    required String myNpub,
    required String targetNpub,
    int maxDepth = 6,
  }) async {
    // Die Pruefung braucht die Teilnahmen der Zielperson — deshalb als
    // zweiter Ausgangspunkt. Tiefer als drei Stufen wird nicht geladen,
    // auch wenn die Suche weiter reicht: Die Kette ergibt sich von beiden
    // Enden her.
    final nodes = await _loadAllNodes(
        myNpub: myNpub, extraNpubs: [targetNpub], maxDepth: 3);

    final myMeetups = nodes[myNpub]?.meetups ?? <String>{};
    final targetMeetups = nodes[targetNpub]?.meetups ?? <String>{};
    final sharedMeetups = sharedKeys(myMeetups, targetMeetups);

    // Sonderfall: man selbst
    if (myNpub == targetNpub) {
      return PresenceCheck(
        targetNpub: targetNpub,
        degree: 0,
        path: [myNpub],
        sharedMeetups: sharedMeetups,
        targetInNetwork: nodes.containsKey(targetNpub),
        targetTotalMeetups: targetMeetups.length,
      );
    }

    // Ungerichtete Adjazenz aufbauen (Kante = gemeinsames Meetup)
    final adj = <String, Set<String>>{};
    final entries = nodes.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        if (sharedKeys(entries[i].value.meetups, entries[j].value.meetups).isNotEmpty) {
          adj.putIfAbsent(entries[i].key, () => <String>{}).add(entries[j].key);
          adj.putIfAbsent(entries[j].key, () => <String>{}).add(entries[i].key);
        }
      }
    }

    final targetInNetwork = nodes.containsKey(targetNpub);

    // BFS für kürzesten Pfad my -> target
    List<String>? foundPath;
    if (adj.containsKey(myNpub)) {
      final visited = <String>{myNpub};
      final queue = <List<String>>[[myNpub]];
      while (queue.isNotEmpty) {
        final cur = queue.removeAt(0);
        if (cur.length - 1 > maxDepth) continue;
        final last = cur.last;
        if (last == targetNpub) { foundPath = cur; break; }
        for (final n in (adj[last] ?? const <String>{})) {
          if (!visited.contains(n)) {
            visited.add(n);
            queue.add([...cur, n]);
          }
        }
      }
    }

    return PresenceCheck(
      targetNpub: targetNpub,
      degree: foundPath == null ? -1 : foundPath.length - 1,
      path: foundPath ?? const [],
      sharedMeetups: sharedMeetups,
      targetInNetwork: targetInNetwork,
      targetTotalMeetups: targetMeetups.length,
    );
  }

  /// Erfasst die Teilnahme des ORGANISATORS am eigenen Meetup.
  ///
  /// Anders als beim normalen Badge-Scan:
  ///  - Der Organisator darf sich kein selbst-signiertes Reputations-Badge
  ///    geben (würde den Trust Score manipulieren — bleibt blockiert).
  ///  - ABER: Er war nachweislich da (hat das Event signiert), also nimmt er
  ///    automatisch am Co-Attendance-Netzwerk teil und bekommt ein
  ///    Organisator-MARKER-Badge (isOrganizer = true, zählt NICHT zum Score).
  ///
  /// [meetupName] und [date] müssen identisch zu den Teilnehmer-Badges sein,
  /// damit derselbe meetupEventId entsteht und alle im selben Knoten landen.
  ///
  /// Gibt das erstellte Organisator-Badge zurück (oder null bei Fehler).
  static Future<MeetupBadge?> recordOrganizerAttendance({
    required String meetupName,
    required DateTime date,
    int blockHeight = 0,
    double lat = 0,
    double lng = 0,
    /// Event statt Meetup. Muss durchgereicht werden, sonst landete der
    /// Helfer selbst im Meetup-Graphen, waehrend alle, die bei ihm gescannt
    /// haben, im Event-Graphen sitzen — er waere von seinen eigenen
    /// Teilnehmern getrennt.
    bool isEvent = false,
  }) async {
    try {
      // Exakt dasselbe Format wie in meetup_verification.dart
      final dateStr = date.toIso8601String().substring(0, 10);
      final meetupEventId =
          '${meetupName.toLowerCase().replaceAll(' ', '-')}-$dateStr';

      // Blockhöhe sicherstellen: falls 0 übergeben (Session hatte sie nicht),
      // selbst von Mempool holen — damit das Badge eine echte Blockzeit hat.
      int finalBlockHeight = blockHeight;
      if (finalBlockHeight <= 0) {
        finalBlockHeight = await MempoolService.getBlockHeight();
      }

      // 1. Organisator-Marker-Badge erstellen (zählt NICHT zum Trust Score)
      final badge = MeetupBadge(
        id: 'org-$meetupEventId',
        meetupName: meetupName,
        date: date,
        iconPath: '',
        blockHeight: finalBlockHeight,
        meetupEventId: meetupEventId,
        isEvent: isEvent,
        delivery: 'organizer',
        isOrganizer: true,
        lat: lat,
        lng: lng,
      );

      // 2. Schon vorhanden? (nicht doppelt anlegen)
      final existing = await MeetupBadge.loadBadges();
      final already = existing.any((b) =>
          b.isOrganizer && b.meetupEventId == meetupEventId);
      if (!already) {
        existing.add(badge);
        await MeetupBadge.saveBadges(existing);
      }

      // 3. Co-Attendance veröffentlichen (Organisator nimmt automatisch teil).
      //    Hier KEIN isNostrSigned-Check wie bei publishAttendance, weil die
      //    Teilnahme durch die Organisator-Signatur der Session ohnehin belegt
      //    ist (nur der Organisator besitzt den Schlüssel).
      await _publishOrganizerAttendance(meetupEventId, meetupName, date,
          isEvent: isEvent);

      return badge;
    } catch (e) {
      AppLogger.warn(_tag, 'Organisator-Teilnahme fehlgeschlagen: $e');
      return null;
    }
  }

  static Future<int> _publishOrganizerAttendance(
      String meetupEventId, String meetupName, DateTime date,
      {bool isEvent = false}) async {
    // Der Organisator IST der Signierer seiner eigenen Session — damit
    // stimmt sein Schluessel mit dem seiner Teilnehmer ueberein.
    final ownNpub = await SigningService.npub();
    final key =
        attendanceKey(meetupEventId, ownNpub ?? '', isEvent: isEvent);
    try {
      final content = jsonEncode({
        'event': key,
        'meetup': meetupName,
        't': date.millisecondsSinceEpoch ~/ 1000,
        'role': 'organizer',
      });
      final signed = await SigningService.signEvent(
        kind: kind,
        tags: <List<String>>[
          ['d', key],
          ['role', 'organizer'],
          ['client', _client],
        ],
        content: content,
      );
      return await _publish(signed);
    } catch (e) {
      AppLogger.warn(_tag, 'Organisator-Publish fehlgeschlagen: $e');
      return 0;
    }
  }

  /// Baut das EIGENE Netzwerk auf — automatisch, ohne npub-Eingabe.
  ///
  /// Grad 1 = Leute, die ich auf Meetups getroffen habe (gemeinsamer Event).
  /// Grad 2 = deren Kontakte, die ich selbst noch nicht getroffen habe.
  /// Grad 3 = noch eine Ebene weiter.
  ///
  /// Für jeden Kontakt wird festgehalten, über WEN (Brücke, Grad-1-Kontakt)
  /// er erreichbar ist — das ist die Grundlage des transitiven Vertrauens.
  static Future<MyNetwork> buildMyNetwork({
    required String myNpub,
    int maxDepth = 3,
  }) async {
    final nodes = await _loadAllNodes(myNpub: myNpub, maxDepth: maxDepth);

    // Ungerichtete Adjazenz: A--B wenn sie >=1 Meetup teilen
    final adj = <String, Set<String>>{};
    final entries = nodes.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      for (int j = i + 1; j < entries.length; j++) {
        final a = entries[i];
        final b = entries[j];
        if (sharedKeys(a.value.meetups, b.value.meetups).isNotEmpty) {
          adj.putIfAbsent(a.key, () => <String>{}).add(b.key);
          adj.putIfAbsent(b.key, () => <String>{}).add(a.key);
        }
      }
    }

    final myMeetups = nodes[myNpub]?.meetups ?? <String>{};

    // BFS: Grad pro npub + über welchen Grad-1-Kontakt erreichbar
    final degree = <String, int>{myNpub: 0};
    final bridges = <String, Set<String>>{}; // npub -> Grad-1-Brücken
    final queue = <String>[myNpub];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final curDeg = degree[current]!;
      if (curDeg >= maxDepth) continue;
      for (final neighbor in (adj[current] ?? const <String>{})) {
        if (!degree.containsKey(neighbor)) {
          degree[neighbor] = curDeg + 1;
          queue.add(neighbor);
        }
        // Brücke merken: der Grad-1-Knoten auf dem Weg
        if (curDeg == 0) {
          // direkter Nachbar -> er ist seine eigene "Brücke" (Grad 1)
        } else if (degree[neighbor] == curDeg + 1) {
          final via = (curDeg == 1) ? current : null;
          if (via != null) {
            bridges.putIfAbsent(neighbor, () => <String>{}).add(via);
          } else {
            // tiefer: Brücken des current weiterreichen
            final inherited = bridges[current];
            if (inherited != null) {
              bridges.putIfAbsent(neighbor, () => <String>{}).addAll(inherited);
            }
          }
        }
      }
    }

    // Kontakte nach Grad gruppieren
    final byDegree = <int, List<NetworkContact>>{1: [], 2: [], 3: []};
    for (final entry in degree.entries) {
      final npub = entry.key;
      final deg = entry.value;
      if (deg == 0 || deg > maxDepth) continue;

      Set<String> shared = <String>{};
      if (deg == 1) {
        shared = sharedKeys(nodes[npub]?.meetups ?? <String>{}, myMeetups);
      }

      byDegree.putIfAbsent(deg, () => []).add(NetworkContact(
            npub: npub,
            degree: deg,
            sharedMeetupsWithMe: shared,
            bridges: deg == 1 ? <String>{} : (bridges[npub] ?? <String>{}),
          ));
    }

    // ── DIAGNOSE ────────────────────────────────────────────────────
    // Erscheint jemand faelschlich im 1. Grad, laesst sich hier ablesen,
    // WELCHE Kennung die Verbindung erzeugt. Ohne diese Zeilen bleibt nur
    // Raten — die Kennung steckt weder in der Oberflaeche noch im Badge.
    AppLogger.diag('Netzwerk',
        'Eigene Meetup-Kennungen (${myMeetups.length}): '
        '${myMeetups.join(", ")}');
    // Zaehlt mit, ob ueberhaupt fremde Teilnahmen ankamen. Ohne diese Zahl
    // sieht ein leeres Netzwerk gleich aus, egal ob die Relays nichts
    // lieferten oder ob die Kennungen nicht zusammenpassten.
    AppLogger.diag('Netzwerk',
        '${nodes.length} Teilnehmer aus den Relays, davon ${(byDegree[1] ?? const []).length} im 1. Grad, '
        '${(byDegree[2] ?? const []).length} im 2. Grad.');

    // Bei NULL Treffern eine Stichprobe der FREMDEN Kennungen ausgeben.
    //
    // Ohne sie sieht man nur, dass nichts passt — nicht warum. Und der
    // Vergleich der beiden Formate nebeneinander beantwortet die Frage
    // sofort: gleiche Meetups mit anderem Anhang, andere Schreibweise, oder
    // schlicht andere Meetups.
    if ((byDegree[1] ?? const []).isEmpty && nodes.isNotEmpty) {
      final fremde = <String>{};
      for (final e in nodes.entries) {
        if (e.key == myNpub) continue;
        fremde.addAll(e.value.meetups);
        if (fremde.length >= 15) break;
      }
      AppLogger.diag('Netzwerk',
          'Keine Treffer. Fremde Kennungen (Stichprobe): ${fremde.take(15).join(", ")}');
    }
    for (final c in (byDegree[1] ?? const <NetworkContact>[])) {
      AppLogger.diag('Netzwerk',
          '1. Grad ${c.npub.substring(0, c.npub.length > 16 ? 16 : c.npub.length)}… '
          'ueber: ${c.sharedMeetupsWithMe.join(", ")}');
    }

    // Sortierung: Grad 1 nach Anzahl gemeinsamer Meetups, sonst nach Brücken-Anzahl
    byDegree[1]?.sort((a, b) =>
        b.sharedMeetupsWithMe.length.compareTo(a.sharedMeetupsWithMe.length));
    byDegree[2]?.sort((a, b) => b.bridges.length.compareTo(a.bridges.length));
    byDegree[3]?.sort((a, b) => b.bridges.length.compareTo(a.bridges.length));

    return MyNetwork(
      myNpub: myNpub,
      byDegree: byDegree,
      myMeetupCount: myMeetups.length,
    );
  }
}

/// Ein Kontakt im eigenen Netzwerk.
class NetworkContact {
  final String npub;
  final int degree;                    // 1, 2 oder 3
  final Set<String> sharedMeetupsWithMe; // nur bei Grad 1 befüllt
  final Set<String> bridges;           // Grad-1-Kontakte, über die ich diese Person erreiche (Grad 2+)

  NetworkContact({
    required this.npub,
    required this.degree,
    required this.sharedMeetupsWithMe,
    required this.bridges,
  });
}

/// Das gesamte eigene Netzwerk, nach Graden gruppiert.
class MyNetwork {
  final String myNpub;
  final Map<int, List<NetworkContact>> byDegree;
  final int myMeetupCount;

  MyNetwork({
    required this.myNpub,
    required this.byDegree,
    required this.myMeetupCount,
  });

  int get degree1Count => byDegree[1]?.length ?? 0;
  int get degree2Count => byDegree[2]?.length ?? 0;
  int get degree3Count => byDegree[3]?.length ?? 0;
  int get totalReach => degree1Count + degree2Count + degree3Count;
  bool get isEmpty => totalReach == 0;
}

/// Ergebnis eines Präsenz-Checks zu einer bestimmten Person.
class PresenceCheck {
  final String targetNpub;
  final int degree;              // 0=ich, 1=direkt, 2/3...=über Ecken, -1=keine Verbindung
  final List<String> path;       // konkreter Pfad [myNpub, ..., targetNpub]
  final Set<String> sharedMeetups; // gemeinsame Meetups (bei Grad 1)
  final bool targetInNetwork;    // nimmt die Zielperson überhaupt am Netzwerk teil?
  final int targetTotalMeetups;  // wie viele Meetups die Zielperson besucht hat

  PresenceCheck({
    required this.targetNpub,
    required this.degree,
    required this.path,
    required this.sharedMeetups,
    required this.targetInNetwork,
    required this.targetTotalMeetups,
  });

  bool get found => degree >= 0;
  bool get isDirect => degree == 1;
  bool get isSelf => degree == 0;
}
