// PORTAL — "Meine Meetups verwalten"
// ============================================
// Anmeldung am Einundzwanzig-Portal per Nostr (stateless, kind 22242),
// dann eigene Meetups laden und Termine anlegen.
// Nutzt PortalApiService (loginWithNostr / getMyMeetups / createMeetupEvent).
// ============================================

import 'package:flutter/material.dart';
import '../widgets/npub_chip.dart';
import '../services/meetup_calendar_service.dart';

import '../services/guide_service.dart';
import '../mixins/guide_service_host.dart';
import '../theme.dart';
import '../tours/more_tours.dart';
import '../l10n/app_localizations.dart';
import '../services/portal_api_service.dart';

class PortalMeetupsScreen extends StatefulWidget {
  const PortalMeetupsScreen({super.key});

  @override
  State<PortalMeetupsScreen> createState() => _PortalMeetupsScreenState();
}

class _PortalMeetupsScreenState extends State<PortalMeetupsScreen>
    with GuideServiceHost {
  bool _checking = true;       // initiale Token-Prüfung
  bool _connected = false;
  bool _loggingIn = false;
  bool _loadingMeetups = false;
  List<PortalMeetup> _meetups = [];

  @override
  void initState() {
    super.initState();
    _init();
    _startTour();
  }

  Future<void> _startTour() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final guide = this.guide;
    if (await guide.wasTourCompleted(GuideTour.myMeetups)) return;
    if (!mounted) return;
    await guide.startTour(GuideTour.myMeetups, MyMeetupsTour.steps());
  }

  @override
  void dispose() {
    finishGuideTourIfActive(GuideTour.myMeetups);
    super.dispose();
  }

  Future<void> _init() async {
    final has = await PortalApiService.hasToken();
    if (!mounted) return;
    setState(() { _connected = has; _checking = false; });
    if (has) _loadMeetups();
  }

  Future<void> _login() async {
    setState(() => _loggingIn = true);
    final res = await PortalApiService.loginWithNostr();
    if (!mounted) return;
    setState(() => _loggingIn = false);
    if (res.ok) {
      setState(() => _connected = true);
      _loadMeetups();
    } else {
      _snack('${AppLocalizations.of(context).portalLoginFailed}: ${res.error ?? ''}', cRed);
    }
  }

  Future<void> _logout() async {
    await PortalApiService.logout();
    if (!mounted) return;
    setState(() { _connected = false; _meetups = []; });
  }

  Future<void> _loadMeetups() async {
    setState(() => _loadingMeetups = true);
    final list = await PortalApiService.getMyMeetups();
    if (!mounted) return;
    setState(() { _meetups = list; _loadingMeetups = false; });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: KeyedSubtree(
            key: MyMeetupsTour.listKey,
            child: Text(t.portalTitle,
                style: const TextStyle(color: cText, fontWeight: FontWeight.w700))),
        actions: [
          if (_connected)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: cTextSecondary),
              tooltip: t.portalLogout,
              onPressed: _logout,
            ),
        ],
      ),
      body: SafeArea(
        child: _checking
            ? const Center(child: CircularProgressIndicator(color: cOrange))
            : _connected
                ? _connectedView(t)
                : _loginView(t),
      ),
    );
  }

  // ── Nicht verbunden ──
  Widget _loginView(AppLocalizations t) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const SizedBox(height: 40),
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.hub_rounded, color: cOrange, size: 30),
      ),
      const SizedBox(height: 20),
      Text(t.portalNotConnected, textAlign: TextAlign.center,
          style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text(t.portalConnectInfo, textAlign: TextAlign.center,
          style: const TextStyle(color: cTextSecondary, fontSize: 14, height: 1.55)),
      const SizedBox(height: 28),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _loggingIn ? null : _login,
          icon: _loggingIn
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.login_rounded, color: Colors.white, size: 18),
          label: Text(_loggingIn ? t.portalConnecting : t.portalConnect,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: cOrange,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
          ),
        ),
      ),
    ]),
  );

  // ── Verbunden ──
  Widget _connectedView(AppLocalizations t) {
    if (_loadingMeetups) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(color: cOrange),
        const SizedBox(height: 14),
        Text(t.portalLoadingMeetups, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
      ]));
    }
    return RefreshIndicator(
      color: cOrange, backgroundColor: cCard,
      onRefresh: _loadMeetups,
      child: ListView(
        // Kein Tour-Schluessel mehr an der ganzen Liste: Sie fuellt den
        // Bildschirm, und ein bildschirmfuellendes Loch ist kein Spotlight
        // mehr — es ist nur ein Rahmen um alles. Der Schluessel sitzt jetzt
        // an der Kopfleiste, das Loch bleibt klein und der Text lesbar.
        padding: const EdgeInsets.all(16),
        children: [
          if (_meetups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(children: [
                const Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 44),
                const SizedBox(height: 12),
                Text(t.portalNoMeetups, textAlign: TextAlign.center,
                    style: const TextStyle(color: cTextSecondary, fontSize: 14)),
              ]),
            )
          else
            ..._meetups.map((m) => _meetupCard(t, m)),
          const SizedBox(height: 12),
          Center(child: Text(t.portalSource, style: const TextStyle(color: cTextTertiary, fontSize: 11))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _meetupCard(AppLocalizations t, PortalMeetup m) =>
      _MeetupAdminCard(meetup: m, onManageEvents: () => _openManageEvents(m));

  Future<void> _openManageEvents(PortalMeetup meetup) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ManageEventsScreen(meetup: meetup)),
    );
    // nach Rückkehr nichts nachzuladen — die Verwaltungsseite lädt selbst
  }
}

