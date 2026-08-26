// VERANSTALTUNGSKALENDER
// ============================================
// Übersichtlicher Kalender über alle Nostr-Events (NIP-52) + Meetups.
// Drei Ansichten: Monat (Grid), Jahr (12 Monate), Liste (chronologisch).
// Eigenes Kalender-Grid (keine externe Abhängigkeit).
// Button zum Eintragen eigener Veranstaltungen, die bei Nostr publiziert
// werden und so für alle sichtbar sind.
// ============================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/calendar_event_service.dart';
import 'package:image_picker/image_picker.dart';

import '../services/blossom_upload_service.dart';
import '../services/event_badge_auth_service.dart';
import '../services/guide_service.dart';
import '../mixins/guide_service_host.dart';
import '../tours/event_badge_tour.dart';
import '../services/nostr_service.dart';
import '../services/event_badge_session_service.dart';
import '../services/event_rsvp_service.dart';
import '../services/rolling_qr_service.dart';
import '../services/signing_service.dart';
import 'chat_screen.dart';
import 'rolling_qr_screen.dart';
import 'location_picker_screen.dart';
import '../services/meetup_calendar_service.dart';
import '../services/portal_api_service.dart';
import '../models/calendar_event.dart' as ical;

enum _CalView { month, year, list }

/// Vereinheitlichter Kalender-Eintrag — vereint Nostr-Events (NIP-52) und
/// die Portal-/iCal-Meetups in einer gemeinsamen Darstellung.
/// isMeetup steuert die Farbe (Meetup = orange, Nostr-Event = cyan/gold).
class _CalItem {
  final String title;
  final String description;
  final String location;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final bool isMeetup;
  final bool isCourse; // Portal-Kurstermin (eigene Farbe)
  final String url;

  /// Das zugrunde liegende Nostr-Event — nur bei Terminen aus dem
  /// Nostr-Kalender gesetzt. Traegt Badge-Bild, Koordinaten und die
  /// Aussteller-Liste; die Anzeige greift direkt darauf zu, statt jedes
  /// Feld einzeln durchzureichen.
  final NostrCalendarEvent? nostr;

  _CalItem({
    required this.title,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.allDay,
    required this.isMeetup,
    this.isCourse = false,
    this.url = '',
    this.nostr,
  });

  DateTime get day => DateTime(start.year, start.month, start.day);
  Color get color => isCourse ? cCourse : (isMeetup ? cOrange : cNostr);

  /// Gibt es fuer diesen Termin ein Badge?
  bool get hasBadge => nostr?.badgeEnabled ?? false;

  /// Bild des Event-Badges, leer wenn keines hinterlegt ist.
  String get badgeImage => nostr?.badgeImageUrl ?? '';

  factory _CalItem.fromNostr(NostrCalendarEvent e) => _CalItem(
        title: e.title,
        description: e.description,
        location: e.location,
        start: e.start,
        end: e.end,
        allDay: e.allDay,
        isMeetup: false,
        nostr: e,
      );

  factory _CalItem.fromMeetup(ical.CalendarEvent e) => _CalItem(
        title: e.title,
        description: e.description,
        location: e.location,
        start: e.startTime,
        end: null,
        allDay: false,
        isMeetup: true,
      );
}

/// Kennung fuer den eigenen Schluessel im Kalender-Bildschirm. Wird einmal
/// beim Laden geholt und dann nur noch verglichen.
class EventCalendarScreen extends StatefulWidget {
  /// Tag, der beim Oeffnen ausgewaehlt sein soll. Wird von der
  /// Dashboard-Kachel gesetzt, damit man direkt in der Tagesuebersicht
  /// landet statt im aktuellen Monat ohne Auswahl.
  final DateTime? initialDay;

  const EventCalendarScreen({super.key, this.initialDay});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  _CalView _view = _CalView.month;
  late DateTime _focused;   // aktuell angezeigter Monat/Jahr
  late DateTime _selected;  // gewählter Tag (Monatsansicht)
  bool _loading = true;
  List<_CalItem> _allItems = [];       // alle geladenen (ungefiltert)
  List<_CalItem> _events = [];         // aktuell angezeigte (gefiltert)
  // Events nach Tag gruppiert (für schnelle Marker)
  Map<DateTime, List<_CalItem>> _byDay = {};

  // Filter
  int _typeFilter = 0;                 // 0=Alle, 1=Meetups, 2=Externe, 3=Kurse
  bool _worldwide = false;             // false=nur Community-Relay, true=alle
  final TextEditingController _locationCtrl = TextEditingController();
  String _locationQuery = '';

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  /// Eigener Schluessel — einmal geholt, danach nur noch verglichen. Damit
  /// erkennt der Bildschirm, ob man bei einem Termin als Aussteller
  /// eingetragen ist. Eine eigene Relay-Abfrage dafuer waere ueberfluessig:
  /// Die Termine liegen ohnehin schon geladen vor.
  String? _myPubkey;

  /// Laeuft gerade ein Sessionstart? Sperrt den Knopf — die Ortspruefung
  /// dauert ein paar Sekunden, und zweimal tippen erzeugt sonst zwei
  /// Versuche.
  bool _startingSession = false;

  /// meetupId einer bereits laufenden Session, sonst null. Damit der Knopf
  /// "QR anzeigen" statt "Session starten" heisst — sonst sieht es aus, als
  /// muesste man jedes Mal neu beginnen, obwohl die alte Session
  /// weiterlaeuft.
  String? _runningSessionId;

  @override
  void initState() {
    super.initState();
    final start = widget.initialDay ?? DateTime.now();
    _focused = DateTime(start.year, start.month);
    _selected = DateTime(start.year, start.month, start.day);
    _loadMyPubkey();
    _loadRunningSession();
    _loadRsvps();
    _load();
  }

  Future<void> _loadRunningSession() async {
    final s = await RollingQRService.loadSession();
    if (!mounted) return;
    setState(() =>
        _runningSessionId = (s != null && !s.isExpired) ? s.meetupId : null);
  }

  Future<void> _loadMyPubkey() async {
    final key = await SigningService.pubkeyHex();
    if (mounted) setState(() => _myPubkey = key);
  }

