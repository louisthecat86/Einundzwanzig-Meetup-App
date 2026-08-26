// COMMUNITY-HUB
// ============================================
// Auswahlmenü hinter der "Community"-Kachel (Struktur C):
//   - PORTAL (groß)  -> PortalAreaScreen: Meetups, Events & Zusagen (RSVP),
//                       Kurse & Dozenten, Karte, Meine Meetups, Portal-Web
//   - News / Nostr / Shoutout / Podcast (bestehende Ziele, unverändert)
// Funktionen orientiert an der Open-Source-Companion-App
// (HolgerHatGarKeineNode/twenty-one-companion), Design = App-Theme.
// ============================================

import 'package:flutter/material.dart';
import '../services/meetup_calendar_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/signing_service.dart';
import '../services/satoshiduell_service.dart';
import 'plebrap_player_screen.dart';

import '../l10n/app_localizations.dart';
import '../services/guide_service.dart';
import '../mixins/guide_service_host.dart';
import '../tours/more_tours.dart';
import '../services/portal_api_service.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'calendar_screen.dart';
import 'community_portal_screen.dart' as legacy;
import 'news_screen.dart';
import 'nearby_meetups_screen.dart';
import 'portal_meetups_screen.dart';
import '../widgets/shadows.dart';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
}

/// Aus StatelessWidget geworden, damit die Tour einen Lebenszyklus hat:
/// starten beim Oeffnen, beenden beim Schliessen. Ohne State liefe sie bei
/// jedem Neuzeichnen erneut los.
class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with GuideServiceHost {
  @override
  void initState() {
    super.initState();
    _startTour();
  }