// ============================================
//  MEETUP-KARTE mit inline Admin-Verwaltung
// ============================================
class _MeetupAdminCard extends StatefulWidget {
  final PortalMeetup meetup;
  final VoidCallback onManageEvents;
  const _MeetupAdminCard({required this.meetup, required this.onManageEvents});

  @override
  State<_MeetupAdminCard> createState() => _MeetupAdminCardState();
}

class _MeetupAdminCardState extends State<_MeetupAdminCard> {
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.meetup.isLeader) {
      _loadAdmins();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadAdmins() async {
    setState(() => _loading = true);
    final l = await PortalApiService.getMeetupLeaders(widget.meetup.id);
    if (!mounted) return;
    setState(() { _admins = l; _loading = false; });
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating));

  Future<void> _addAdmin() async {
    final t = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final npub = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: Text(t.ldAdd, style: const TextStyle(color: cText, fontSize: 17)),
        content: TextField(
          controller: ctrl, autofocus: true,
          style: const TextStyle(color: cText),
          decoration: InputDecoration(
            hintText: t.ldAddHint,
            hintStyle: const TextStyle(color: cTextTertiary),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: cTileBorder)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: cOrange)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.resetCancel, style: const TextStyle(color: cTextSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(t.ldAddDo, style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (npub == null || npub.isEmpty) return;
    if (!npub.startsWith('npub1') || npub.length < 60) { _snack(t.ldNpubInvalid, cRed); return; }
    setState(() => _busy = true);
    final res = await PortalApiService.addMeetupLeader(widget.meetup.id, npub);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) { _snack(t.ldAdded, Colors.green.shade700); _loadAdmins(); }
    else { _snack('${t.ldFailed}: ${res.error ?? ''}', cRed); }
  }

  Future<void> _removeAdmin(Map<String, dynamic> admin) async {
    final t = AppLocalizations.of(context);
    final id = admin['id'];
    if (id is! int) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: Text(t.ldRemove, style: const TextStyle(color: cText, fontSize: 17)),
        content: Text(t.ldRemoveConfirm, style: const TextStyle(color: cTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.resetCancel, style: const TextStyle(color: cTextSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.ldRemove, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final res = await PortalApiService.removeMeetupLeader(widget.meetup.id, id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) { _snack(t.ldRemoved, Colors.green.shade700); _loadAdmins(); }
    else { _snack('${t.ldFailed}: ${res.error ?? ''}', cRed); }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final m = widget.meetup;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(m.name, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700))),
          if (m.isLeader)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(t.portalLeader, style: const TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onManageEvents,
            icon: const Icon(Icons.event_note_rounded, color: cOrange, size: 18),
            label: Text(t.portalManageEvents, style: const TextStyle(color: cOrange, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: cOrange, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
            ),
          ),
        ),

        // ── Admin-Verwaltung (nur wenn ich Leader bin) ──
        if (m.isLeader) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.shield_rounded, color: cTextSecondary, size: 15),
            const SizedBox(width: 7),
            Text(t.ldTitle, style: const TextStyle(color: cTextSecondary, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: cOrange, strokeWidth: 2))))
          else ...[
            for (final a in _admins) _adminRow(t, a),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _addAdmin,
                icon: const Icon(Icons.person_add_alt_1_rounded, color: cGreen, size: 17),
                label: Text(t.ldAddButton, style: const TextStyle(color: cGreen, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cGreen.withValues(alpha: 0.7), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
                ),
              ),
            ),
          ],
        ],
      ]),
    );
  }

  Widget _adminRow(AppLocalizations t, Map<String, dynamic> a) {
    final name = (a['name'] ?? '').toString();
    final nostr = (a['nostr'] ?? '').toString();
    final isCreator = a['is_creator'] == true;
    final shortNpub = nostr.isNotEmpty ? NpubChip.shorten(nostr) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(isCreator ? Icons.star_rounded : Icons.person_rounded, color: isCreator ? cOrange : cTextSecondary, size: 17),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isNotEmpty ? name : (shortNpub.isNotEmpty ? shortNpub : '?'),
              style: const TextStyle(color: cText, fontSize: 13.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          if (name.isNotEmpty && shortNpub.isNotEmpty)
            NpubChip(nostr,
                style: const TextStyle(color: cTextTertiary, fontSize: 10.5),
                showIcon: false),
        ])),
        if (isCreator)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(5)),
            child: Text(t.ldCreator, style: const TextStyle(color: cOrange, fontSize: 9.5, fontWeight: FontWeight.w700)),
          )
        else
          GestureDetector(
            onTap: _busy ? null : () => _removeAdmin(a),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: cRed.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.close_rounded, color: cRed, size: 16),
            ),
          ),
      ]),
    );
  }
}