  /// Hinweiskasten unter dem Termin: Es gibt ein Badge — und wer es
  /// ausgeben darf, erfaehrt es hier.
  Widget _badgeNotice(AppLocalizations t, _CalItem e) {
    final iAmIssuer =
        _myPubkey != null && (e.nostr?.isIssuer(_myPubkey!) ?? false);

    // Termine aus aelteren Fassungen koennen ein Badge tragen, ohne dass
    // Koordinaten hinterlegt sind. Beim Anlegen wird das inzwischen
    // verhindert; die bereits veroeffentlichten bleiben aber im Umlauf, und
    // dort gibt es kein Badge — die Ausgabe prueft den Abstand zum
    // Veranstaltungsort. Das gehoert in den Kasten, nicht erst auf den
    // Knopf: Wer hinfaehrt, soll es vorher wissen.
    final noLocation =
        (e.nostr?.lat ?? 0) == 0 && (e.nostr?.lng ?? 0) == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cOrange.withValues(alpha: iAmIssuer ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(
            color: cOrange.withValues(alpha: iAmIssuer ? 0.5 : 0.25),
            width: 0.5),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.military_tech_rounded, color: cOrange, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(iAmIssuer ? t.evBadgeYouIssue : t.evBadgeAvailable,
                style: const TextStyle(
                    color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(
                noLocation
                    ? t.evBadgeNoLocationSet
                    : (iAmIssuer
                        ? t.evBadgeYouIssueSub
                        : t.evBadgeAvailableSub),
                style: TextStyle(
                    color: noLocation ? cRed : cTextSecondary,
                    fontSize: 12,
                    height: 1.45)),
            // Der Knopf erscheint NUR am Termintag. Ihn ganzjaehrig zu
            // zeigen und dann abzulehnen waere eine Einladung ins Leere.
            // Ohne Ort kein Knopf: Er wuerde nur die Ablehnung ausloesen.
            if (iAmIssuer && !noLocation && (e.nostr?.isBadgeWindowOpen ?? false)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startingSession ? null : () => _startEventSession(e),
                  icon: _startingSession
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.qr_code_2_rounded,
                          color: Colors.black, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cOrange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kTileRadius)),
                  ),
                  label: Text(
                      _runningSessionId != null &&
                              e.nostr != null &&
                              _runningSessionId!.contains(e.nostr!.dTag)
                          ? t.evBadgeShowSession
                          : t.evBadgeStartSession,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  /// Eigene Antworten auf Termine, Adresse zu Status. Wird beim Oeffnen des
  /// Kalenders geladen.
  Map<String, RsvpStatus> _rsvps = {};
  String? _rsvpBusy;

  Future<void> _loadRsvps() async {
    final mine = await EventRsvpService.loadMine();
    if (mounted) setState(() => _rsvps = mine);
  }

  /// Zwei Knoepfe: Ich komme / Ich komme nicht.
  ///
  /// Bewusst KEIN dritter fuer "vielleicht". Das Protokoll kennt ihn, aber
  /// eine dritte Wahl macht die Zeile breiter und die Aussage schwaecher —
  /// wer unsicher ist, sagt einfach noch gar nichts.
  /// [setSheet] zeichnet das Blatt neu — der Kalender-State erreicht es
  /// nicht.
  Widget _rsvpRow(
      AppLocalizations t, NostrCalendarEvent event, StateSetter setSheet) {
    final current = _rsvps[event.address];
    final busy = _rsvpBusy == event.address;

    Widget button(RsvpStatus status, IconData icon, String label, Color color) {
      final active = current == status;
      // NICHT gewaehlt = neutral grau. Vorher trug "Ich komme" auch ohne
      // Zusage gruene Schrift und einen gruenen Rand — das las sich wie eine
      // bereits erteilte Zusage, und wer sich darauf verliess, tauchte in
      // keiner Teilnehmerliste auf. Farbe bedeutet hier: entschieden.
      final fg = active ? Colors.black : cTextSecondary;
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: busy ? null : () => _setRsvp(event, status, setSheet),
          icon: Icon(icon, size: 17, color: fg),
          style: OutlinedButton.styleFrom(
            backgroundColor: active ? color : Colors.transparent,
            side: BorderSide(
                color: active ? color : cTileBorder,
                width: active ? 1 : 0.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          label: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
        ),
      );
    }

    return Row(children: [
      button(RsvpStatus.accepted, Icons.check_rounded, t.rsvpYes, cGreen),
      const SizedBox(width: 8),
      button(RsvpStatus.declined, Icons.close_rounded, t.rsvpNo, cTextSecondary),
    ]);
  }

  Future<void> _setRsvp(NostrCalendarEvent event, RsvpStatus status,
      StateSetter setSheet) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Sofort umschalten, dann senden. Eine Zusage ist eine Kleinigkeit; auf
    // die Relay-Antwort zu warten, bevor sich etwas ruehrt, faende
    // niemand angemessen. Schlaegt es fehl, wird zurueckgesetzt.
    final previous = _rsvps[event.address];
    // BEIDE neu zeichnen: setState fuer den Kalender darunter, setSheet fuer
    // das Blatt darueber. Die Daten liegen im Kalender-State, gezeigt werden
    // sie im Blatt — eines allein genuegt nicht.
    setState(() {
      _rsvps[event.address] = status;
      _rsvpBusy = event.address;
    });
    setSheet(() {});

    final err = await EventRsvpService.setStatus(
      eventAddress: event.address,
      eventAuthorPubkey: event.pubkey,
      status: status,
    );

    if (!mounted) return;
    setState(() {
      _rsvpBusy = null;
      if (err != null) {
        if (previous == null) {
          _rsvps.remove(event.address);
        } else {
          _rsvps[event.address] = previous;
        }
      }
    });
    setSheet(() {});
    if (err != null) {
      messenger.showSnackBar(SnackBar(
          content: Text(t.rsvpFailed(err)), backgroundColor: cRed));
    }
  }

  /// Oeffnet den Chat zu einem Termin.
  ///
  /// Nichts anzulegen, nichts freizuschalten: Der Strang haengt als
  /// NIP-22-Kommentar am Termin selbst und existiert, sobald jemand etwas
  /// schreibt. Genau deshalb laeuft er NICHT ueber das Gruppen-Relay — dort
  /// braeuchte ein Raum eine Berechtigung, die derjenige, der den Termin
  /// angelegt hat, oft gar nicht hat.
  void _openEventChat(_CalItem e) {
    final event = e.nostr;
    if (event == null) return;

    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatScreen.event(
        eventAddress: event.address,
        eventAuthor: event.pubkey,
        title: event.title,
      ),
    ));
  }

  /// Badge-Session fuer ein Event starten.
  Future<void> _startEventSession(_CalItem e) async {
    final event = e.nostr;
    if (event == null) return;

    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _startingSession = true);

    final res = await EventBadgeSessionService.start(event);

    if (!mounted) return;
    setState(() => _startingSession = false);

    if (!res.ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(_sessionErrorText(t, res)),
        backgroundColor: cRed,
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    // Detailblatt schliessen, dann den QR zeigen — sonst laege der Code
    // hinter dem halbhohen Blatt.
    navigator.pop();
    await navigator.push(
      MaterialPageRoute(builder: (_) => const RollingQRScreen()),
    );
    if (mounted) _loadRunningSession();
  }

