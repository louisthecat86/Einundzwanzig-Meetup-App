import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import '../services/meetup_calendar_service.dart';
import '../services/meetup_service.dart';
import '../services/meetup_event_matcher.dart';
import '../services/portal_api_service.dart';
import '../models/calendar_event.dart';
import '../models/meetup.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/event_details_sheet.dart';

class CalendarScreen extends StatefulWidget {
  // Wir erlauben einen optionalen Suchbegriff beim Start (z.B. vom Dashboard kommend)
  final String? initialSearch;
  final String? initialMeetupId;

  const CalendarScreen({super.key, this.initialSearch, this.initialMeetupId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Stored favorites: portal IDs, or city names from older app versions.
  Set<String> _favCities = {};

  final MeetupCalendarService _calendarService = MeetupCalendarService();
  
  List<CalendarEvent> _allEvents = [];  // Alle geladenen Events
  List<CalendarEvent> _filteredEvents = []; // Die aktuell angezeigten Events
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // WAPPEN: Meetups aus dem Portal (mit logoUrl) + Zuordnungs-Cache
  List<Meetup> _meetups = [];
  final Map<String, Meetup?> _crestCache = {};

  // PORTAL-MODUS: Termine direkt aus dem Portal (exakte Meetup-Zuordnung).
  // _eventLogo = Wappen-URL je Termin, _eventPortalId = Event-ID (für RSVP).
  final Map<CalendarEvent, String> _eventLogo = {};
  final Map<CalendarEvent, int> _eventPortalId = {};
  final Map<int, Map<String, dynamic>> _rsvp = {};
  final Set<int> _rsvpBusy = {};
  // Teilnehmerlisten-Aufklappung: welches Event ist offen + geladene Namen.
  final Set<int> _attendeesExpanded = {};
  final Map<int, List<Map<String, String>>> _attendees = {};
  final Set<int> _attendeesLoading = {};

  void _loadEvents() async {
    // 1) PORTAL ZUERST: /api/meetup-events liefert jeden Termin MIT seinem
    //    Meetup (Name + Wappen-URL) -> exakte Zuordnung, RSVP möglich.
    try {
      final portal = await PortalApiService.getAllMeetupEvents();
      if (portal.isNotEmpty) {
        final cutoff = DateTime.now().subtract(const Duration(hours: 6));
        final events = <CalendarEvent>[];
        _eventLogo.clear(); _eventPortalId.clear();
        for (final e in portal) {
          final start = MeetupCalendarService.portalStart((e['start'] ?? '').toString());
          if (start == null || start.isBefore(cutoff)) continue;
          // Meetup-Felder sind FLACH mit Punkt-Schlüsseln ("meetup.name")
          String mv(String key) {
            final nested = e['meetup'];
            if (nested is Map && nested[key] != null) return nested[key].toString();
            final flat = e['meetup.$key'];
            return flat == null ? '' : flat.toString();
          }
          final name = mv('name').trim().isNotEmpty ? mv('name').trim() : 'Meetup';
          final link = (e['link'] ?? '').toString();
          final ev = CalendarEvent(
            title: name,
            description: (e['description'] ?? '').toString(),
            location: (e['location'] ?? '').toString(),
            startTime: start,
            url: link.isNotEmpty ? link : mv('portalLink'),
            meetupId: mv('id'),
            meetupPortalLink: mv('portalLink'),
            portalEventId: e['id'] is int ? e['id'] as int : null,
          );
          events.add(ev);
          final logo = mv('logo');
          if (logo.isNotEmpty) _eventLogo[ev] = logo;
          if (e['id'] is int) { _eventPortalId[ev] = e['id'] as int; _rsvp[e['id'] as int] = {'count': (e['attendees'] is int) ? e['attendees'] : 0, 'might': (e['might_attendees'] is int) ? e['might_attendees'] : 0}; }
        }
        if (events.isNotEmpty) {
          events.sort((a, b) => a.startTime.compareTo(b.startTime));
          if (mounted) {
            setState(() { _allEvents = events; _isLoading = false; _filterEvents(); });
          }
          _loadRsvpStatuses();
          return;
        }
      }
    } catch (_) {/* Portal nicht erreichbar -> iCal-Fallback */}

    // 2) FALLBACK: iCal-Feed wie bisher (Wappen dann per Stadtnamen-Matching)
    final events = await _calendarService.fetchMeetups();
    if (mounted) {
      setState(() {
        _allEvents = events;
        _isLoading = false;
        _filterEvents(); // Direkt filtern nach dem Laden
      });
    }
  }

  /// RSVP-Status der ersten 25 sichtbaren Portal-Termine nachladen (sparsam).
  void _loadRsvpStatuses() async {
    // INSTANT für sichtbare Termine: die ersten ~12 (das, was auf den Schirm
    // passt) werden SOFORT und gebündelt geladen -> "Du hast zugesagt"
    // erscheint praktisch ohne Verzögerung. Der Rest lädt danach im
    // Hintergrund nach (für Scrollen weiter unten).
    final ids = _eventPortalId.values.toList();
    if (ids.isEmpty) return;

    Future<void> load(Iterable<int> batch) async {
      await Future.wait(batch.map((id) async {
        final r = await PortalApiService.getRsvpCached(id);
        if (mounted && r != null) setState(() => _rsvp[id] = {...?_rsvp[id], ...r});
      }));
    }

    // 1) Sofort: erste 12 (sichtbarer Bereich) – alle gleichzeitig
    final visible = ids.take(12).toList();
    await load(visible);
    if (!mounted) return;

    // 2) Hintergrund: der Rest in 20er-Wellen
    final rest = ids.skip(12).toList();
    for (var i = 0; i < rest.length; i += 20) {
      await load(rest.skip(i).take(20));
      if (!mounted) return;
    }
  }

  /// Stellt sicher, dass eine gültige Portal-Verbindung besteht: löst bei
  /// Bedarf DIREKT den Nostr-Login aus (Amber/nsec) — ohne separaten Screen.
  /// Gibt true zurück, wenn danach verbunden. Zeigt dezenten Fortschritt.
  Future<bool> _ensurePortalLogin() async {
    final t = AppLocalizations.of(context);
    // Messenger zusammen mit den Uebersetzungen vor dem ersten await
    // greifen — danach steht der Context nicht mehr zwingend.
    final messenger = ScaffoldMessenger.of(context);
    if (await PortalApiService.tokenMatchesCurrentKey()) return true;
    messenger.showSnackBar(SnackBar(
        content: Text(t.portalConnecting), backgroundColor: cCard,
        duration: const Duration(seconds: 8), behavior: SnackBarBehavior.floating));
    final res = await PortalApiService.loginWithNostr();
    if (!mounted) return false;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (res.ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.portalConnected), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating));
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${t.portalLoginFailed}: ${res.error ?? ''}'), backgroundColor: cRed, behavior: SnackBarBehavior.floating));
    return false;
  }