  Future<void> _startTour() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final guide = this.guide;
    if (await guide.wasTourCompleted(GuideTour.portal)) return;
    if (!mounted) return;
    await guide.startTour(GuideTour.portal, CommunityTour.steps());
  }

  @override
  void dispose() {
    finishGuideTourIfActive(GuideTour.portal);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.chTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // PORTAL (groß)
            KeyedSubtree(
              key: CommunityTour.portalKey,
              child: _bigCard(
              context,
              icon: Icons.public_rounded,
              color: cOrange,
              title: t.chPortal,
              subtitle: t.chPortalSub,
              chips: const ['Meetups', 'Events', 'Kurse', 'Karte'],
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalAreaScreen())),
            ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: KeyedSubtree(key: CommunityTour.newsKey, child: _smallCard(context, icon: Icons.article_rounded, color: cOrange, title: t.chNews, subtitle: t.chNewsSub,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen()))))),
              const SizedBox(width: 14),
              Expanded(child: _smallCard(context, icon: Icons.flutter_dash, color: cNostr, title: t.chNostr, subtitle: t.chNostrSub,
                  onTap: () => _openUrl('https://njump.me/npub1qv02xpsc3lhxxx5x7xswf88w3u7kykft9ea7t78tz7ywxf7mxs9qrxujnc'))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: KeyedSubtree(key: CommunityTour.shoutoutKey, child: _smallCard(context, icon: Icons.campaign_rounded, color: cOrange, title: t.chShoutout, subtitle: t.chShoutoutSub,
                  onTap: () => _openUrl('https://shoutout.einundzwanzig.space')))),
              const SizedBox(width: 14),
              Expanded(child: _smallCard(context, icon: Icons.podcasts_rounded, color: cPurple, title: t.chPodcast, subtitle: t.chPodcastSub,
                  onTap: () => _openUrl('https://einundzwanzig.space/podcast/'))),
            ]),
            const SizedBox(height: 14),
            // SATOSHIDUELL — Quiz-Duelle um Sats (satoshiduell.de).
            // Öffnet die WebApp MIT npub in der URL: deren LoginView liest
            // ?npub=... und loggt automatisch ein -> One-Tap ins Spiel.
            KeyedSubtree(
                key: CommunityTour.duellKey,
                child: _duellCard(context, subtitle: t.chDuellSub)),
            const SizedBox(height: 14),
            // PLEBRAP — Bitcoin-Rap-Player (Songs von plebrap.de)
            _smallCardWide(context, icon: Icons.graphic_eq_rounded, color: cOrange,
                title: 'PlebRap', subtitle: t.chPlebrapSub,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlebrapPlayerScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _bigCard(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required List<String> chips, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.08), cCard.withValues(alpha: 0.98)],
          ),
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
          boxShadow: shadowForElevation(2, accent: color),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kTileRadius),
          child: Stack(children: [
            Positioned(right: -12, bottom: -12, child: Icon(icon, size: 96, color: color.withValues(alpha: 0.10))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(icon, color: color, size: 22),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20),
                ]),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _duellCard(BuildContext context, {required String subtitle}) {
    const gold = Color(0xFFFFC93C); // Blitz-Gelb des Logos
    return GestureDetector(
      onTap: () async {
        // npub der aktiven Identität (Amber ODER lokal). Die WebApp liest
        // den Parameter, loggt ein und entfernt ihn aus der Adresszeile.
        final npub = await SigningService.npub();
        final url = (npub != null && npub.isNotEmpty)
            ? 'https://satoshiduell.de/?npub=$npub'
            : 'https://satoshiduell.de/';
        _openUrl(url);
      },
      child: Container(
        // 106 war zu knapp: Icon 22 + 10 + Titel + 3 + Untertitel brauchen
        // zusammen mit dem Padding (16/18) mehr Platz — auf dem Geraet lief
        // die Karte um 5px ueber. 120 laesst Reserve fuer groessere Schrift.
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gold.withValues(alpha: 0.16), cCard.withValues(alpha: 0.98)],
          ),
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: gold.withValues(alpha: 0.28), width: 0.8),
          boxShadow: shadowForElevation(2, accent: gold),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kTileRadius),
          child: Stack(children: [
            Positioned(right: -12, bottom: -12,
              child: Opacity(opacity: 0.13,
                child: Image.asset('assets/images/satoshiduell.png',
                  width: 100, height: 100, fit: BoxFit.contain,
                  errorBuilder: (_, e, st) => Icon(Icons.bolt_rounded, size: 96, color: gold.withValues(alpha: 0.10))))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: FutureBuilder<DuellStatus>(
                // Untertitel sagt WAS ansteht, Badge zeigt WIE VIELE Duelle
                // eine Aktion erlauben — gleiche Logik wie die Home-Kachel.
                future: SatoshiDuellService.fetchStatus(),
                builder: (_, snap) {
                  final st = snap.data ?? DuellStatus.empty;
                  final t = AppLocalizations.of(context);
                  // ALLES anzeigen, farblich wie in SatoshiDuell selbst:
                  // dran = Gold, Lobby = Orange, warten (eigenes Spiel) = Grün.
                  final spans = <TextSpan>[
                    if (st.myTurn > 0)
                      TextSpan(text: '⚡ ${st.myTurn} ${t.sdShortTurn}',
                          style: const TextStyle(color: gold, fontWeight: FontWeight.w700)),
                    if (st.lobby > 0)
                      TextSpan(text: '${st.lobby} ${t.sdShortLobby}',
                          style: const TextStyle(color: cOrange, fontWeight: FontWeight.w600)),
                    if (st.waiting > 0)
                      TextSpan(text: '${st.waiting} ${t.sdShortWait}',
                          style: const TextStyle(color: cGreen)),
                  ];
                  final joined = <TextSpan>[];
                  for (var i = 0; i < spans.length; i++) {
                    if (i > 0) joined.add(const TextSpan(text: '  ·  ', style: TextStyle(color: cTextTertiary)));
                    joined.add(spans[i]);
                  }
                  final n = st.myTurn + st.lobby;
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Row(children: [
                      const Icon(Icons.bolt_rounded, color: gold, size: 22),
                      const Spacer(),
                      if (n > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: gold.withValues(alpha: 0.5), width: 0.8),
                          ),
                          child: Text('$n', style: const TextStyle(color: gold, fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ),
                      Icon(Icons.open_in_new_rounded, color: cTextTertiary, size: 17),
                    ]),
                    const SizedBox(height: 10),
                    const Text('SatoshiDuell', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    joined.isEmpty
                ? Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)
                : Text.rich(TextSpan(children: joined), style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Kompakte Karte ueber volle Breite — Dashboard-Optik.
  Widget _smallCardWide(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.08), cCard.withValues(alpha: 0.98)],
          ),
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
          boxShadow: shadowForElevation(2, accent: color),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kTileRadius),
          child: Stack(children: [
            Positioned(right: -12, bottom: -12, child: Icon(icon, size: 96, color: color.withValues(alpha: 0.10))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(children: [
                  Icon(icon, color: color, size: 22),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20),
                ]),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _smallCard(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.08), cCard.withValues(alpha: 0.98)],
          ),
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
          boxShadow: shadowForElevation(2, accent: color),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kTileRadius),
          child: Stack(children: [
            Positioned(right: -12, bottom: -12, child: Icon(icon, size: 96, color: color.withValues(alpha: 0.10))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(icon, color: color, size: 22),
                const Spacer(),
                Text(title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ============================================
//  PORTAL-BEREICH (Ebene 2)
// ============================================
/// Wie der Community-Hub aus StatelessWidget geworden: Die Tour braucht
/// einen Lebenszyklus, damit sie einmal startet statt bei jedem Neuzeichnen.
class PortalAreaScreen extends StatefulWidget {
  const PortalAreaScreen({super.key});

  @override
  State<PortalAreaScreen> createState() => _PortalAreaScreenState();
}

class _PortalAreaScreenState extends State<PortalAreaScreen>
    with GuideServiceHost {
  @override
  void initState() {
    super.initState();
    _startTour();
  }

  Future<void> _startTour() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final guide = this.guide;
    if (await guide.wasTourCompleted(GuideTour.portalArea)) return;
    if (!mounted) return;
    await guide.startTour(GuideTour.portalArea, PortalAreaTour.steps());
  }

  @override
  void dispose() {
    finishGuideTourIfActive(GuideTour.portalArea);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.paTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _row(context, Icons.groups_rounded, cOrange, t.paMeetups, t.paMeetupsSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
                rowKey: PortalAreaTour.meetupsKey),
            _row(context, Icons.event_available_rounded, cGreen, t.paEvents, t.paEventsSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()))),
            _row(context, Icons.school_rounded, cNostr, t.paCourses, t.paCoursesSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen())),
                rowKey: PortalAreaTour.coursesKey),
            _row(context, Icons.map_rounded, cCyan, t.paMap, t.paMapSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyMeetupsScreen())),
                rowKey: PortalAreaTour.mapKey),
            _row(context, Icons.edit_calendar_rounded, cOrange, t.paMine, t.paMineSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalMeetupsScreen())),
                rowKey: PortalAreaTour.mineKey),
            _row(context, Icons.language_rounded, cTextSecondary, t.paWeb, t.paWebSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const legacy.CommunityPortalScreen()))),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, Color color, String title, String sub, VoidCallback onTap,
          {Key? rowKey}) =>
      GestureDetector(
    key: rowKey,
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.08), cCard.withValues(alpha: 0.98)],
        ),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
        boxShadow: shadowForElevation(2, accent: color),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: cTextTertiary, fontSize: 11.5)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
      ]),
    ),
  );
}