  String _sessionErrorText(AppLocalizations t, EventSessionResult res) =>
      switch (res.error) {
        EventSessionError.noIdentity => t.evSessionNoIdentity,
        EventSessionError.notIssuer => t.evSessionNotIssuer,
        EventSessionError.outsideWindow => t.evSessionOutsideWindow,
        EventSessionError.noEventLocation => t.evSessionNoEventLocation,
        EventSessionError.locationUnavailable => t.evSessionNoLocation,
        EventSessionError.tooFarAway =>
          t.evSessionTooFar((res.distanceKm ?? 0).toStringAsFixed(1)),
        _ => t.evSessionFailed,
      };

  Future<void> _load() async {
    setState(() => _loading = true);
    // Beide Quellen laden: Nostr-Events (NIP-52) + Portal-/iCal-Meetups.
    // Getrennt awaiten, damit die Typen sauber erhalten bleiben.
    final nostrFuture = CalendarEventService.fetchEvents(worldwide: _worldwide);
    final meetupFuture = MeetupCalendarService().fetchMeetupsPortalFirst();
    final coursesFuture = PortalApiService.getCourses();
    final List<NostrCalendarEvent> nostrEvents = await nostrFuture;
    final List<ical.CalendarEvent> meetups = await meetupFuture;
    final List<Map<String, dynamic>> courses = await coursesFuture;
    if (!mounted) return;

    final items = <_CalItem>[];
    for (final e in nostrEvents) {
      items.add(_CalItem.fromNostr(e));
    }
    for (final m in meetups) {
      items.add(_CalItem.fromMeetup(m));
    }
    // KURS-TERMINE: Die Übersicht (/courses) enthält NUR next_event, nicht
    // die volle Terminliste. Die vielen Termine (z.B. Schnuartz' 11) stecken
    // in der DETAIL-Antwort /courses/{id} -> Feld "events" mit from/to/venue.
    // Wir laden die Details parallel (mit Limit gegen Überlastung).
    final cutoff = DateTime.now().subtract(const Duration(hours: 6));
    final courseIds = courses.map((c) => c['id']).whereType<int>().toSet().toList();
    final details = <Map<String, dynamic>>[];
    const cchunk = 8;
    for (var i = 0; i < courseIds.length; i += cchunk) {
      final batch = courseIds.skip(i).take(cchunk);
      final results = await Future.wait(batch.map((id) => PortalApiService.getCourse(id)));
      details.addAll(results.whereType<Map<String, dynamic>>());
    }
    if (!mounted) return;
    final seenCourseEv = <String>{}; // gegen Doppel-Einträge
    for (final c in details) {
      final cname = (c['name'] ?? c['title'] ?? 'Kurs').toString();
      final cdesc = (c['description'] ?? '').toString();
      final cportal = (c['portalLink'] ?? '').toString();
      final evs = (c['events'] is List) ? c['events'] as List : const [];
      for (final ev in evs.whereType<Map>()) {
        final start = MeetupCalendarService.portalStart((ev['from'] ?? ev['start'] ?? '').toString());
        if (start == null || start.toLocal().isBefore(cutoff)) continue;
        // Dedup: gleiche Termin-id ODER gleiche Kurs+Startzeit nur EINMAL
        final evKey = ev['id'] != null ? 'e${ev['id']}' : '$cname@${start.toIso8601String()}';
        if (!seenCourseEv.add(evKey)) continue;
        // Ort: venue.name (+ Stadt), sonst location
        String loc = '';
        final venue = ev['venue'];
        if (venue is Map) {
          loc = (venue['name'] ?? '').toString();
          final city = venue['city'];
          if (city is Map && (city['name'] ?? '').toString().isNotEmpty) {
            loc = loc.isEmpty ? city['name'].toString() : '$loc · ${city['name']}';
          }
        }
        if (loc.isEmpty) loc = (ev['location'] ?? '').toString();
        items.add(_CalItem(
          title: cname,
          description: cdesc,
          location: loc,
          start: start.toLocal(),
          end: DateTime.tryParse((ev['to'] ?? '').toString())?.toLocal(),
          allDay: false,
          isMeetup: false,
          isCourse: true,
          url: (ev['link'] ?? cportal).toString(),
        ));
      }
    }
    items.sort((a, b) => a.start.compareTo(b.start));

    // QUELLENÜBERGREIFENDE DEDUP: Derselbe Termin kann aus mehreren Quellen
    // kommen (z.B. ein Kurs als Nostr-Event UND als Portal-Kurstermin). Wir
    // erkennen Duplikate an gleicher Startzeit (auf die Minute) + ähnlichem
    // Titel (erste 12 Zeichen, normalisiert) bzw. gleichem Ort.
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9äöü]'), '');
    // Vor der Dedup: bevorzugte Reihenfolge, damit bei Duplikaten die
    // SAUBERE Variante gewinnt (Portal-Kurstermin/Meetup vor Nostr-Blob).
    int rank(_CalItem e) => e.isCourse ? 0 : (e.isMeetup ? 1 : 2);
    final dedup = <_CalItem>[];
    final byKey = <String, _CalItem>{};
    for (final it in items) {
      final tkey = norm(it.title);
      final tShort = tkey.length > 12 ? tkey.substring(0, 12) : tkey;
      final minuteKey = '${it.start.year}${it.start.month}${it.start.day}${it.start.hour}${it.start.minute}';
      final key = '$minuteKey|$tShort';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = it;
      } else if (rank(it) < rank(existing)) {
        byKey[key] = it; // bessere Variante ersetzt die schlechtere
      }
    }
    dedup.addAll(byKey.values);
    dedup.sort((a, b) => a.start.compareTo(b.start));
    items
      ..clear()
      ..addAll(dedup);

    _allItems = items;
    if (mounted) setState(() => _loading = false);
    _applyFilter();
  }

  /// Wendet Typ- und Ortsfilter auf _allItems an und füllt _events + _byDay.
  void _applyFilter() {
    final q = _locationQuery.trim().toLowerCase();
    final filtered = _allItems.where((e) {
      // Typ-Filter: 0=Alle, 1=Meetups, 2=Externe, 3=Kurse
      if (_typeFilter == 1 && !e.isMeetup) return false;
      if (_typeFilter == 2 && (e.isMeetup || e.isCourse)) return false;
      if (_typeFilter == 3 && !e.isCourse) return false;
      // Orts-Filter: leerer Ort bleibt IMMER sichtbar (nichts verstecken)
      if (q.isNotEmpty) {
        final loc = e.location.trim().toLowerCase();
        if (loc.isNotEmpty && !loc.contains(q)) return false;
      }
      return true;
    }).toList();

    final map = <DateTime, List<_CalItem>>{};
    for (final e in filtered) {
      map.putIfAbsent(e.day, () => []).add(e);
    }
    if (mounted) setState(() { _events = filtered; _byDay = map; });
  }

  bool get _filterActive => _typeFilter != 0 || _locationQuery.trim().isNotEmpty;

  void _clearFilter() {
    _locationCtrl.clear();
    setState(() { _typeFilter = 0; _locationQuery = ''; });
    _applyFilter();
  }

  List<_CalItem> _eventsOn(DateTime day) =>
      _byDay[DateTime(day.year, day.month, day.day)] ?? const [];

  String _monthName(AppLocalizations t, int m) {
    switch (m) {
      case 1: return t.calMonth1; case 2: return t.calMonth2; case 3: return t.calMonth3;
      case 4: return t.calMonth4; case 5: return t.calMonth5; case 6: return t.calMonth6;
      case 7: return t.calMonth7; case 8: return t.calMonth8; case 9: return t.calMonth9;
      case 10: return t.calMonth10; case 11: return t.calMonth11; default: return t.calMonth12;
    }
  }

  String _wd(AppLocalizations t, int i) {
    switch (i) {
      case 0: return t.calWd0; case 1: return t.calWd1; case 2: return t.calWd2;
      case 3: return t.calWd3; case 4: return t.calWd4; case 5: return t.calWd5; default: return t.calWd6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.calTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: cTextSecondary),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: cOrange,
        onPressed: _openEditor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(t.calAddEvent, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(children: [
          _viewSwitcher(t),
          _legend(t),
          _filterBar(t),
          Expanded(
            child: _loading
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(color: cOrange),
                    const SizedBox(height: 14),
                    Text(t.calLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
                  ]))
                : RefreshIndicator(
                    color: cOrange, backgroundColor: cCard,
                    onRefresh: _load,
                    child: _viewBody(t),
                  ),
          ),
        ]),
      ),
    );
  }

  // ── Ansichts-Umschalter (Monat / Jahr / Liste) ──
  Widget _viewSwitcher(AppLocalizations t) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
    child: Row(children: [
      _segBtn(t.calViewMonth, _CalView.month),
      _segBtn(t.calViewYear, _CalView.year),
      _segBtn(t.calViewList, _CalView.list),
    ]),
  );

  Widget _segBtn(String label, _CalView v) {
    final sel = _view == v;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _view = v),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: sel ? cOrange : Colors.transparent, borderRadius: BorderRadius.circular(kTileRadius - 2)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: sel ? Colors.white : cTextSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  // ── Farb-Legende ──
  Widget _legend(AppLocalizations t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _legendDot(cOrange, t.calLegendMeetup),
      const SizedBox(width: 18),
      _legendDot(cNostr, t.calLegendEvent),
      const SizedBox(width: 14),
      _legendDot(cCourse, t.calLegendCourse),
    ]),
  );

  Widget _legendDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
  ]);

  // ── Filterleiste: Typ-Umschalter + Ortssuche ──
  Widget _filterBar(AppLocalizations t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Column(children: [
      // Typ-Umschalter
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
        child: Row(children: [
          _typeBtn(t.calFilterAll, 0, cOrange),
          _typeBtn(t.calFilterMeetups, 1, cOrange),
          _typeBtn(t.calFilterExternal, 2, cNostr),
          _typeBtn(t.calFilterCourses, 3, cCourse),
        ]),
      ),
      const SizedBox(height: 8),
      // Ortssuche
      Row(children: [
        Expanded(
          child: TextField(
            controller: _locationCtrl,
            onChanged: (v) { _locationQuery = v; _applyFilter(); },
            style: const TextStyle(color: cText, fontSize: 14),
            decoration: InputDecoration(
              hintText: t.calFilterLocation,
              hintStyle: const TextStyle(color: cTextTertiary, fontSize: 13),
              prefixIcon: const Icon(Icons.place_rounded, color: cTextTertiary, size: 18),
              isDense: true,
              filled: true, fillColor: cCard,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cOrange, width: 1.2)),
            ),
          ),
        ),
        if (_filterActive) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearFilter,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
              child: const Icon(Icons.close_rounded, color: cTextSecondary, size: 18),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      // Community / Weltweit-Umschalter
      GestureDetector(
        onTap: () { setState(() => _worldwide = !_worldwide); _load(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _worldwide ? cNostr.withValues(alpha: 0.12) : cCard,
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: _worldwide ? cNostr.withValues(alpha: 0.5) : cTileBorder, width: _worldwide ? 1 : 0.5),
          ),
          child: Row(children: [
            Icon(_worldwide ? Icons.public_rounded : Icons.groups_rounded,
                color: _worldwide ? cNostr : cOrange, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_worldwide ? t.calWorldwide : t.calCommunityOnly,
                style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w700))),
            Switch(
              value: _worldwide,
              activeTrackColor: cNostr,
              onChanged: (v) { setState(() => _worldwide = v); _load(); },
            ),
          ]),
        ),
      ),
      if (_worldwide)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(t.calWorldwideHint, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
        ),
    ]),
  );

  Widget _typeBtn(String label, int value, Color activeColor) {
    final sel = _typeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _typeFilter = value); _applyFilter(); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(color: sel ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(kTileRadius - 2)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: sel ? Colors.white : cTextSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _viewBody(AppLocalizations t) {
    switch (_view) {
      case _CalView.month: return _monthView(t);
      case _CalView.year:  return _yearView(t);
      case _CalView.list:  return _listView(t);
    }
  }

  // ── MONATSANSICHT ──
  Widget _monthView(AppLocalizations t) {
    final selectedEvents = _eventsOn(_selected);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _monthHeader(t, _focused, () => setState(() => _focused = DateTime(_focused.year, _focused.month - 1)),
            () => setState(() => _focused = DateTime(_focused.year, _focused.month + 1))),
        const SizedBox(height: 12),
        _weekdayRow(t),
        const SizedBox(height: 6),
        _monthGrid(t),
        const SizedBox(height: 20),
        // Events des gewählten Tages
        Row(children: [
          Text('${_selected.day}. ${_monthName(t, _selected.month)}',
              style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (_isToday(_selected))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(t.calToday, style: const TextStyle(color: cOrange, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 10),
        if (selectedEvents.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(t.calNoEvents, style: const TextStyle(color: cTextSecondary, fontSize: 13)))
        else
          ...selectedEvents.map((e) => _eventCard(t, e)),
        const SizedBox(height: 12),
        Center(child: Text(t.calSource, style: const TextStyle(color: cTextTertiary, fontSize: 11))),
      ],
    );
  }

  Widget _monthHeader(AppLocalizations t, DateTime month, VoidCallback onPrev, VoidCallback onNext) => Row(
    children: [
      IconButton(icon: const Icon(Icons.chevron_left_rounded, color: cTextSecondary), onPressed: onPrev),
      Expanded(child: Center(child: Text('${_monthName(t, month.month)} ${month.year}',
          style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w800)))),
      IconButton(icon: const Icon(Icons.chevron_right_rounded, color: cTextSecondary), onPressed: onNext),
    ],
  );

  Widget _weekdayRow(AppLocalizations t) => Row(
    children: List.generate(7, (i) => Expanded(
      child: Center(child: Text(_wd(t, i), style: const TextStyle(color: cTextTertiary, fontSize: 11, fontWeight: FontWeight.w700))),
    )),
  );

  Widget _monthGrid(AppLocalizations t) {
    final first = DateTime(_focused.year, _focused.month, 1);
    // Montag=1 ... Sonntag=7 -> Offset auf Montag-basiertes Grid
    final leading = (first.weekday + 6) % 7;
    final daysInMonth = DateTime(_focused.year, _focused.month + 1, 0).day;
    final cells = <Widget>[];

    for (int i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(_focused.year, _focused.month, d);
      final events = _eventsOn(day);
      final isSel = _sameDay(day, _selected);
      final isToday = _isToday(day);
      cells.add(GestureDetector(
        onTap: () => setState(() => _selected = day),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSel ? cOrange : (isToday ? cOrange.withValues(alpha: 0.12) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: isToday && !isSel ? Border.all(color: cOrange, width: 1) : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$d', style: TextStyle(
              color: isSel ? Colors.white : cText,
              fontSize: 13,
              fontWeight: isSel || isToday ? FontWeight.w800 : FontWeight.w500,
            )),
            const SizedBox(height: 2),
            // Event-Punkte (max 3), eingefärbt nach Typ (orange=Meetup, cyan=Event)
            if (events.isNotEmpty)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (int k = 0; k < (events.length > 3 ? 3 : events.length); k++)
                  Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(color: isSel ? Colors.white : events[k].color, shape: BoxShape.circle)),
              ])
            else
              const SizedBox(height: 4),
          ]),
        ),
      ));
    }

    // In Wochenzeilen zu je 7 aufteilen
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(i, (i + 7 > cells.length) ? cells.length : i + 7);
      while (week.length < 7) {
        week.add(const SizedBox.shrink());
      }
      rows.add(Row(children: week.map((c) => Expanded(child: AspectRatio(aspectRatio: 1, child: c))).toList()));
    }
    return Column(children: rows);
  }

  // ── JAHRESANSICHT ──
  Widget _yearView(AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left_rounded, color: cTextSecondary),
              onPressed: () => setState(() => _focused = DateTime(_focused.year - 1, _focused.month))),
          Expanded(child: Center(child: Text('${_focused.year}',
              style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800)))),
          IconButton(icon: const Icon(Icons.chevron_right_rounded, color: cTextSecondary),
              onPressed: () => setState(() => _focused = DateTime(_focused.year + 1, _focused.month))),
        ]),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: List.generate(12, (i) => _yearMonthCell(t, i + 1)),
        ),
      ],
    );
  }

  Widget _yearMonthCell(AppLocalizations t, int month) {
    // Anzahl Events in diesem Monat
    int count = 0;
    for (final e in _events) {
      if (e.start.year == _focused.year && e.start.month == month) count++;
    }
    return GestureDetector(
      onTap: () => setState(() { _focused = DateTime(_focused.year, month); _view = _CalView.month; }),
      child: Container(
        decoration: BoxDecoration(
          color: cCard, borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: count > 0 ? cOrange.withValues(alpha: 0.4) : cTileBorder, width: 0.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_monthName(t, month), style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w800)),
            )
          else
            Text('–', style: const TextStyle(color: cTextTertiary, fontSize: 12)),
        ]),
      ),
    );
  }

  // ── LISTENANSICHT ──
  Widget _listView(AppLocalizations t) {
    final now = DateTime.now();
    final upcoming = _events.where((e) => e.start.isAfter(now.subtract(const Duration(days: 1)))).toList();
    if (upcoming.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 44),
        const SizedBox(height: 12),
        Center(child: Text(t.calNoEventsRange, style: const TextStyle(color: cTextSecondary, fontSize: 14))),
      ]);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        ...upcoming.map((e) => _eventCard(t, e, showDate: true)),
        const SizedBox(height: 12),
        Center(child: Text(t.calSource, style: const TextStyle(color: cTextTertiary, fontSize: 11))),
      ],
    );
  }

  // ── Event-Karte ──
  Widget _eventCard(AppLocalizations t, _CalItem e, {bool showDate = false}) {
    return GestureDetector(
      onTap: () => _showItemDetails(e),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard, borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
          // Meetup-Wappen (aus der Portal-Registry), falls vorhanden
          Builder(builder: (_) {
            final logo = e.isMeetup ? MeetupCalendarService.logoFor(e.title) : '';
            if (logo.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(logo, width: 26, height: 26, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
            );
          }),
          const SizedBox(width: 8),
          Expanded(child: Text(e.title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700))),
          // Abzeichen "hier gibt es ein Badge" — steht VOR dem Typ-Etikett,
          // weil es die seltenere und damit interessantere Information ist.
          if (e.hasBadge) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: cOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.military_tech_rounded,
                  color: cOrange, size: 13),
            ),
            const SizedBox(width: 6),
          ],
          // Typ-Badge (Meetup = orange, Veranstaltung = cyan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: e.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(e.isMeetup ? t.calTypeMeetup : t.calTypeEvent,
                style: TextStyle(color: e.color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        // Badge-Bild als schmales Band. Bewusst niedrig: Die Liste soll
        // uebersichtlich bleiben, das Bild ist Wiedererkennung, nicht Inhalt.
        if (e.badgeImage.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              e.badgeImage,
              height: 84,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.schedule_rounded, color: cTextTertiary, size: 13),
          const SizedBox(width: 5),
          Text(_fmtWhen(t, e, showDate), style: const TextStyle(color: cTextSecondary, fontSize: 12)),
        ]),
        if (e.location.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.place_rounded, color: cTextTertiary, size: 13),
            const SizedBox(width: 5),
            Expanded(child: Text(e.location, style: const TextStyle(color: cTextSecondary, fontSize: 12))),
          ]),
        ],
        if (e.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(e.description, maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
        ],
      ]),
      ),
    );
  }

  /// DETAIL-ANSICHT: Antippen einer Veranstaltung öffnet ein Sheet mit
  /// vollständiger Beschreibung, Ort, Zeit und KLICKBAREN Links.
  void _showItemDetails(_CalItem e) {
    final t = AppLocalizations.of(context);
    // URLs aus Beschreibung + Ort extrahieren (klickbar anbieten)
    final linkRegex = RegExp(r'https?://[^\s\)\]>,]+');
    final links = <String>{
      ...linkRegex.allMatches('${e.description} ${e.location}').map((m) => m.group(0)!),
    }.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      // StatefulBuilder um das Blatt: Es haengt in einer EIGENEN Route und
      // zeichnet sich NICHT neu, wenn der Kalender setState aufruft. Deshalb
      // faerbte sich "Ich komme" erst, wenn man das Blatt schloss und wieder
      // oeffnete — die Zusage war laengst gespeichert, nur sah man es nicht.
      builder: (_) => StatefulBuilder(
        builder: (_, setSheet) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.55, maxChildSize: 0.9, minChildSize: 0.35,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: cTileBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(e.title, style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: e.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
                child: Text(e.isCourse ? t.calLegendCourse : (e.isMeetup ? t.calLegendMeetup : t.calLegendEvent),
                    style: TextStyle(color: e.color, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.schedule_rounded, color: cTextTertiary, size: 15),
              const SizedBox(width: 7),
              Text(_fmtWhen(t, e, true), style: const TextStyle(color: cTextSecondary, fontSize: 13)),
            ]),
            if (e.location.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.place_rounded, color: cTextTertiary, size: 15),
                const SizedBox(width: 7),
                Expanded(child: Text(e.location, style: const TextStyle(color: cTextSecondary, fontSize: 13))),
              ]),
            ],
            if (e.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(e.description, style: const TextStyle(color: cText, fontSize: 14, height: 1.5)),
            ],
            if (e.hasBadge) ...[
              const SizedBox(height: 16),
              _badgeNotice(t, e),
            ],
            // Zu- oder Absagen. Nur bei Nostr-Terminen, weil die Antwort
            // als NIP-52-Ereignis an der Termin-Adresse haengt — Portal-
            // Meetups haben keine.
            if (e.nostr != null) ...[
              const SizedBox(height: 14),
              _rsvpRow(t, e.nostr!, setSheet),
            ],
            // Chat zum Termin. Nur fuer Nostr-Termine: Portal-Meetups haben
            // ihren eigenen Meetup-Raum, ein zweiter Raum daneben wuerde die
            // Unterhaltung nur aufteilen.
            if (e.nostr != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openEventChat(e),
                  icon: const Icon(Icons.forum_rounded,
                      color: cNostr, size: 18),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cNostr.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  label: Text(t.chatEventOpen,
                      style: const TextStyle(color: cNostr, fontSize: 13)),
                ),
              ),
            ],
            if (links.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final url in links)
                GestureDetector(
                  onTap: () async {
                    try { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } catch (_) {}
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: cOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cOrange.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.link_rounded, color: cOrange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: cOrange, fontSize: 13, fontWeight: FontWeight.w600))),
                      const Icon(Icons.open_in_new_rounded, color: cOrange, size: 14),
                    ]),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                cal.Add2Calendar.addEvent2Cal(cal.Event(
                  title: e.title,
                  description: e.description,
                  location: e.location,
                  startDate: e.start,
                  endDate: e.end ?? e.start.add(const Duration(hours: 2)),
                  allDay: e.allDay,
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(11), border: Border.all(color: cTileBorder, width: 0.5)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.event_available_rounded, color: cTextSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text(t.evToCalendar, style: const TextStyle(color: cText, fontSize: 13.5, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
      ),
      ),
    );
  }

  String _fmtWhen(AppLocalizations t, _CalItem e, bool showDate) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = e.start;
    final datePart = showDate ? '${d.day}. ${_monthName(t, d.month)} ${d.year}' : '';
    if (e.allDay) {
      return showDate ? '$datePart · ${t.calAllDay}' : t.calAllDay;
    }
    final time = '${two(d.hour)}:${two(d.minute)}';
    return showDate ? '$datePart · $time' : time;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isToday(DateTime d) => _sameDay(d, DateTime.now());

  Future<void> _openEditor() async {
    final published = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const EventEditorScreen()),
    );
    if (published == true && mounted) {
      _load(); // neu laden, damit das eigene Event erscheint
    }
  }
}