// ============================================
//  TERMINE VERWALTEN (Liste + anlegen + bearbeiten)
// ============================================
class _ManageEventsScreen extends StatefulWidget {
  final PortalMeetup meetup;
  const _ManageEventsScreen({required this.meetup});

  @override
  State<_ManageEventsScreen> createState() => _ManageEventsScreenState();
}

class _ManageEventsScreenState extends State<_ManageEventsScreen> {
  bool _loading = true;
  List<PortalMeetupEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await PortalApiService.getMyMeetupEvents();
    if (!mounted) return;
    // nur Termine dieses Meetups, chronologisch
    final mine = all.where((e) => e.meetupId == widget.meetup.id).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    setState(() { _events = mine; _loading = false; });
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _newEvent() async {
    final ok = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => _EventEditor(meetup: widget.meetup)),
    );
    if (ok == true && mounted) {
      _snack(AppLocalizations.of(context).portalCreatedOk, cGreen);
      _load();
    }
  }

  Future<void> _editEvent(PortalMeetupEvent ev) async {
    final ok = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => _EventEditor(meetup: widget.meetup, existing: ev)),
    );
    if (ok == true && mounted) {
      _snack(AppLocalizations.of(context).portalUpdatedOk, cGreen);
      _load();
    }
  }

  String _fmtStart(String iso) {
    // /my-meetup-events liefert rohe UTC ohne Kennung -> portalStartUtc
    // rechnet in Geraetezeit um (18:00 statt 16:00 bei MESZ).
    final d = MeetupCalendarService.portalStartUtc(iso);
    if (d == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(widget.meetup.name, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: cOrange,
        onPressed: _newEvent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(t.portalNewEvent, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: cOrange),
                const SizedBox(height: 14),
                Text(t.portalLoadingEvents, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
              ]))
            : RefreshIndicator(
                color: cOrange, backgroundColor: cCard,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    Text(t.portalExistingEvents.toUpperCase(),
                        style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                    const SizedBox(height: 10),
                    if (_events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Column(children: [
                          const Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 40),
                          const SizedBox(height: 12),
                          Text(t.portalNoEvents, textAlign: TextAlign.center,
                              style: const TextStyle(color: cTextSecondary, fontSize: 14)),
                        ]),
                      )
                    else
                      ..._events.map((ev) => _eventRow(t, ev)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _eventRow(AppLocalizations t, PortalMeetupEvent ev) => GestureDetector(
    onTap: () => _editEvent(ev),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard, borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.event_rounded, color: cOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_fmtStart(ev.start), style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          if (ev.location != null && ev.location!.isNotEmpty)
            Text(ev.location!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: cTextSecondary, fontSize: 12))
          else
            Text(t.portalTapToEdit, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
        ])),
        const Icon(Icons.edit_rounded, color: cTextTertiary, size: 16),
      ]),
    ),
  );
}