// ============================================
//  EVENTS & ZUSAGEN (RSVP) — Companion-Feature
// ============================================
class PortalEventsScreen extends StatefulWidget {
  const PortalEventsScreen({super.key});

  @override
  State<PortalEventsScreen> createState() => _PortalEventsScreenState();
}

class _PortalEventsScreenState extends State<PortalEventsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _events = [];
  final Map<int, Map<String, dynamic>> _rsvp = {}; // eventId -> {count, going}
  final Set<int> _busy = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await PortalApiService.getAllMeetupEvents();
    // nur kommende, chronologisch
    final now = DateTime.now().subtract(const Duration(hours: 6));
    list.retainWhere((e) {
      final d = MeetupCalendarService.portalStart((e['start'] ?? '').toString());
      return d != null && d.isAfter(now);
    });
    list.sort((a, b) => (a['start'] ?? '').toString().compareTo((b['start'] ?? '').toString()));
    if (!mounted) return;
    setState(() { _events = list; _loading = false; });
    // RSVP-Status der ersten 25 nachladen (sparsam)
    for (final e in list) {
      final id = e['id'];
      if (id is! int) continue;
      final r = await PortalApiService.getRsvp(id);
      if (!mounted) return;
      if (r != null) setState(() => _rsvp[id] = r);
    }
  }

  Future<void> _doRsvp(int id, {String status = 'attending'}) async {
    final t = AppLocalizations.of(context);
    if (!await PortalApiService.hasToken()) {
      _snack(t.rsvpNeedLogin, cRed);
      return;
    }
    setState(() => _busy.add(id));
    final res = await PortalApiService.rsvp(id, status: status);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    if (res.ok) {
      final r = await PortalApiService.getRsvp(id);
      if (mounted && r != null) setState(() => _rsvp[id] = r);
    } else {
      _snack('${t.rsvpFailed}: ${res.error ?? ''}', cRed);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating));

  String _fmt(String iso) {
    final d = MeetupCalendarService.portalStart(iso);
    if (d == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }

  bool _isGoing(Map<String, dynamic>? r) {
    if (r == null) return false;
    final st = (r['status'] ?? '').toString();
    if (st == 'attending' || st == 'maybe') return true;
    final v = r['going'] ?? r['is_going'] ?? r['rsvped'];
    return v == true;
  }

  int _count(Map<String, dynamic>? r) {
    if (r == null) return -1;
    final v = r['attendees'] ?? r['count'] ?? r['total'] ?? r['rsvps'];
    return (v is int) ? v : -1;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.paEvents, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: cTextSecondary), onPressed: _loading ? null : _load)],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: cOrange),
                const SizedBox(height: 12),
                Text(t.rsvpLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
              ]))
            : _events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [cCard.withValues(alpha: 0.96), cDark.withValues(alpha: 0.96)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cOrange.withValues(alpha: 0.24), width: 1),
                          boxShadow: shadowForElevation(2, accent: cOrange),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cOrange.withValues(alpha: 0.12),
                                border: Border.all(color: cOrange.withValues(alpha: 0.24), width: 1),
                              ),
                              child: const Icon(Icons.event_available_rounded, color: cOrange, size: 28),
                            ),
                            const SizedBox(height: 14),
                            Text(t.rsvpNone, textAlign: TextAlign.center, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: cOrange, backgroundColor: cCard, onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length,
                      itemBuilder: (_, i) => _eventCard(t, _events[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _eventCard(AppLocalizations t, Map<String, dynamic> e) {
    final id = e['id'] is int ? e['id'] as int : -1;
    final r = _rsvp[id];
    final going = _isGoing(r);
    final count = _count(r);
    final meetupName = (e['meetup'] is Map ? ((e['meetup'] as Map)['name'] ?? '') : (e['meetup.name'] ?? e['meetup_name'] ?? '')).toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cOrange.withValues(alpha: 0.08), cCard.withValues(alpha: 0.98)],
        ),
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cOrange.withValues(alpha: 0.22), width: 0.8),
        boxShadow: shadowForElevation(2, accent: cOrange),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(meetupName.isNotEmpty ? meetupName : 'Meetup #${e['meetup_id'] ?? ''}',
            style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.schedule_rounded, color: cTextTertiary, size: 13),
          const SizedBox(width: 5),
          Text(_fmt((e['start'] ?? '').toString()), style: const TextStyle(color: cTextSecondary, fontSize: 12)),
        ]),
        if ((e['location'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.place_rounded, color: cTextTertiary, size: 13),
            const SizedBox(width: 5),
            Expanded(child: Text(e['location'].toString(), style: const TextStyle(color: cTextSecondary, fontSize: 12))),
          ]),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (count >= 0)
            Text('$count ${t.rsvpCount}', style: const TextStyle(color: cTextTertiary, fontSize: 12)),
          const Spacer(),
          if (id > 0)
            going
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t.rsvpYouGo, style: const TextStyle(color: cGreen, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _busy.contains(id) ? null : () => _doRsvp(id, status: 'none'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cRed.withValues(alpha: 0.6), width: 1),
                        ),
                        child: _busy.contains(id)
                            ? const SizedBox(width: 12, height: 12,
                                child: CircularProgressIndicator(color: cRed, strokeWidth: 2))
                            : Text(t.rsvpCancel, style: const TextStyle(color: cRed, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ])
                : SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: _busy.contains(id) ? null : () => _doRsvp(id),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: cGreen, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _busy.contains(id)
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: cGreen, strokeWidth: 2))
                          : Text(t.rsvpGoing, style: const TextStyle(color: cGreen, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
        ]),
      ]),
    );
  }
}