  Future<void> _doRsvp(int id, {String status = 'attending'}) async {
    final t = AppLocalizations.of(context);
    // Nicht verbunden? -> DIREKT verbinden (statt roter Fehlermeldung).
    if (!await PortalApiService.tokenMatchesCurrentKey()) {
      final ok = await _ensurePortalLogin();
      if (!ok) return; // abgebrochen/fehlgeschlagen
    }
    setState(() => _rsvpBusy.add(id));
    final res = await PortalApiService.rsvp(id, status: status);
    if (!mounted) return;
    setState(() => _rsvpBusy.remove(id));
    if (res.ok) {
      // Status lokal SOFORT setzen (nicht auf getRsvp warten/verlassen) —
      // so bleibt "Du hast zugesagt" auch nach Verlassen/Rückkehr korrekt.
      setState(() => _rsvp[id] = {...?_rsvp[id], 'status': status});
      // Frisch laden UND den Cache aktualisieren (forceRefresh), damit die
      // eigene Zusage sofort auch im 1h-Cache steht.
      final r = await PortalApiService.getRsvpCached(id, forceRefresh: true);
      if (mounted && r != null) setState(() => _rsvp[id] = {...?_rsvp[id], ...r});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${t.rsvpFailed}: ${res.error ?? ''}'), backgroundColor: cRed, behavior: SnackBarBehavior.floating));
    }
  }