// ============================================
//  EVENT-EDITOR (eintragen + bei Nostr publishen)
// ============================================
class EventEditorScreen extends StatefulWidget {
  const EventEditorScreen({super.key});

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen>
    with GuideServiceHost {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _allDay = false;
  DateTime? _start;
  DateTime? _end;
  bool _publishing = false;

  // --- Event-Badge ---
  final _imageCtrl = TextEditingController();
  bool _badgeEnabled = false;
  double _lat = 0;
  double _lng = 0;
  bool _uploading = false;

  /// Ein Eingabefeld je Helfer. Bewusst Felder statt einer festen Liste:
  /// Ein eingefuegter npub laesst sich so noch korrigieren, ohne ihn erst
  /// loeschen und neu einfuegen zu muessen. Die erste Zeile steht von
  /// Anfang an da, damit sichtbar ist, worum es geht.
  final List<TextEditingController> _issuerCtrls = [TextEditingController()];

  /// null = wird noch geprueft. Jeder darf Events anlegen; das Badge daran
  /// ist an die Berechtigung gebunden.
  EventBadgeRight? _right;

  @override
  void initState() {
    super.initState();
    _checkRight();
  }

  Future<void> _checkRight() async {
    final right = await EventBadgeAuthService.myRight();
    if (!mounted) return;
    setState(() => _right = right);

    // Die Tour laeuft fuer JEDEN — Titel, Ort und Zeitraum betreffen alle.
    // Nur der Badge-Teil haengt an der Berechtigung: Wer den Schalter nicht
    // bedienen kann, bekommt die drei Schritte dazu gar nicht erst zu
    // sehen. Deshalb wird erst hier gestartet, wenn die Pruefung durch ist.
    final guide = this.guide;
    if (await guide.wasTourCompleted(GuideTour.events)) return;
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await guide.startTour(
      GuideTour.events,
      EventBadgeTour.steps(mayCreateBadge: right != EventBadgeRight.none),
    );
  }

  bool get _mayCreateBadge =>
      _right != null && _right != EventBadgeRight.none;

  @override
  void dispose() {
    // Editor zu, Tour raus: Sonst suchte das Overlay Ziele in einem Blatt,
    // das nicht mehr existiert.
    finishGuideTourIfActive(GuideTour.events);

    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    for (final c in _issuerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  /// Wandelt eine Eingabezeile in einen Hex-Pubkey.
  ///
  /// Nimmt npub UND Hex — beim Kopieren aus verschiedenen Quellen bekommt
  /// man mal das eine, mal das andere. Gibt null zurueck, wenn nichts
  /// Verwertbares drinsteht.
  String? _toHex(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('npub1')) {
      try {
        final hex = NostrService.npubToHex(s);
        return hex.length == 64 ? hex.toLowerCase() : null;
      } catch (_) {
        return null;
      }
    }
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(s)) return s.toLowerCase();
    return null;
  }

  /// Alle gueltigen Aussteller, ohne Doppelte und ohne leere Zeilen.
  List<String> get _issuerHexes {
    final out = <String>[];
    for (final c in _issuerCtrls) {
      final hex = _toHex(c.text);
      if (hex != null && !out.contains(hex)) out.add(hex);
    }
    return out;
  }

  /// Steht in dieser Zeile etwas, das kein npub ist? Nur dann wird gemeckert —
  /// eine leere Zeile ist kein Fehler, sondern ein Angebot.
  bool _rowInvalid(TextEditingController c) =>
      c.text.trim().isNotEmpty && _toHex(c.text) == null;

  void _addIssuerRow() {
    setState(() => _issuerCtrls.add(TextEditingController()));
  }

  void _removeIssuerRow(int index) {
    setState(() {
      _issuerCtrls[index].dispose();
      _issuerCtrls.removeAt(index);
      // Nie ganz ohne Zeile dastehen — sonst waere der Abschnitt leer und
      // niemand wuesste, wie man wieder eine bekommt.
      if (_issuerCtrls.isEmpty) _issuerCtrls.add(TextEditingController());
    });
  }

  /// Ort des Events auf der Karte waehlen.
  Future<void> _pickLocation() async {
    final picked = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: _lat != 0 ? _lat : null,
          initialLng: _lng != 0 ? _lng : null,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _lat = picked.latitude as double;
      _lng = picked.longitude as double;
    });
  }

  /// Bild aus der Galerie waehlen und hochladen.
  ///
  /// Der Upload ist keine Bequemlichkeit, sondern Pflicht: Im Kalender-Event
  /// steht eine URL, die JEDER laden koennen muss. Ein Galeriepfad waere auf
  /// jedem anderen Geraet wertlos.
  Future<void> _pickImage() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;

      setState(() => _uploading = true);
      final res = await BlossomUploadService.uploadImage(image.path);
      if (!mounted) return;
      setState(() => _uploading = false);

      if (res.ok) {
        setState(() => _imageCtrl.text = res.url!);
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(t.evBadgeUploadFailed(res.error ?? '')),
          backgroundColor: cRed,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      messenger.showSnackBar(SnackBar(
        content: Text(t.evBadgeUploadFailed(e.toString())),
        backgroundColor: cRed,
      ));
    }
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(_end ?? _start);
    if (picked != null) setState(() => _end = picked);
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null) return null;
    if (_allDay) {
      return DateTime(date.year, date.month, date.day);
    }
    if (!mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    return DateTime(date.year, date.month, date.day, time?.hour ?? 19, time?.minute ?? 0);
  }

  Future<void> _publish() async {
    final t = AppLocalizations.of(context);
    if (_titleCtrl.text.trim().isEmpty) { _snack(t.calNeedTitle, cRed); return; }
    if (_start == null) { _snack(t.calNeedStart, cRed); return; }

    // Badge OHNE Koordinaten geht nicht — und das muss HIER auffallen.
    //
    // Die Ausgabe prueft den Abstand zum Veranstaltungsort; fehlt der Punkt,
    // laesst sich keine Session starten. Bisher merkte man das erst am Tag
    // des Events, vor Ort, mit wartenden Leuten: Der Termin liess sich mit
    // Badge anlegen, und der Knopf verweigerte dann die Auskunft "kein Ort
    // hinterlegt". Es ist kein Sicherheitsloch — aber ein Fehler, der zum
    // denkbar schlechtesten Zeitpunkt sichtbar wurde.
    if (_badgeEnabled && _mayCreateBadge && _lat == 0 && _lng == 0) {
      _snack(t.evBadgeNeedLocation, cRed);
      return;
    }

    setState(() => _publishing = true);
    // Badge nur mitsenden, wenn es angehakt UND erlaubt ist. Die zweite
    // Bedingung ist kein Zierrat: Der Schalter koennte durch einen spaeteren
    // Umbau erreichbar werden, ohne dass die Pruefung noch greift.
    final withBadge = _badgeEnabled && _mayCreateBadge;

    final count = await CalendarEventService.publishEvent(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      start: _start!,
      end: _end,
      allDay: _allDay,
      badgeEnabled: withBadge,
      badgeImageUrl: withBadge ? _imageCtrl.text.trim() : '',
      lat: withBadge ? _lat : 0,
      lng: withBadge ? _lng : 0,
      issuers: withBadge ? _issuerHexes : const [],
    );
    if (!mounted) return;
    setState(() => _publishing = false);
    if (count > 0) {
      Navigator.pop(context, true);
    } else {
      _snack(t.calPublishFail, cRed);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  String _fmt(DateTime? d, AppLocalizations t) {
    if (d == null) return _allDay ? t.calPickDate : t.calPickDateTime;
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(d.day)}.${two(d.month)}.${d.year}';
    return _allDay ? date : '$date  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.calNewEventTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            KeyedSubtree(
              key: EventBadgeTour.basicsKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(t.calFieldTitle),
                    _input(_titleCtrl, t.calFieldTitleHint),
                    const SizedBox(height: 16),
                    _label(t.calFieldLocation),
                    _input(_locationCtrl, t.calFieldLocationHint),
                  ]),
            ),
            const SizedBox(height: 16),
            // Ganztägig-Schalter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
              child: Row(children: [
                const Icon(Icons.event_available_rounded, color: cTextSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(t.calFieldAllDay, style: const TextStyle(color: cText, fontSize: 14))),
                Switch(
                  value: _allDay,
                  activeTrackColor: cOrange,
                  onChanged: (v) => setState(() {
                    _allDay = v;
                    // bei Umschaltung Zeiten zurücksetzen, um Inkonsistenz zu vermeiden
                    _start = null; _end = null;
                  }),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: EventBadgeTour.whenWhereKey,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(t.calFieldStart),
                    _dateButton(_fmt(_start, t), _start != null, _pickStart),
                    const SizedBox(height: 16),
                    _label(t.calFieldEnd),
                    _dateButton(_fmt(_end, t), _end != null, _pickEnd),
                  ]),
            ),
            if (_end != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => setState(() => _end = null),
                    child: Text(t.calClearEnd, style: const TextStyle(color: cTextSecondary, fontSize: 12))),
              ),
            const SizedBox(height: 16),
            _label(t.calFieldDescription),
            _input(_descCtrl, t.calFieldDescriptionHint, maxLines: 4),
            const SizedBox(height: 16),
            _badgeSection(t),
            const SizedBox(height: 16),
            // Hinweis: öffentlich bei Nostr
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cNostr.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cNostr.withValues(alpha: 0.3), width: 0.5)),
              child: Row(children: [
                const Icon(Icons.public_rounded, color: cNostr, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(t.calPublishInfo, style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.45))),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _publishing ? null : _publish,
                icon: _publishing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: Text(_publishing ? t.calPublishing : t.calPublish,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(backgroundColor: cOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius))),
              ),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  /// Der gesamte Event-Badge-Abschnitt.
  ///
  /// Sichtbar fuer alle — auch fuer Leute ohne Berechtigung. Einen Bereich
  /// ganz zu verstecken laesst niemanden verstehen, dass es ihn gibt; ein
  /// gesperrter Schalter mit Begruendung schon.
  Widget _badgeSection(AppLocalizations t) {
    final may = _mayCreateBadge;
    final checking = _right == null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(
            color: _badgeEnabled ? cOrange.withValues(alpha: 0.5) : cTileBorder,
            width: _badgeEnabled ? 1 : 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.military_tech_rounded,
              color: may ? cOrange : cTextTertiary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.evBadgeCreate,
                  style: TextStyle(
                      color: may ? cText : cTextTertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                checking
                    ? t.evBadgeChecking
                    : (may ? t.evBadgeCreateSub : t.evBadgeNotAllowed),
                style: const TextStyle(
                    color: cTextTertiary, fontSize: 11.5, height: 1.4),
              ),
            ]),
          ),
          KeyedSubtree(
            key: EventBadgeTour.switchKey,
            child: Switch(
              value: _badgeEnabled,
              activeTrackColor: cOrange,
              onChanged: may ? (v) => setState(() => _badgeEnabled = v) : null,
            ),
          ),
        ]),

        if (_badgeEnabled) ...[
          const SizedBox(height: 18),
          KeyedSubtree(
              key: EventBadgeTour.imageKey, child: _label(t.evBadgeImage)),
          Row(children: [
            Expanded(child: _input(_imageCtrl, t.evBadgeImageHint)),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _uploading ? null : _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  disabledBackgroundColor: cSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kTileRadius)),
                ),
                child: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cOrange))
                    : const Icon(Icons.photo_library_rounded,
                        color: Colors.black, size: 20),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(_uploading ? t.evBadgeUploading : t.evBadgeImageInfo,
              style: const TextStyle(
                  color: cTextTertiary, fontSize: 11, height: 1.4)),

          if (_imageCtrl.text.trim().startsWith('http')) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(kTileRadius),
              child: Image.network(
                _imageCtrl.text.trim(),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                // Kaputte URL: lieber gar nichts als ein Fehlersymbol.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],

          const SizedBox(height: 16),
          KeyedSubtree(
              key: EventBadgeTour.locationKey,
              child: _label(t.evBadgeLocation)),
          GestureDetector(
            onTap: _pickLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(kTileRadius),
                border: Border.all(
                    color: (_lat != 0 || _lng != 0) ? cOrange : cTileBorder,
                    width: (_lat != 0 || _lng != 0) ? 1 : 0.5),
              ),
              child: Row(children: [
                Icon(Icons.map_rounded,
                    color: (_lat != 0 || _lng != 0) ? cOrange : cTextTertiary,
                    size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (_lat != 0 || _lng != 0)
                        ? '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}'
                        : t.evBadgeLocationPick,
                    style: TextStyle(
                        color: (_lat != 0 || _lng != 0) ? cText : cTextTertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                if (_lat != 0 || _lng != 0)
                  GestureDetector(
                    onTap: () => setState(() { _lat = 0; _lng = 0; }),
                    child: const Icon(Icons.close_rounded,
                        color: cTextTertiary, size: 18),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: cTextTertiary, size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Text(t.evBadgeLocationInfo,
              style: const TextStyle(
                  color: cTextTertiary, fontSize: 11, height: 1.4)),

          const SizedBox(height: 16),
          KeyedSubtree(
              key: EventBadgeTour.issuersKey,
              child: _label(t.evBadgeIssuers)),
          for (int i = 0; i < _issuerCtrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                  child: _input(_issuerCtrls[i], t.evBadgeIssuerHint,
                      onChanged: (_) => setState(() {}),
                      borderColor: _rowInvalid(_issuerCtrls[i]) ? cRed : null),
                ),
                const SizedBox(width: 10),
                // Nur die LETZTE Zeile traegt das Plus, alle anderen den
                // Papierkorb. Zwei Knoepfe pro Zeile waeren doppelt so viel
                // zum Zielen und halb so klar.
                SizedBox(
                  height: 48,
                  width: 48,
                  child: i == _issuerCtrls.length - 1
                      ? ElevatedButton(
                          onPressed: _addIssuerRow,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: cOrange,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(kTileRadius)),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.black),
                        )
                      : ElevatedButton(
                          onPressed: () => _removeIssuerRow(i),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: cSurface,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(kTileRadius)),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: cRed),
                        ),
                ),
              ]),
            ),
          Text(t.evBadgeIssuerInfo,
              style: const TextStyle(
                  color: cTextTertiary, fontSize: 11, height: 1.4)),
        ],
      ]),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(), style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
  );

  Widget _dateButton(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: active ? cOrange : cTileBorder, width: active ? 1 : 0.5)),
      child: Row(children: [
        Icon(Icons.event_rounded, color: active ? cOrange : cTextTertiary, size: 18),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: active ? cText : cTextTertiary, fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  /// [onChanged] und [borderColor] sind fuer die Aussteller-Zeilen dazu-
  /// gekommen: Sie faerben sich rot, sobald etwas drinsteht, das kein npub
  /// ist — waehrend des Tippens, nicht erst beim Veroeffentlichen.
  Widget _input(TextEditingController c, String hint,
          {int maxLines = 1, ValueChanged<String>? onChanged, Color? borderColor}) =>
      TextField(
    controller: c,
    maxLines: maxLines,
    onChanged: onChanged,
    style: const TextStyle(color: cText, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: cTextTertiary, fontSize: 14),
      filled: true, fillColor: cCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: BorderSide(color: borderColor ?? cTileBorder, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: BorderSide(color: borderColor ?? cTileBorder, width: borderColor != null ? 1 : 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: BorderSide(color: borderColor ?? cOrange, width: 1.5)),
    ),
  );
}