// ============================================
//  KURSE & DOZENTEN — Companion-Feature (lesend)
// ============================================
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _lecturers = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final c = await PortalApiService.getCourses();
    final l = await PortalApiService.getLecturers();
    if (!mounted) return;
    setState(() { _courses = c; _lecturers = l; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cDark,
        appBar: AppBar(
          backgroundColor: cDark, elevation: 0,
          title: Text(t.paCourses, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 17)),
          bottom: TabBar(
            indicatorColor: cOrange, labelColor: cOrange, unselectedLabelColor: cTextSecondary,
            tabs: [Tab(text: t.crsCourses), Tab(text: t.crsLecturers)],
          ),
        ),
        body: SafeArea(
          child: _loading
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: cOrange),
                  const SizedBox(height: 12),
                  Text(t.crsLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
                ]))
              : TabBarView(children: [
                  _list(_courses, t, isCourse: true),
                  _list(_lecturers, t, isCourse: false),
                ]),
        ),
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> items, AppLocalizations t, {required bool isCourse}) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cCard.withValues(alpha: 0.96), cDark.withValues(alpha: 0.96)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cNostr.withValues(alpha: 0.24), width: 1),
              boxShadow: shadowForElevation(2, accent: cNostr),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cNostr.withValues(alpha: 0.12),
                    border: Border.all(color: cNostr.withValues(alpha: 0.24), width: 1),
                  ),
                  child: const Icon(Icons.school_rounded, color: cNostr, size: 28),
                ),
                const SizedBox(height: 14),
                Text(t.crsNone, textAlign: TextAlign.center, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: cOrange, backgroundColor: cCard, onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i];
          final name = (e['name'] ?? e['title'] ?? '').toString();
          final desc = (e['description'] ?? e['intro'] ?? e['bio'] ?? '').toString();
          return GestureDetector(
            onTap: () { final id = e['id']; if (id is int) { Navigator.push(context, MaterialPageRoute(builder: (_) => isCourse ? CourseDetailScreen(id: id, fallback: e) : LecturerDetailScreen(id: id, fallback: e))); } else { _showDetails(context, name, desc, isCourse); } },
            child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cNostr.withValues(alpha: 0.08), cCard.withValues(alpha: 0.98)],
              ),
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(color: cNostr.withValues(alpha: 0.22), width: 0.8),
              boxShadow: shadowForElevation(2, accent: cNostr),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: cNostr.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                child: Icon(isCourse ? Icons.school_rounded : Icons.person_rounded, color: cNostr, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc, maxLines: 3, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: cTextSecondary, fontSize: 12.5, height: 1.4)),
                ],
              ])),
              const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16),
            ]),
          ),
          );
        },
      ),
    );
  }

  /// Detail-Sheet für Kurs/Dozent: voller Text + klickbare Links.
  void _showDetails(BuildContext context, String name, String desc, bool isCourse) {
    final links = RegExp(r'https?://[^\s\)\]>,]+').allMatches(desc).map((m) => m.group(0)!).toSet().toList();
    showModalBottomSheet(
      context: context, backgroundColor: cCard, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.5, maxChildSize: 0.9, minChildSize: 0.3,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(isCourse ? Icons.school_rounded : Icons.person_rounded, color: cNostr, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 12),
            Text(desc.isNotEmpty ? desc : '—', style: const TextStyle(color: cTextSecondary, fontSize: 14, height: 1.5)),
            for (final url in links)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () => _openUrl(url),
                  child: Row(children: [
                    const Icon(Icons.link_rounded, color: cOrange, size: 15),
                    const SizedBox(width: 7),
                    Expanded(child: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: cOrange, fontSize: 13, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}


// ── Tolerante Helfer für Portal-Felder (flach "a.b" ODER verschachtelt) ──
String pv(Map e, String key) {
  final v = e[key];
  if (v != null && v is! Map && v is! List) return v.toString();
  if (key.contains('.')) {
    final parts = key.split('.');
    final n = e[parts[0]];
    if (n is Map && n[parts[1]] != null) return n[parts[1]].toString();
  }
  return '';
}
String pImg(Map e) {
  for (final k in ['image', 'logo', 'avatar', 'picture', 'cover']) {
    final v = pv(e, k);
    if (v.startsWith('http')) return v;
  }
  return '';
}

class CourseDetailScreen extends StatefulWidget {
  final int id; final Map<String, dynamic> fallback;
  const CourseDetailScreen({super.key, required this.id, required this.fallback});
  @override State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Map<String, dynamic>? _d;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final d = await PortalApiService.getCourse(widget.id);
    if (mounted) setState(() => _d = d ?? widget.fallback);
  }

  @override Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final e = _d ?? widget.fallback;
    final name = pv(e, 'name').isNotEmpty ? pv(e, 'name') : pv(e, 'title');
    final desc = pv(e, 'description');
    final img = pImg(e);
    final lecName = pv(e, 'lecturer.name');
    final lecId = (e['lecturer'] is Map && (e['lecturer'] as Map)['id'] is int) ? (e['lecturer'] as Map)['id'] as int : null;
    final events = (e['events'] is List) ? (e['events'] as List).whereType<Map<String, dynamic>>().toList()
                 : (e['course_events'] is List) ? (e['course_events'] as List).whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
    final portal = pv(e, 'portalLink');
    final links = RegExp(r'https?://[^\s\)\]>,]+').allMatches(desc).map((m) => m.group(0)!).toSet().toList();
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(backgroundColor: cDark, elevation: 0,
        title: Text(t.crsCourses, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 17))),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        _headerCard(img, name, lecName, Icons.school_rounded),
        if (portal.startsWith('http'))
          Padding(padding: const EdgeInsets.only(top: 10),
            child: _linkRow(Icons.open_in_new_rounded, t.crsOpenPortal, () => _openUrl(portal))),
        if (events.isNotEmpty) ...[
          _section(t.crsUpcoming),
          for (final ev in events) _eventRow(ev),
        ],
        if (desc.isNotEmpty) ...[_section(t.crsAbout),
          Text(desc, style: const TextStyle(color: cTextSecondary, fontSize: 14, height: 1.55))],
        for (final u in links) Padding(padding: const EdgeInsets.only(top: 8), child: _linkRow(Icons.link_rounded, u, () => _openUrl(u))),
        if (lecName.isNotEmpty) ...[
          _section(t.crsLecturer),
          GestureDetector(
            onTap: lecId == null ? null : () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LecturerDetailScreen(id: lecId, fallback: (e['lecturer'] as Map).cast<String, dynamic>()))),
            child: _rowCard(pImg((e['lecturer'] as Map?) ?? {}), lecName, pv(e, 'lecturer.intro'), Icons.person_rounded)),
        ],
      ])),
    );
  }

  Widget _eventRow(Map<String, dynamic> ev) {
    final from = pv(ev, 'from').isNotEmpty ? pv(ev, 'from') : pv(ev, 'start');
    final loc = pv(ev, 'location').isNotEmpty ? pv(ev, 'location') : pv(ev, 'venue.name');
    final link = pv(ev, 'link');
    final title = pv(ev, 'name').isNotEmpty ? pv(ev, 'name') : pv(ev, 'title');
    final desc = pv(ev, 'description');
    final d = DateTime.tryParse(from);
    String two(int n) => n.toString().padLeft(2, '0');
    final when = d == null ? from : '${two(d.day)}.${two(d.month)}.${d.year} · ${two(d.hour)}:${two(d.minute)}';
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
      child: Row(children: [
        const Icon(Icons.event_rounded, color: cOrange, size: 18), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(when, style: const TextStyle(color: cText, fontSize: 13.5, fontWeight: FontWeight.w700)),
          if (loc.isNotEmpty) Text(loc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cTextTertiary, fontSize: 12)),
        ])),
        // In den Geräte-Kalender übernehmen
        if (d != null)
          GestureDetector(
            onTap: () {
              cal.Add2Calendar.addEvent2Cal(cal.Event(
                title: title.isNotEmpty ? title : (loc.isNotEmpty ? loc : 'Termin'),
                description: desc,
                location: loc,
                startDate: d,
                endDate: d.add(const Duration(hours: 2)),
              ));
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 6, right: 4),
              child: Icon(Icons.event_available_rounded, color: cTextSecondary, size: 18),
            ),
          ),
        if (link.startsWith('http')) GestureDetector(onTap: () => _openUrl(link), child: const Icon(Icons.link_rounded, color: cOrange, size: 18)),
      ]));
  }
}