  bool _isGoing(Map<String, dynamic>? r) {
    if (r == null) return false;
    final st = (r['status'] ?? '').toString();
    if (st == 'attending' || st == 'maybe') return true;
    final v = r['going'] ?? r['is_going'] ?? r['rsvped'];
    return v == true;
  }

  int _rsvpCount(Map<String, dynamic>? r) {
    if (r == null) return -1;
    final v = r['attendees'] ?? r['count'] ?? r['total'] ?? r['rsvps'];
    return (v is int) ? v : -1;
  }

  /// Lädt die Teilnehmernamen für ein Event (einmalig) und klappt auf/zu.
  Future<void> _toggleAttendees(int id) async {
    if (_attendeesExpanded.contains(id)) {
      setState(() => _attendeesExpanded.remove(id));
      return;
    }
    setState(() => _attendeesExpanded.add(id));
    if (!_attendees.containsKey(id)) {
      setState(() => _attendeesLoading.add(id));
      final list = await PortalApiService.getRsvpAttendees(id);
      if (mounted) {
        setState(() {
          _attendees[id] = list;
          _attendeesLoading.remove(id);
        });
      }
    }
  }

  /// Zusagen-Zeile unter dem Termin (nur im Portal-Modus verfügbar).
  Widget _rsvpRow(CalendarEvent event) {
    final id = _eventPortalId[event];
    if (id == null) return const SizedBox.shrink();
    final t = AppLocalizations.of(context);
    final r = _rsvp[id];
    final going = _isGoing(r);
    final count = _rsvpCount(r);
    final expanded = _attendeesExpanded.contains(id);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        if (count >= 0)
          // Antippbar: klappt die Teilnehmerliste auf/zu.
          GestureDetector(
            onTap: count > 0 ? () => _toggleAttendees(id) : null,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('$count ${t.rsvpCount}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: Colors.grey, size: 16),
              ],
            ]),
          ),
        const Spacer(),
        going
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Text(t.rsvpYouGo, style: const TextStyle(color: cGreen, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _rsvpBusy.contains(id) ? null : () => _doRsvp(id, status: 'none'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cRed.withValues(alpha: 0.6), width: 1),
                    ),
                    child: _rsvpBusy.contains(id)
                        ? const SizedBox(width: 12, height: 12,
                            child: CircularProgressIndicator(color: cRed, strokeWidth: 2))
                        : Text(t.rsvpCancel, style: const TextStyle(color: cRed, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ])
            : SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: _rsvpBusy.contains(id) ? null : () => _doRsvp(id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cGreen, width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  child: _rsvpBusy.contains(id)
                      ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(color: cGreen, strokeWidth: 2))
                      : Text(t.rsvpGoing, style: const TextStyle(color: cGreen, fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
      ]),
    ),
    // Aufgeklappte Teilnehmerliste
    if (expanded) _attendeesList(id, t),
    ]);
  }

  /// Die aufgeklappte Liste der Zusagenden (Nickname + gekürzter npub).
  Widget _attendeesList(int id, AppLocalizations t) {
    final loading = _attendeesLoading.contains(id);
    final list = _attendees[id] ?? [];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: loading
          ? const Center(child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: cOrange, strokeWidth: 2)),
            ))
          : list.isEmpty
              // Portal liefert (noch) keine Namen -> ehrlicher Hinweis.
              ? Text(t.rsvpNoNames, style: const TextStyle(color: cTextTertiary, fontSize: 12))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final a in list) Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(
                        width: 26, height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cOrange.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          (a['name']?.isNotEmpty == true ? a['name']![0] : '?').toUpperCase(),
                          style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          a['name']?.isNotEmpty == true ? a['name']! : t.rsvpAnon,
                          style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        if (a['npub']?.isNotEmpty == true)
                          Text(
                            _shortNpub(a['npub']!),
                            style: const TextStyle(color: cTextTertiary, fontSize: 10).copyWith(fontFamily: fontMono),
                          ),
                      ])),
                    ]),
                  ),
                ]),
    );
  }

  /// Kürzt einen npub für die Anzeige (npub1abc…xyz).
  String _shortNpub(String npub) {
    if (npub.length <= 16) return npub;
    return '${npub.substring(0, 10)}…${npub.substring(npub.length - 6)}';
  }


  Future<void> _loadFavs() async {
    final u = await UserProfile.load();
    await MeetupService.fetchMeetups();
    if (!mounted) return;
    setState(() {
      _favCities = u.favoriteMeetupIds.toSet();
    });
    _filterEvents();
  }

  Future<void> _toggleFav(String favKey) async {
    final u = await UserProfile.load();
    final favs = List<String>.from(u.favoriteMeetupIds);
    bool sameMeetup(String key) => key == favKey ||
        MeetupService.resolveFavorite(key)?.id == favKey;
    final added = !favs.any(sameMeetup);
    if (added) { favs.add(favKey); } else { favs.removeWhere(sameMeetup); }
    u.favoriteMeetupIds = favs;
    u.homeMeetupId = favs.isNotEmpty ? favs.first : '';
    await u.save();
    if (!mounted) return;
    setState(() => _favCities = favs.toSet());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: added ? Colors.green : cSurface,
      duration: const Duration(seconds: 2),
      // Fuer die Meldung den lesbaren Namen, nicht die Portal-ID: "Favorit
      // hinzugefuegt: 4711" waere fuer niemanden eine Auskunft.
      content: Text(added
          ? AppLocalizations.of(context).calFavAdded(MeetupService.labelFor(favKey))
          : AppLocalizations.of(context).calFavRemoved(MeetupService.labelFor(favKey))),
    ));
  }

  @override
  void initState() {
    super.initState();
    _loadFavs();
    // Wenn ein Suchbegriff übergeben wurde (z.B. "Landau"), tragen wir ihn ein
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    _loadEvents();
    _loadMeetupCrests();
  }

  /// Lädt die Portal-Meetups (enthalten die Wappen/Logos) parallel zur
  /// Terminliste. Schlägt das fehl, zeigen wir einfach das Fallback-Icon.
  void _loadMeetupCrests() async {
    final meetups = await MeetupService.fetchMeetups();
    if (mounted && meetups.isNotEmpty) {
      setState(() { _meetups = meetups; _crestCache.clear(); });
    }
  }

  /// Ordnet einem Termin das passende Meetup zu (Stadtname im Titel/Ort).
  /// Bei mehreren Treffern gewinnt der LÄNGSTE Stadtname (verhindert, dass
  /// z.B. "Au" fälschlich vor "Aschaffenburg" matcht). Ergebnis wird gecacht.
  Meetup? _matchMeetup(CalendarEvent event) {
    final key = '${event.title}|${event.location}';
    if (_crestCache.containsKey(key)) return _crestCache[key];
    final hay = '${event.title} ${event.location}'.toLowerCase();
    Meetup? best;
    for (final m in _meetups) {
      final city = m.city.trim().toLowerCase();
      if (city.length < 3) continue;
      if (hay.contains(city)) {
        if (best == null || city.length > best.city.trim().length) best = m;
      }
    }
    _crestCache[key] = best;
    return best;
  }

  /// Rundes Meetup-Wappen. Im Portal-Modus exakt (Logo hängt am Termin),
  /// im iCal-Fallback per Stadtnamen-Matching. Fallback: Icon.
  Widget _crest(CalendarEvent event) {
    String url = _eventLogo[event] ?? '';
    if (url.isEmpty) {
      final m = _matchMeetup(event);
      url = m == null ? '' : (m.logoUrl.isNotEmpty ? m.logoUrl : m.coverImagePath);
    }
    final fallback = Container(
      width: 42, height: 42,
      decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: cOrange.withValues(alpha: 0.25))),
      child: const Icon(Icons.groups_rounded, color: cOrange, size: 20),
    );
    if (url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Image.network(
        url, width: 42, height: 42, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  // Diese Funktion filtert die Liste basierend auf dem Suchtext
  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        // Keep the Home meetup selection exact until the user edits the search.
        if (widget.initialMeetupId != null &&
            query == (widget.initialSearch ?? '').toLowerCase()) {
          return MeetupEventMatcher.resolve(event, MeetupService.cached)?.id ==
              widget.initialMeetupId;
        }
        final title = event.title.toLowerCase();
        final location = event.location.toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();
    });
  }

  // Hilfsfunktion für führende Nullen (z.B. 19:05 statt 19:5)
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // Zeigt Details in einem schönen "Bottom Sheet" statt der hässlichen Box
  void _showEventDetails(CalendarEvent event) {
    final t = AppLocalizations.of(context);
    final id = _eventPortalId[event];
    String two(int n) => n.toString().padLeft(2, '0');
    final d = event.startTime;
    final when = '${two(d.day)}.${two(d.month)}.${d.year} · ${two(d.hour)}:${two(d.minute)}';
    showModalBottomSheet(
      context: context, backgroundColor: cCard, isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        final r = id == null ? null : _rsvp[id];
        final st = (r?['status'] ?? '').toString();
        final count = _rsvpCount(r);
        final might = (r?['might'] ?? r?['might_attendees']) is int ? (r?['might'] ?? r?['might_attendees']) as int : -1;
        // WICHTIG (UX-Fix): Der Portal-Roundtrip dauert mehrere Sekunden.
        // Ohne sichtbares Feedback drücken Nutzer mehrfach auf den Button.
        // Das Sheet rendert den busy-Zustand des Screens (_rsvpBusy) nicht
        // automatisch — deshalb hier ein EIGENER Busy-Zustand, der über
        // setSheet sofort sichtbar wird: Spinner im gedrückten Button,
        // beide Buttons gesperrt, bis die Antwort da ist.
        String sheetBusyStatus = '';
        Future<void> doStatus(String status) async {
          if (id == null || sheetBusyStatus.isNotEmpty) return; // Doppelklick-Schutz
          setSheet(() => sheetBusyStatus = status);
          await _doRsvp(id, status: status);
          if (!ctx.mounted) return;
          setSheet(() => sheetBusyStatus = '');
        }
        Widget btn(String label, IconData ic, bool active, String forStatus, VoidCallback onTap) => Expanded(
          child: GestureDetector(onTap: sheetBusyStatus.isNotEmpty ? null : onTap, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? cGreen.withValues(alpha: 0.16) : cSurface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: active ? cGreen : cTileBorder, width: active ? 1.2 : 0.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Spinner ERSETZT das Icon des gerade gedrückten Buttons.
              sheetBusyStatus == forStatus || (sheetBusyStatus == 'none' && active)
                  ? const SizedBox(width: 15, height: 15,
                      child: CircularProgressIndicator(color: cGreen, strokeWidth: 2))
                  : Icon(ic, color: active ? cGreen : cTextSecondary, size: 16),
              const SizedBox(width: 7),
              Text(label, style: TextStyle(
                color: active ? cGreen : (sheetBusyStatus.isNotEmpty ? cTextTertiary : cText),
                fontSize: 13.5, fontWeight: FontWeight.w700)),
            ]))));
        Widget action(String label, IconData ic, VoidCallback onTap) => Expanded(
          child: GestureDetector(onTap: onTap, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(11), border: Border.all(color: cTileBorder, width: 0.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(ic, color: cTextSecondary, size: 15), const SizedBox(width: 7),
              Text(label, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600)),
            ]))));
        return EventDetailsSheet(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              _crest(event), const SizedBox(width: 12),
              Expanded(child: Text(event.title, style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 14),
            Row(children: [const Icon(Icons.event_rounded, color: cTextTertiary, size: 15), const SizedBox(width: 8),
              Text(when, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600))]),
            if (event.location.isNotEmpty) ...[const SizedBox(height: 7),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.place_rounded, color: cTextTertiary, size: 15), const SizedBox(width: 8),
                Expanded(child: Text(event.location, style: const TextStyle(color: cTextSecondary, fontSize: 13.5)))])],
            if (event.description.isNotEmpty) ...[const SizedBox(height: 12),
              Text(event.description, style: const TextStyle(color: cTextSecondary, fontSize: 13.5, height: 1.5))],
            if (id != null) ...[
              const SizedBox(height: 14),
              Text('${count >= 0 ? count : 0} ${t.rsvpCount}${might >= 0 ? ' · $might ${t.rsvpMaybe}' : ''}',
                  style: const TextStyle(color: cTextTertiary, fontSize: 12.5)),
              const SizedBox(height: 10),
              Row(children: [
                btn(t.rsvpImComing, Icons.check_rounded, st == 'attending', 'attending', () => doStatus(st == 'attending' ? 'none' : 'attending')),
                const SizedBox(width: 10),
                btn(t.rsvpMaybe, Icons.help_outline_rounded, st == 'maybe', 'maybe', () => doStatus(st == 'maybe' ? 'none' : 'maybe')),
              ]),
            ],
            const SizedBox(height: 12),
            Row(children: [
              if (event.url.isNotEmpty) ...[
                action(t.evOpenLink, Icons.link_rounded, () async {
                  try { await launchUrl(Uri.parse(event.url), mode: LaunchMode.externalApplication); } catch (_) {}
                }),
                const SizedBox(width: 10),
              ],
              action(t.evShare, Icons.share_rounded, () {
                Share.share('${event.title} · $when${event.location.isNotEmpty ? '\n${event.location}' : ''}${event.url.isNotEmpty ? '\n${event.url}' : ''}');
              }),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              action(t.evToCalendar, Icons.event_available_rounded, () {
                cal.Add2Calendar.addEvent2Cal(cal.Event(
                  title: event.title,
                  description: event.description,
                  location: event.location,
                  startDate: event.startTime,
                  endDate: event.startTime.add(const Duration(hours: 2)),
                ));
              }),
            ]),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark, // Dunkler Hintergrund
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).calendarTitle),
        backgroundColor: cDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // SUCHLEISTE
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterEvents(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).calendarSearch,
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: cOrange),
                filled: true,
                fillColor: cCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // LISTE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: cOrange))
                : _filteredEvents.isEmpty
                    ? Center(child: Text(AppLocalizations.of(context).calendarNoEvents, style: TextStyle(color: Colors.grey.shade600)))
                    : ListView.builder(
                        itemCount: _filteredEvents.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          return Card(
                            color: cCard,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () => _showEventDetails(event),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                  children: [
                                    // DATUMS-BOX (Links)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: cOrange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: cOrange.withValues(alpha: 0.3)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _twoDigits(event.startTime.day),
                                            style: const TextStyle(color: cOrange, fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            _twoDigits(event.startTime.month),
                                            style: const TextStyle(color: cOrange, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // MEETUP-WAPPEN
                                    _crest(event),
                                    const SizedBox(width: 12),
                                    // INFO-TEXT (Mitte)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.title,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${_twoDigits(event.startTime.hour)}:${_twoDigits(event.startTime.minute)} Uhr",
                                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            event.location,
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // STERN: Meetup dieses Termins als Favorit
                                    // markieren -> erscheint als swipebare Karte
                                    // auf dem Dashboard.
                                    Builder(builder: (_) {
                                      final meetup = MeetupEventMatcher.resolve(event, MeetupService.cached);
                                      if (meetup == null) return const Icon(Icons.chevron_right, color: Colors.grey);
                                      // Store the resolved identity, never a guessed city.
                                      final favKey = meetup.id;
                                      final isFav = _favCities.any((key) =>
                                          MeetupService.resolveFavorite(key)?.id == favKey);
                                      return Row(mainAxisSize: MainAxisSize.min, children: [
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _toggleFav(favKey),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                            child: Icon(isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                                color: isFav ? cOrange : Colors.grey, size: 24),
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ]);
                                    }),
                                  ],
                                ),
                                    _rsvpRow(event),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
