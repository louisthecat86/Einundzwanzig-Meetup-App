import 'dart:math';
import '../widgets/npub_chip.dart';
import '../services/haptic_service.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/badge.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../services/coattendance_service.dart';
import 'verify_person_screen.dart';

/// Automatische Übersicht des eigenen Co-Attendance-Netzwerks (Grad 1-3).
/// Kein npub-Input — lädt direkt beim Öffnen.
class MyNetworkScreen extends StatefulWidget {
  const MyNetworkScreen({super.key});

  @override
  State<MyNetworkScreen> createState() => _MyNetworkScreenState();
}

class _MyNetworkScreenState extends State<MyNetworkScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  MyNetwork? _net;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Teilnahmen, die zugestimmt, aber nicht veroeffentlicht wurden.
  int _failedCount = 0;
  bool _retrying = false;

  /// Sendet alle fehlgeschlagenen Teilnahmen erneut und laedt dann neu.
  Future<void> _retry() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _retrying = true);
    final badges = await MeetupBadge.loadBadges();
    final fixed = await CoAttendanceService.retryFailed(badges);
    if (!mounted) return;
    setState(() => _retrying = false);
    messenger.showSnackBar(SnackBar(
      content: Text(t.mnRetryResult(fixed, _failedCount)),
      backgroundColor: fixed > 0 ? cGreen : cRed,
    ));
    // Neu laden: Die jetzt angekommenen Teilnahmen erweitern das Netzwerk.
    _load();
  }

  /// Hinweis mit Knopf, solange Teilnahmen fehlen.
  ///
  /// Steht OBEN, noch vor der Einleitung: Fehlt eine eigene Teilnahme,
  /// fehlen auch alle Verbindungen, die daran haengen — das ist der Grund,
  /// falls das Netzwerk kleiner aussieht als erwartet.
  Widget _failedBanner(AppLocalizations t) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: cOrange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cOrange.withValues(alpha: 0.45), width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.cloud_off_rounded, color: cOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.mnFailedBanner(_failedCount),
                style: const TextStyle(color: cText, fontSize: 12.5, height: 1.4)),
          ),
          const SizedBox(width: 6),
          _retrying
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cOrange))
              : TextButton(
                  onPressed: _retry,
                  child: Text(t.mnRetry,
                      style: const TextStyle(
                          color: cOrange, fontWeight: FontWeight.w700)),
                ),
        ]),
      );

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await UserProfile.load();
      if (user.nostrNpub.isEmpty) {
        if (mounted) setState(() { _loading = false; _net = null; });
        return;
      }
      final net = await CoAttendanceService.buildMyNetwork(myNpub: user.nostrNpub);
      // Wie viele eigene Teilnahmen sind zugestimmt, aber nicht angekommen?
      final badges = await MeetupBadge.loadBadges();
      final failed = await CoAttendanceService.failedBadges(badges);
      if (mounted) {
        setState(() {
          _net = net;
          _failedCount = failed.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _net = null; });
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
        title: Text(t.mnTitle,
            style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded, color: cTextSecondary, size: 22),
            tooltip: t.mnCheckPerson,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VerifyPersonScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cOrange, strokeWidth: 2))
          : RefreshIndicator(
              color: cOrange,
              backgroundColor: cCard,
              onRefresh: _load,
              child: _net == null || _net!.isEmpty
                  ? _buildEmpty(t)
                  : _buildContent(t, _net!),
            ),
    );
  }

  Widget _buildEmpty(AppLocalizations t) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Gerade im LEEREN Netzwerk wichtig: Oft ist es leer, weil die
        // eigenen Teilnahmen nie angekommen sind.
        if (_failedCount > 0) _failedBanner(t),
        const SizedBox(height: 60),
        const Icon(Icons.hub_outlined, color: cTextTertiary, size: 56),
        const SizedBox(height: 20),
        Text(t.mnEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(t.mnEmptySub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 24),
        _eventNote(t),
      ],
    );
  }

  /// Hinweis: Veranstaltungen zaehlen nicht als Begegnung.
  ///
  /// Das ist gewollt — bei fuenfhundert Besuchern sagt gemeinsame
  /// Anwesenheit nichts darueber, ob man sich begegnet ist. Aber die App
  /// sagte es bisher nirgends. Wer nur Event-Badges hatte, sah ein leeres
  /// Netzwerk und hielt es fuer einen Fehler (Issue #57, Punkt 2).
  Widget _eventNote(AppLocalizations t) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline_rounded,
              color: cTextTertiary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.mnEventNote,
                style: const TextStyle(
                    color: cTextTertiary, fontSize: 12, height: 1.5)),
          ),
        ]),
      );

  Widget _buildContent(AppLocalizations t, MyNetwork net) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_failedCount > 0) _failedBanner(t),
        Text(t.mnIntro,
            style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
        const SizedBox(height: 12),
        _eventNote(t),
        const SizedBox(height: 20),

        // Interaktiver Netzwerk-Graph (geschwungene Verbindungen, antippbar)
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF15171C), Color(0xFF0D0E12)],
            ),
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final graphSize = Size(constraints.maxWidth, constraints.maxHeight);
              final nodes = _computeNodes(net, graphSize);
              return GestureDetector(
                onTapUp: (details) => _handleGraphTap(details.localPosition, nodes, t),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => CustomPaint(
                    painter: _NetworkGraphPainter(
                      nodes: nodes,
                      pulse: _pulse.value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Legende
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _legendDot(cGreen, t.mnLegendDirect),
          const SizedBox(width: 14),
          _legendDot(cCyan, t.mnLegendSecond),
          const SizedBox(width: 14),
          _legendDot(cOrange, t.mnLegendThird),
        ]),
        const SizedBox(height: 6),
        Center(child: Text(t.mnTapHint,
            style: const TextStyle(color: cTextTertiary, fontSize: 11, fontStyle: FontStyle.italic))),
        const SizedBox(height: 16),

        // Reichweiten-Kacheln
        Row(children: [
          _reachTile('${net.degree1Count}', t.mnDirectLabel, cGreen),
          const SizedBox(width: 8),
          _reachTile('${net.degree2Count}', '2.', cCyan),
          const SizedBox(width: 8),
          _reachTile('${net.degree3Count}', '3.', cOrange),
        ]),
        const SizedBox(height: 20),

        // Aufklappbare Listen pro Grad
        _degreeSection(t, net, 1, t.mnDegree1, t.mnDegree1Sub, cGreen),
        const SizedBox(height: 10),
        _degreeSection(t, net, 2, t.mnDegree2, t.mnDegree2Sub, cCyan),
        const SizedBox(height: 10),
        _degreeSection(t, net, 3, t.mnDegree3, t.mnDegree3Sub, cOrange),
        const SizedBox(height: 20),

        // Vertrauens-Hinweis
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cOrange.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, color: cOrange, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(t.mnTrustHint,
                style: const TextStyle(color: cTextSecondary, fontSize: 11, height: 1.4))),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          child: Row(children: [
            const Icon(Icons.privacy_tip_outlined, color: cTextTertiary, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text(t.mnPrivacyNote,
                style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4))),
          ]),
        ),
      ],
    );
  }

  Widget _reachTile(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 11)),
    ]);
  }

  /// Berechnet die Position aller Knoten im Graph. Du = Zentrum, die Grade
  /// auf konzentrischen Bahnen verteilt, leicht versetzt für organisches Bild.
  List<_GraphNode> _computeNodes(MyNetwork net, Size size) {
    final nodes = <_GraphNode>[];
    final center = Offset(size.width / 2, size.height / 2);

    // Zentrum = ich
    nodes.add(_GraphNode(
      pos: center, degree: 0, contact: null, radius: 13,
    ));

    final maxR = min(size.width, size.height) / 2 - 26;
    final ring = {1: maxR * 0.40, 2: maxR * 0.70, 3: maxR * 1.0};
    final colorFor = {1: cGreen, 2: cCyan, 3: cOrange};
    final nodeR = {1: 7.0, 2: 5.5, 3: 4.5};

    for (final deg in [1, 2, 3]) {
      final contacts = net.byDegree[deg] ?? [];
      if (contacts.isEmpty) continue;
      final shown = contacts.take(deg == 1 ? 12 : (deg == 2 ? 16 : 18)).toList();
      final r = ring[deg]!;
      // Winkel-Offset pro Grad, damit Knoten nicht exakt übereinander liegen
      final angleOffset = deg * 0.5;
      for (int i = 0; i < shown.length; i++) {
        final angle = (2 * pi * i / shown.length) - pi / 2 + angleOffset;
        final pos = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
        nodes.add(_GraphNode(
          pos: pos, degree: deg, contact: shown[i],
          radius: nodeR[deg]!, color: colorFor[deg],
        ));
      }
    }
    return nodes;
  }

  /// Findet den angetippten Knoten (nächster innerhalb Toleranz) und zeigt Details.
  void _handleGraphTap(Offset tap, List<_GraphNode> nodes, AppLocalizations t) {
    _GraphNode? hit;
    double best = 28; // Toleranz-Radius in px
    for (final n in nodes) {
      if (n.contact == null) continue; // Zentrum (ich) ignorieren
      final d = (n.pos - tap).distance;
      if (d < best) { best = d; hit = n; }
    }
    if (hit != null) {
      HapticService.light();
      _showNodeDetail(t, hit.contact!);
    }
  }

  /// Detail-Sheet zu einem angetippten Knoten: Grad, gemeinsame Meetups /
  /// Brücken, npub, Nostr-Link.
  void _showNodeDetail(AppLocalizations t, NetworkContact c) {
    final color = c.degree == 1 ? cGreen : (c.degree == 2 ? cCyan : cOrange);
    final degreeLabel = c.degree == 1 ? t.mnDegreeDirect : (c.degree == 2 ? t.mnDegreeSecond : t.mnDegreeThird);

    showModalBottomSheet(
      context: context,
      backgroundColor: cDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          // Kopf: Avatar + Grad
          Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)),
              child: Icon(c.degree == 1 ? Icons.person_rounded : Icons.person_outline_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(degreeLabel, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 4),
              NpubChip(c.npub, style: TextStyle(color: cText, fontSize: 13, fontFamily: fontMono)),
            ])),
          ]),
          const SizedBox(height: 18),
          // Grad-1: gemeinsame Meetups. Grad 2+: Brücken.
          if (c.degree == 1) ...[
            Text(t.mnSharedMeetupsList.toUpperCase(),
                style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            if (c.sharedMeetupsWithMe.isEmpty)
              Text(t.mnNoSharedDetail, style: const TextStyle(color: cTextSecondary, fontSize: 13))
            else
              ...c.sharedMeetupsWithMe.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.groups_rounded, color: cGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(m, style: const TextStyle(color: cText, fontSize: 14))),
                ]),
              )),
          ] else ...[
            Text(t.mnViaBridges.toUpperCase(),
                style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ...c.bridges.take(8).map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(Icons.hub_rounded, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(child: NpubChip(b, style: TextStyle(color: cText, fontSize: 13, fontFamily: fontMono))),
              ]),
            )),
          ],
          const SizedBox(height: 20),
          // Nostr öffnen
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: cText, side: const BorderSide(color: cTileBorder), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () { Navigator.pop(ctx); _openNostrProfile(c.npub); },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(t.mnOpenInNostr),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _degreeSection(AppLocalizations t, MyNetwork net, int degree,
      String title, String subtitle, Color color) {
    final contacts = net.byDegree[degree] ?? [];
    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: color,
          collapsedIconColor: cTextTertiary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Center(child: Text('$degree.',
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800))),
          ),
          title: Text(title,
              style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          subtitle: Text('${contacts.length} · $subtitle',
              style: const TextStyle(color: cTextTertiary, fontSize: 11)),
          children: contacts.isEmpty
              ? [Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('—', style: TextStyle(color: cTextTertiary)),
                )]
              : contacts.take(50).map((c) => _contactRow(t, c, color)).toList(),
        ),
      ),
    );
  }

  Widget _contactRow(AppLocalizations t, NetworkContact c, Color color) {
    String detail;
    if (c.degree == 1) {
      final n = c.sharedMeetupsWithMe.length;
      detail = n == 1 ? t.mnOneSharedMeetup : t.mnSharedMeetups(n);
    } else {
      final n = c.bridges.length;
      detail = n == 1 ? t.mnViaOneContact : t.mnViaContacts(n);
    }
    return InkWell(
      onTap: () => _openNostrProfile(c.npub),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: cTileBorder, width: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(
              c.degree == 1 ? Icons.person_rounded : Icons.person_outline_rounded,
              color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              NpubChip(c.npub, style: TextStyle(color: cText, fontSize: 13, fontFamily: fontMono)),
              const SizedBox(height: 2),
              Text(detail, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
            ]),
          ),
          Icon(Icons.open_in_new_rounded, color: cTextTertiary.withValues(alpha: 0.6), size: 15),
        ]),
      ),
    );
  }

  /// Öffnet das Nostr-Profil: erst per nostr:-Schema (installierte App),
  /// Fallback auf njump.me im Browser.
  Future<void> _openNostrProfile(String npub) async {
    final nostrUri = Uri.parse('nostr:$npub');
    final webUri = Uri.parse('https://njump.me/$npub');
    try {
      if (!await launchUrl(nostrUri, mode: LaunchMode.externalApplication)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}

/// Zeichnet konzentrische Ringe: Ich (Mitte) -> Grad 1 -> 2 -> 3.
/// Ein Knoten im Netzwerk-Graph mit Position und (optional) Kontaktdaten.
class _GraphNode {
  final Offset pos;
  final int degree;          // 0 = ich, 1/2/3 = Verbindungsgrad
  final NetworkContact? contact; // null beim Zentrum
  final double radius;
  final Color? color;
  _GraphNode({required this.pos, required this.degree, required this.contact, required this.radius, this.color});
}

/// Zeichnet das Netzwerk: geschwungene Bezier-Verbindungen vom Zentrum (ich)
/// zu jedem Knoten, farbcodiert nach Grad (grün/cyan/orange), mit sanftem Puls.
class _NetworkGraphPainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final double pulse; // 0..1 für sanfte Animation
  _NetworkGraphPainter({required this.nodes, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final center = nodes.first.pos; // Zentrum ist immer das erste Element

    // 1. Geschwungene Verbindungslinien (Zentrum -> Knoten)
    for (final n in nodes) {
      if (n.contact == null) continue;
      final color = n.color ?? cOrange;
      _drawCurvedConnection(canvas, center, n.pos, color);
    }

    // 2. Knoten zeichnen (nach Grad, damit nähere oben liegen)
    for (final n in nodes.where((n) => n.contact != null)) {
      final color = n.color ?? cOrange;
      // Glow
      final glow = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(n.pos, n.radius + 2, glow);
      // Kern
      canvas.drawCircle(n.pos, n.radius, Paint()..color = color);
      // heller Rand
      canvas.drawCircle(n.pos, n.radius, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.5));
    }

    // 3. Zentrum (ich) — pulsierender weißer Hub
    final pulseR = 13 + pulse * 3;
    canvas.drawCircle(center, pulseR + 6, Paint()
      ..color = cOrange.withValues(alpha: 0.18 + pulse * 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(center, 13, Paint()..color = Colors.white);
    canvas.drawCircle(center, 13, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = cOrange);
    // kleiner Blitz im Zentrum
    final icon = Paint()..color = cOrange;
    canvas.drawCircle(center, 4, icon);
  }

  /// Zeichnet eine geschwungene Verbindung (quadratische Bezier-Kurve) zwischen
  /// zwei Punkten — der Kontrollpunkt wird seitlich versetzt für den Bogen-Look.
  void _drawCurvedConnection(Canvas canvas, Offset from, Offset to, Color color) {
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    // Senkrechte zum Verbindungsvektor für den Bogen-Versatz
    final dir = to - from;
    final len = dir.distance;
    if (len < 1) return;
    final normal = Offset(-dir.dy / len, dir.dx / len);
    final bow = len * 0.18; // Stärke der Krümmung
    final control = mid + normal * bow;

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);

    // Farbverlauf entlang der Linie (am Knoten kräftiger, am Zentrum blasser)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(from, to, [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.65),
      ]);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NetworkGraphPainter old) =>
      old.pulse != pulse || old.nodes.length != nodes.length;
}