class LecturerDetailScreen extends StatefulWidget {
  final int id; final Map<String, dynamic> fallback;
  const LecturerDetailScreen({super.key, required this.id, required this.fallback});
  @override State<LecturerDetailScreen> createState() => _LecturerDetailScreenState();
}

class _LecturerDetailScreenState extends State<LecturerDetailScreen> {
  Map<String, dynamic>? _d;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final d = await PortalApiService.getLecturer(widget.id);
    if (mounted) setState(() => _d = d ?? widget.fallback);
  }

  @override Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final e = _d ?? widget.fallback;
    final name = pv(e, 'name');
    final intro = pv(e, 'intro');
    final bio = pv(e, 'description').isNotEmpty ? pv(e, 'description') : pv(e, 'bio');
    final courses = (e['courses'] is List) ? (e['courses'] as List).whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
    final linkPairs = <String, String>{
      'Website': pv(e, 'website'), 'X (Twitter)': pv(e, 'twitter').isNotEmpty ? pv(e, 'twitter') : pv(e, 'twitter_username'),
      'Nostr': pv(e, 'nostr'), 'Portal': pv(e, 'portalLink'),
    }..removeWhere((_, v) => v.isEmpty);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(backgroundColor: cDark, elevation: 0,
        title: Text(t.crsLecturer, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 17))),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        _headerCard(pImg(e), name, intro, Icons.person_rounded),
        if (bio.isNotEmpty) ...[_section(t.lecAbout),
          Text(bio, style: const TextStyle(color: cTextSecondary, fontSize: 14, height: 1.55))],
        if (courses.isNotEmpty) ...[
          _section(t.crsCourses),
          for (final c in courses)
            GestureDetector(
              onTap: (c['id'] is int) ? () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(id: c['id'] as int, fallback: c))) : null,
              child: _rowCard(pImg(c), pv(c, 'name'), '', Icons.school_rounded)),
        ],
        if (linkPairs.isNotEmpty) ...[
          _section(t.lecLinks),
          for (final kv in linkPairs.entries)
            Padding(padding: const EdgeInsets.only(bottom: 8),
              child: _linkRow(Icons.link_rounded, '${kv.key}: ${kv.value}', () {
                final v = kv.value;
                _openUrl(v.startsWith('http') ? v : (kv.key == 'X (Twitter)' ? 'https://x.com/$v' : 'https://$v'));
              })),
        ],
      ])),
    );
  }
}