// ============================================
//  EVENT-EDITOR (Termin anlegen ODER bearbeiten)
// ============================================
class _EventEditor extends StatefulWidget {
  final PortalMeetup meetup;
  final PortalMeetupEvent? existing; // null = anlegen, sonst bearbeiten
  const _EventEditor({required this.meetup, this.existing});

  @override
  State<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<_EventEditor> {
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  DateTime? _start;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Bearbeiten-Modus: Felder vorbelegen
    final ex = widget.existing;
    if (ex != null) {
      _locationCtrl.text = ex.location ?? '';
      _descriptionCtrl.text = ex.description ?? '';
      _linkCtrl.text = ex.link ?? '';
      _start = DateTime.tryParse(ex.start)?.toLocal();
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _start ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start ?? now),
    );
    if (!mounted) return;
    setState(() {
      _start = DateTime(date.year, date.month, date.day, time?.hour ?? 19, time?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    if (_start == null) { _snack(t.portalNeedStart, cRed); return; }
    setState(() => _saving = true);
    // Portal erwartet RFC-3339 in UTC (z.B. 2026-07-21T17:32:28Z)
    final startIso = _start!.toUtc().toIso8601String();
    final PortalResult res;
    if (_isEdit) {
      final eid = widget.existing!.id;
      if (eid == null) { setState(() => _saving = false); _snack('Fehler: Termin ohne ID', cRed); return; }
      res = await PortalApiService.updateMeetupEvent(
        eventId: eid,
        start: startIso,
        location: _emptyToNull(_locationCtrl.text),
        description: _emptyToNull(_descriptionCtrl.text),
        link: _emptyToNull(_linkCtrl.text),
      );
    } else {
      res = await PortalApiService.createMeetupEvent(
        meetupId: widget.meetup.id,
        start: startIso,
        location: _emptyToNull(_locationCtrl.text),
        description: _emptyToNull(_descriptionCtrl.text),
        link: _emptyToNull(_linkCtrl.text),
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (res.ok) {
      Navigator.pop(context, true);
    } else {
      _snack(res.error ?? 'Fehler', cRed);
    }
  }

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  String _fmtStart(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(_isEdit ? t.portalEditEvent : t.portalEventTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Meetup-Name (Kontext)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: cCard, borderRadius: BorderRadius.circular(kTileRadius),
                border: Border.all(color: cTileBorder, width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.groups_rounded, color: cOrange, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.meetup.name,
                    style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700))),
              ]),
            ),
            // Datum & Uhrzeit
            _label(t.portalFieldStart),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: cCard, borderRadius: BorderRadius.circular(kTileRadius),
                  border: Border.all(color: _start == null ? cTileBorder : cOrange, width: _start == null ? 0.5 : 1),
                ),
                child: Row(children: [
                  Icon(Icons.event_rounded, color: _start == null ? cTextTertiary : cOrange, size: 18),
                  const SizedBox(width: 10),
                  Text(_start == null ? t.portalPickDate : _fmtStart(_start!),
                      style: TextStyle(color: _start == null ? cTextTertiary : cText, fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _label(t.portalFieldLocation),
            _input(_locationCtrl, t.portalFieldLocationHint),
            const SizedBox(height: 16),
            _label(t.portalFieldDescription),
            _input(_descriptionCtrl, t.portalFieldDescriptionHint, maxLines: 4),
            const SizedBox(height: 16),
            _label(t.portalFieldLink),
            _input(_linkCtrl, t.portalFieldLinkHint, keyboard: TextInputType.url),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                label: Text(_saving ? t.portalSaving : (_isEdit ? t.portalUpdate : t.portalSave),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
  );

  Widget _input(TextEditingController c, String hint, {int maxLines = 1, TextInputType? keyboard}) => TextField(
    controller: c,
    maxLines: maxLines,
    keyboardType: keyboard,
    style: const TextStyle(color: cText, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: cTextTertiary, fontSize: 14),
      filled: true, fillColor: cCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cOrange, width: 1.5)),
    ),
  );
}