// ── gemeinsame kleine Bausteine der Detailseiten ──
Widget _headerCard(String img, String title, String sub, IconData fb) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius + 2), border: Border.all(color: cTileBorder, width: 0.5)),
  child: Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(12),
      child: img.isNotEmpty
          ? Image.network(img, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fbIcon(fb))
          : _fbIcon(fb)),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w800)),
      if (sub.isNotEmpty) ...[const SizedBox(height: 3),
        Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cTextSecondary, fontSize: 12.5))],
    ])),
  ]));
Widget _fbSmall(IconData i) => Container(width: 40, height: 40,
  decoration: BoxDecoration(color: cNostr.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
  child: Icon(i, color: cNostr, size: 19));
Widget _fbIcon(IconData i) => Container(width: 64, height: 64,
  decoration: BoxDecoration(color: cNostr.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
  child: Icon(i, color: cNostr, size: 28));
Widget _section(String s) => Padding(padding: const EdgeInsets.only(top: 18, bottom: 10),
  child: Text(s, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w800)));
Widget _rowCard(String img, String title, String sub, IconData fb) => Container(
  margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cTileBorder, width: 0.5)),
  child: Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(9),
      child: img.isNotEmpty ? Image.network(img, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, _, _) => _fbSmall(fb)) : _fbSmall(fb)),
    const SizedBox(width: 11),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
      if (sub.isNotEmpty) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cTextTertiary, fontSize: 11.5)),
    ])),
    const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16),
  ]));
Widget _linkRow(IconData i, String label, VoidCallback onTap) => GestureDetector(onTap: onTap,
  child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: cOrange.withValues(alpha: 0.3), width: 0.5)),
    child: Row(children: [Icon(i, color: cOrange, size: 15), const SizedBox(width: 8),
      Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cOrange, fontSize: 13, fontWeight: FontWeight.w600)))])));
