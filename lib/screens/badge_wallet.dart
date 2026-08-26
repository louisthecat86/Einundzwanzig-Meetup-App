import 'dart:convert';
import 'calendar_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/meetup_crest_watermark.dart';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';

import '../l10n/app_localizations.dart';
import '../services/guide_service.dart';
import '../mixins/guide_service_host.dart';
import '../tours/more_tours.dart';
import '../models/badge.dart';
import 'badge_world_map_screen.dart';
import '../models/user.dart';
import 'badge_details.dart';
import 'reputation_qr.dart';
import '../services/reputation_publisher.dart';
import '../services/app_logger.dart';

// ============================================================
// GENERATIVE ART PAINTER
// Erzeugt ein einzigartiges Muster pro Badge basierend auf
// dem Meetup-Namen und der Blockhöhe (wie ein Fingerabdruck)
// ============================================================
/// Alle Badges EINES Meetups.
///
/// Eigener Bildschirm statt eines aufklappbaren Abschnitts: Wer hierher
/// kommt, sucht ein bestimmtes Badge — und will dann die ganze Flaeche dafuer,
/// nicht einen Ausschnitt zwischen anderen Sammlungen.
class _CollectionScreen extends StatelessWidget {
  final String title;
  final List<MeetupBadge> badges;

  /// Die Gesamtsammlung — nur fuer die Nummerierung. "#3" soll ueberall
  /// dasselbe Badge meinen.
  final List<MeetupBadge> allBadges;

  const _CollectionScreen({
    required this.title,
    required this.badges,
    required this.allBadges,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: cText, fontSize: 15, fontWeight: FontWeight.w800)),
          Text(
              AppLocalizations.of(context).walletCollectionCount(badges.length),
              style: const TextStyle(color: cTextTertiary, fontSize: 10.5)),
        ]),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.80,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: badges.length,
        itemBuilder: (context, i) {
          final badge = badges[i];
          return _BadgeCardTile(
              badge: badge, index: allBadges.indexOf(badge));
        },
      ),
    );
  }
}

/// Duenne Huelle, damit die Karten-Darstellung des Wallet-States auch
/// ausserhalb davon nutzbar ist.
class _BadgeCardTile extends StatelessWidget {
  final MeetupBadge badge;
  final int index;

  const _BadgeCardTile({required this.badge, required this.index});

  @override
  Widget build(BuildContext context) {
    return _BadgeWalletScreenState.buildCard(context, badge, index);
  }
}

class BadgeArtPainter extends CustomPainter {
  final String seed;
  late final List<int> _hashBytes;

  BadgeArtPainter({required this.seed}) {
    final bytes = utf8.encode(seed);
    _hashBytes = sha256.convert(bytes).bytes;
  }

  int _byte(int i) => _hashBytes[i % _hashBytes.length];

  Color _colorFromHash(int offset, double opacity) {
    // Bitcoin-Orange-Palette: Warme Töne mit Gold/Amber/Kupfer
    int r = (_byte(offset) * 0.5 + 0.5 * 247).round().clamp(100, 255);
    int g = (_byte(offset + 1) * 0.35 + 0.2 * 147).round().clamp(30, 200);
    int b = (_byte(offset + 2) * 0.2).round().clamp(0, 80);
    return Color.fromRGBO(r, g, b, opacity);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. HINTERGRUND GRADIENT
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _colorFromHash(0, 0.3),
          _colorFromHash(3, 0.15),
          _colorFromHash(6, 0.25),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. GEOMETRISCHE FORMEN
    final int shapeCount = 5 + (_byte(9) % 6);

    for (int i = 0; i < shapeCount; i++) {
      final int idx = 10 + i * 3;
      final double cx = (_byte(idx) / 255.0) * w;
      final double cy = (_byte(idx + 1) / 255.0) * h;
      final double radius = 10 + (_byte(idx + 2) / 255.0) * (w * 0.35);
      final int shapeType = _byte(idx) % 4;

      final paint = Paint()
        ..color = _colorFromHash(idx, 0.08 + (_byte(idx + 2) % 10) * 0.01)
        ..style = (_byte(idx + 1) % 3 == 0)
            ? PaintingStyle.stroke
            : PaintingStyle.fill
        ..strokeWidth = 1.5;

      switch (shapeType) {
        case 0: // Kreis
          canvas.drawCircle(Offset(cx, cy), radius, paint);
          break;
        case 1: // Raute
          final path = Path()
            ..moveTo(cx, cy - radius * 0.6)
            ..lineTo(cx + radius * 0.4, cy)
            ..lineTo(cx, cy + radius * 0.6)
            ..lineTo(cx - radius * 0.4, cy)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case 2: // Hexagon
          final path = Path();
          for (int j = 0; j < 6; j++) {
            final angle = (pi / 3) * j - pi / 6;
            final x = cx + radius * 0.5 * cos(angle);
            final y = cy + radius * 0.5 * sin(angle);
            if (j == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
          break;
        case 3: // Diagonale Linien
          final linePaint = Paint()
            ..color = _colorFromHash(idx, 0.06)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          for (int l = 0; l < 4; l++) {
            final offset = l * radius * 0.3;
            canvas.drawLine(
              Offset(cx - radius + offset, cy - radius),
              Offset(cx + radius + offset, cy + radius),
              linePaint,
            );
          }
          break;
      }
    }

    // 3. FEINES RASTER (Grid-Overlay)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    final gridSize = 12.0 + (_byte(30) % 8);
    for (double x = 0; x < w; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BadgeArtPainter old) => old.seed != seed;
}

// ============================================================
// BADGE WALLET SCREEN
// ============================================================
class BadgeWalletScreen extends StatefulWidget {
  const BadgeWalletScreen({super.key});

  @override
  State<BadgeWalletScreen> createState() => _BadgeWalletScreenState();
}

class _BadgeWalletScreenState extends State<BadgeWalletScreen>
    with GuideServiceHost {
  @override
  void initState() {
    super.initState();
    _startTour();
  }

  /// Tour beim ersten Oeffnen. Die kurze Verzoegerung gibt dem Bildschirm
  /// Zeit, sich mit Daten zu zeichnen — vorher gaebe es die Badge-Karten
  /// noch nicht, auf die der erste Schritt zeigt.
  Future<void> _startTour() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final guide = this.guide;
    if (await guide.wasTourCompleted(GuideTour.wallet)) return;
    if (!mounted) return;
    await guide.startTour(GuideTour.wallet, WalletTour.steps());
  }

  bool _compactView = false;

  // ============================================================
  // BIBLIOTHEKS-ANSICHT
  // Eine flache Liste wird ab ~15 Badges unuebersichtlich. Deshalb:
  // Suche + umschaltbare Gruppierung + einklappbare Abschnitte.
  // Die Badge-Karten selbst bleiben unveraendert.
  // ============================================================
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _groupByMeetup = true;          // false = nach Jahr gruppieren
  final Set<String> _collapsed = <String>{};

  /// Interner Gruppenschluessel fuer Organisator-Marker.
  static const String _organizerGroupKey = '\u0000organizer';

  @override
  void dispose() {
    // Bildschirm zu, Tour raus — sonst suchte das Overlay Ziele, die es
    // nicht mehr gibt.
    finishGuideTourIfActive(GuideTour.wallet);

    _searchCtrl.dispose();
    super.dispose();
  }

  /// Badges, die zum Suchbegriff passen (Meetup-Name).
  List<MeetupBadge> get _filteredBadges {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return myBadges;
    return myBadges.where((b) => b.meetupName.toLowerCase().contains(q)).toList();
  }

  /// Gruppiert nach Meetup oder Jahr.
  /// Meetup: groesste Sammlung zuerst. Jahr: neuestes zuerst.
  /// Innerhalb einer Gruppe immer das neueste Badge zuerst.
  List<MapEntry<String, List<MeetupBadge>>> _buildGroups() {
    final map = <String, List<MeetupBadge>>{};
    for (final b in _filteredBadges) {
      final name = b.meetupName.trim();
      // Organisator-Marker bekommen einen EIGENEN Abschnitt — sonst stehen
      // sie unter derselben Ueberschrift wie echte Badges desselben Meetups
      // und sehen aus wie Duplikate.
      final key = b.isOrganizer
          ? _organizerGroupKey
          : (_groupByMeetup ? (name.isEmpty ? '?' : name) : b.date.year.toString());
      map.putIfAbsent(key, () => <MeetupBadge>[]).add(b);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }
    final entries = map.entries.toList();
    if (_groupByMeetup) {
      entries.sort((a, b) {
        final byCount = b.value.length.compareTo(a.value.length);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    } else {
      entries.sort((a, b) => b.key.compareTo(a.key));
    }
    // Organisator-Abschnitt immer ans Ende, egal wie gruppiert wird.
    final orgIdx = entries.indexWhere((e) => e.key == _organizerGroupKey);
    if (orgIdx >= 0) entries.add(entries.removeAt(orgIdx));
    return entries;
  }

  void _shareAllBadges() async {
    if (myBadges.isEmpty) return;

    final user = await UserProfile.load();
    final uniqueMeetups = myBadges.map((b) => b.meetupName).toSet().length;

    final summary = '''
🏆 MEINE EINUNDZWANZIG REPUTATION

Total Badges: ${myBadges.length}
Meetups besucht: $uniqueMeetups
${user.nostrNpub.isNotEmpty ? 'Nostr: ${user.nostrNpub}' : ''}

📍 Besuchte Meetups:
${myBadges.map((b) => '  • ${b.meetupName} (${b.date.day}.${b.date.month}.${b.date.year})').join('\n')}

✅ Proof of Attendance
Verifizierbar über die Einundzwanzig Meetup App

---
Exportiert am ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}
    ''';

    try {
      await Share.share(summary,
          subject: 'Meine Einundzwanzig Meetup Reputation');
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: summary));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).walletReputationCopied),
              backgroundColor: cOrange),
        );
      }
    }
  }

  void _shareReputationJSON() async {
    if (myBadges.isEmpty) return;

    final user = await UserProfile.load();
    final json = MeetupBadge.exportBadgesForReputation(
          myBadges,
          user.nostrNpub,
          nickname: user.nickname,
          telegram: user.telegramHandle,
          twitter: user.twitterHandle,
        );

    try {
      await Share.share(json, subject: 'Einundzwanzig Reputation (v4, signiert)');
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).walletJsonCopied),
              backgroundColor: cOrange),
        );
      }
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      builder: (context) => Container(
        padding: const EdgeInsets.all(100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).walletShareReputation,
                style: const TextStyle(
                    color: cOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share, color: cCyan),
              title: Text(AppLocalizations.of(context).walletShareText,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(AppLocalizations.of(context).walletShareTextSub,
                  style: const TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _shareAllBadges();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: cOrange),
              title: Text(AppLocalizations.of(context).walletShowQr,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(AppLocalizations.of(context).walletShowQrSub,
                  style: const TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (c) => const ReputationQRScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: cPurple),
              title: Text(AppLocalizations.of(context).walletExportJson,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text(AppLocalizations.of(context).walletExportJsonSub,
                  style: const TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _shareReputationJSON();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text(AppLocalizations.of(context).cancel, style: const TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // Blockhöhe leserlich formatieren: 850000 → 850.000
  static String _formatBlock(int height) {
    if (height <= 0) return "---";
    final str = height.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write('.');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(
            "BADGE WALLET${myBadges.isNotEmpty ? ' (${myBadges.length})' : ''}"),
        actions: [
          // Weltkarte — immer erreichbar, sobald Badges existieren
          if (myBadges.isNotEmpty)
            IconButton(
              key: WalletTour.mapKey,
              icon: const Icon(Icons.public_rounded),
              tooltip: AppLocalizations.of(context).mapButton,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BadgeWorldMapScreen(badges: myBadges))),
            ),
          // Toggle erst ab 7+ Badges anzeigen
          if (myBadges.length > 6)
            IconButton(
              key: WalletTour.viewKey,
              icon: Icon(_compactView ? Icons.grid_view : Icons.view_comfy),
              tooltip: _compactView ? 'Normal' : 'Kompakt',
              onPressed: () => setState(() => _compactView = !_compactView),
            ),
          // Bereinigen-Knopf NUR anzeigen, wenn es wirklich Duplikate gibt.
          if (_duplicateBadges().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded),
              tooltip: AppLocalizations.of(context).walletCleanupTitle,
              onPressed: _showCleanupDialog,
            ),
          if (myBadges.isNotEmpty)
            IconButton(
              key: WalletTour.shareKey,
              icon: const Icon(Icons.share),
              tooltip: AppLocalizations.of(context).walletShareTitle,
              onPressed: _showShareOptions,
            ),
        ],
      ),
      body: myBadges.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                _buildLibraryControls(context),
                Expanded(child: _buildGroupedBadges(context)),
              ],
            ),
    );
  }

  // ============================================================
  // DUPLIKATE BEREINIGEN
  // ============================================================
  // Beim Feldtest konnten identische Badges mehrfach in die Wallet gelangen.
  // Der Schutz dagegen greift jetzt beim Sammeln — die bereits entstandenen
  // Kopien bleiben aber liegen.
  //
  // WARUM DAS UNBEDENKLICH IST: Ein Duplikat traegt dieselbe meetupEventId
  // wie das Original. Die Teilnahme-Bestaetigung im Netzwerk (Kind 30079)
  // nutzt genau diese ID als d-Tag, existiert also pro Meetup ohnehin nur
  // EINMAL — ein Duplikat hat dort nie eine eigene Verknuepfung erzeugt.
  // Entfernen aendert daher nur die lokale Sammlung sowie Zaehler und
  // Proof-Hash im (ersetzbaren) Reputations-Event. Das Original bleibt
  // IMMER erhalten: behalten wird das aelteste Badge je Schluessel.

  /// Die Badges, die beim Bereinigen entfernt wuerden (alle ausser dem
  /// jeweils aeltesten Original).
  List<MeetupBadge> _duplicateBadges() {
    // Organisator-Marker ausklammern: Sie teilen sich die meetupEventId mit
    // dem echten Badge desselben Meetups, sind aber etwas anderes — sie
    // duerfen weder als Duplikat gelten noch eines verdraengen.
    final sorted = myBadges.where((b) => !b.isOrganizer).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final seen = <String>{};
    final dups = <MeetupBadge>[];
    for (final b in sorted) {
      if (!seen.add(MeetupBadge.identityKey(b))) dups.add(b);
    }
    return dups;
  }

  void _showCleanupDialog() {
    final t = AppLocalizations.of(context);
    final dups = _duplicateBadges();

    if (dups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.walletCleanupNone),
        backgroundColor: cSurface,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Betroffene Meetups zusammenfassen: "Koblenz (2x)"
    final counts = <String, int>{};
    for (final b in dups) {
      final n = b.meetupName.trim().isEmpty ? '?' : b.meetupName.trim();
      counts[n] = (counts[n] ?? 0) + 1;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.cleaning_services_rounded, color: cOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(t.walletCleanupTitle,
              style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.walletCleanupBody(dups.length),
              style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          ...counts.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  const Icon(Icons.remove_circle_outline_rounded, color: cRed, size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${e.key} (${e.value}x)',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: cText, fontSize: 12.5))),
                ]),
              )),
          const SizedBox(height: 12),
          Text(t.walletCleanupHint,
              style: const TextStyle(color: cTextTertiary, fontSize: 11.5, height: 1.35)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.dialogCancel, style: const TextStyle(color: cTextSecondary)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _removeDuplicates(dups); },
            child: Text(t.walletCleanupConfirm,
                style: const TextStyle(color: cOrange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeDuplicates(List<MeetupBadge> dups) async {
    final t = AppLocalizations.of(context);
    // Identitaetsvergleich: es werden genau die Objekte entfernt, die der
    // Dialog angezeigt hat — kein erneutes Berechnen, keine Ueberraschungen.
    final kept = myBadges.where((b) => !dups.any((d) => identical(d, b))).toList();
    final removed = myBadges.length - kept.length;

    await MeetupBadge.saveBadges(kept);
    myBadges = kept;
    AppLogger.diag('Wallet', '$removed doppelte Badge(s) entfernt. Neu: ${kept.length}.');
    // Reputation neu veroeffentlichen: Zaehler und Proof-Hash aendern sich.
    ReputationPublisher.publishInBackground(kept);

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t.walletCleanupDone(removed)),
      backgroundColor: cGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ============================================================
  // BIBLIOTHEK: Suchleiste + Gruppierungs-Umschalter
  // ============================================================
  Widget _buildLibraryControls(BuildContext context) {
    final t = AppLocalizations.of(context);
    // Suchfeld erst ab 6 Badges — davor ist es nur im Weg.
    final showSearch = myBadges.length >= 6;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(children: [
        if (showSearch)
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: cText, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              hintText: t.walletSearchHint,
              hintStyle: const TextStyle(color: cTextTertiary, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: cOrange, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded, color: cTextTertiary, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: cCard,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cTileBorder, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cTileBorder, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: cOrange, width: 1),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        if (showSearch) const SizedBox(height: 10),
        Row(children: [
          _groupChip(t.walletGroupMeetup, Icons.place_rounded, _groupByMeetup,
              () => setState(() => _groupByMeetup = true)),
          const SizedBox(width: 8),
          _groupChip(t.walletGroupYear, Icons.event_rounded, !_groupByMeetup,
              () => setState(() => _groupByMeetup = false)),
        ]),
      ]),
    );
  }

  Widget _groupChip(String label, IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? cOrange.withValues(alpha: 0.16) : cCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? cOrange.withValues(alpha: 0.6) : cTileBorder,
              width: active ? 1 : 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: active ? cOrange : cTextTertiary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: active ? cOrange : cTextSecondary,
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }

  // ============================================================
  // BIBLIOTHEK: Abschnitte mit Kopfzeile (einklappbar)
  // ============================================================
  Widget _buildGroupedBadges(BuildContext context) {
    final t = AppLocalizations.of(context);
    final groups = _buildGroups();

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.search_off_rounded, color: cTextTertiary, size: 40),
            const SizedBox(height: 12),
            Text(t.walletNoResults,
                textAlign: TextAlign.center,
                style: const TextStyle(color: cTextTertiary, fontSize: 14)),
          ]),
        ),
      );
    }

    // SAMMLUNGEN statt Einzelstuecke.
    //
    // Vorher standen unter "ASCHAFFENBURG (20)" zwanzig fast gleiche Karten
    // untereinander — gleiches Wappen, gleicher Name, unterscheidbar nur am
    // Datum. Das ist keine Sammlung, sondern ein Kontoauszug.
    //
    // Bei Gruppierung nach MEETUP zeigt die Liste deshalb je Ort EINE Karte
    // mit Anzahl und Zeitraum; ein Tipp oeffnet die Einzelstuecke. Nach JAHR
    // gruppiert bleibt es bei der flachen Liste — dort ist jedes Badge ein
    // eigener Eintrag und die Zusammenfassung waere sinnlos.
    if (_groupByMeetup) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: groups.length,
        itemBuilder: (context, gi) {
          final entry = groups[gi];
          return KeyedSubtree(
            key: gi == 0 ? WalletTour.firstBadgeKey : null,
            child: _buildCollectionCard(context, entry.key, entry.value),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: groups.length,
      itemBuilder: (context, gi) {
        final entry = groups[gi];
        final isCollapsed = _collapsed.contains(entry.key);
        return Column(
            // Nur die ERSTE Gruppe traegt den Tour-Schluessel. Ein GlobalKey
            // darf im Baum nur einmal vorkommen — an jede Gruppe gehaengt
            // waere er ein Laufzeitfehler.
            key: gi == 0 ? WalletTour.firstBadgeKey : null,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader(context, entry.key, entry.value.length, isCollapsed),
          if (!isCollapsed) _badgeGrid(context, entry.value),
        ]);
      },
    );
  }

  /// Kopfzeile eines Abschnitts (Jahres-Ansicht).
  Widget _sectionHeader(
      BuildContext context, String key, int count, bool isCollapsed) {
    return GestureDetector(
      onTap: () => setState(() {
        if (isCollapsed) {
          _collapsed.remove(key);
        } else {
          _collapsed.add(key);
        }
      }),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Row(children: [
          Icon(
              key == _organizerGroupKey
                  ? Icons.shield_outlined
                  : Icons.event_rounded,
              color: key == _organizerGroupKey ? cTextSecondary : cOrange,
              size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
                key == _organizerGroupKey
                    ? AppLocalizations.of(context)
                        .walletOrganizerSection
                        .toUpperCase()
                    : key.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: key == _organizerGroupKey ? cTextSecondary : cOrange,
                    fontSize: 11.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: cOrange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8)),
            child: Text('$count',
                style: const TextStyle(
                    color: cOrange, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 4),
          Icon(isCollapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
              color: cTextTertiary, size: 20),
        ]),
      ),
    );
  }

  /// Raster der Einzel-Badges.
  Widget _badgeGrid(BuildContext context, List<MeetupBadge> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _compactView ? 3 : 2,
        childAspectRatio: _compactView ? 0.75 : 0.80,
        crossAxisSpacing: _compactView ? 8 : 12,
        mainAxisSpacing: _compactView ? 8 : 12,
      ),
      itemCount: badges.length,
      itemBuilder: (context, i) {
        final badge = badges[i];
        // Nummer bleibt die Position in der GESAMTsammlung, damit "#3"
        // ueberall dasselbe Badge meint — unabhaengig von Filter und
        // Gruppierung.
        final globalIndex = myBadges.indexOf(badge);
        return _compactView
            ? _buildCompactCard(context, badge, globalIndex)
            : buildCard(context, badge, globalIndex);
      },
    );
  }

  /// Eine Sammlung: alle Badges EINES Meetups auf einer Karte.
  ///
  /// Zeigt, was zwanzig Einzelkarten nicht zeigen: seit wann man dabei ist
  /// und wie lange der letzte Besuch her ist. Aus "seit Februar, zuletzt vor
  /// sechs Tagen" liest man Treue heraus — aus zwanzig Daten untereinander
  /// nicht.
  Widget _buildCollectionCard(
      BuildContext context, String key, List<MeetupBadge> badges) {
    final t = AppLocalizations.of(context);
    final isOrganizer = key == _organizerGroupKey;

    // Nach Datum sortieren — aeltestes und neuestes tragen die Zeitspanne.
    final sorted = [...badges]..sort((a, b) => a.date.compareTo(b.date));
    final first = sorted.first;
    final last = sorted.last;
    final cover = badges.firstWhere((b) => b.coverUrl.isNotEmpty,
        orElse: () => badges.first);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _CollectionScreen(
              title: isOrganizer
                  ? t.walletOrganizerSection
                  : (key.isEmpty ? '?' : key),
              badges: sorted.reversed.toList(),
              allBadges: myBadges,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(
                color: isOrganizer
                    ? cTileBorder
                    : cOrange.withValues(alpha: 0.3),
                width: 0.5),
          ),
          child: Row(children: [
            SizedBox(
              width: 52,
              height: 52,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: MeetupCrestWatermark(
                  meetupName: key,
                  imageUrl: cover.coverUrl.isNotEmpty ? cover.coverUrl : null,
                  opacity: 1.0,
                  widthFactor: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                            isOrganizer
                                ? t.walletOrganizerSection.toUpperCase()
                                : key.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: isOrganizer ? cTextSecondary : cText,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3)),
                      ),
                      const SizedBox(width: 8),
                      Text('×${badges.length}',
                          style: const TextStyle(
                              color: cOrange,
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 4),
                    Text(_collectionSubtitle(t, first, last, badges.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: cTextTertiary, fontSize: 11.5)),
                    const SizedBox(height: 8),
                    _countDots(badges.length),
                  ]),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: cTextTertiary, size: 20),
          ]),
        ),
      ),
    );
  }

  /// "seit Feb 2026 · zuletzt vor 6 Tagen"
  String _collectionSubtitle(
      AppLocalizations t, MeetupBadge first, MeetupBadge last, int count) {
    final since = t.walletSince(_monthYear(first.date));
    if (count == 1) return since;
    return '$since · ${t.walletLastVisit(_agoLabel(t, last.date))}';
  }

  String _monthYear(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _agoLabel(AppLocalizations t, DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return t.walletAgoToday;
    if (days == 1) return t.walletAgoYesterday;
    if (days < 30) return t.walletAgoDays(days);
    final months = (days / 30).floor();
    if (months < 12) return t.walletAgoMonths(months);
    return t.walletAgoYears((days / 365).floor());
  }

  /// Anzahl als Punktreihe. Ab 25 waere die Reihe laenger als die Karte —
  /// dann sagt die Zahl daneben ohnehin mehr.
  Widget _countDots(int count) {
    if (count > 24) return const SizedBox.shrink();
    return Wrap(
      spacing: 3,
      runSpacing: 3,
      children: List.generate(
        count,
        (_) => Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
              color: cOrange.withValues(alpha: 0.65), shape: BoxShape.circle),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(BuildContext context) {
    // Statt eines stummen grauen Symbols: Erklaerung plus konkreter Weg
    // nach vorn. Wer noch kein Badge hat, braucht zuerst ein Meetup.
    return EmptyState(
      icon: Icons.collections_bookmark_outlined,
      title: AppLocalizations.of(context).walletNoBadges,
      subtitle: AppLocalizations.of(context).walletNoBadgesSub,
      actionLabel: AppLocalizations.of(context).emptyFindMeetup,
      onAction: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
      accentColor: cOrange,
    );
  }

  /// Statisch, weil die Karte an keinem Zustand haengt — nur an Badge und
  /// Nummer. So kann der Sammlungs-Bildschirm dieselbe Darstellung nutzen,
  /// statt sie ein zweites Mal zu bauen.
  static Widget buildCard(
      BuildContext context, MeetupBadge badge, int index) {
    final seed = "${badge.meetupName}:${badge.blockHeight}";

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (c) => BadgeDetailsScreen(badge: badge))),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cOrange.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
                color: cOrange.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
            // 1. GENERATIVE ART
            CustomPaint(painter: BadgeArtPainter(seed: seed)),

            // 1b. MEETUP-WAPPEN als Wasserzeichen darueber. Macht jedes
            // Badge auf einen Blick zuordenbar. Faellt still weg, wenn
            // kein Wappen vorliegt — dann traegt die Grafik allein.
            // Bei Event-Badges das hochgeladene Bild statt der
            // Wappen-Suche — "Blocktrainer Event" steht in keiner
            // Meetup-Liste.
            MeetupCrestWatermark(
                meetupName: badge.meetupName,
                imageUrl: badge.coverUrl.isNotEmpty ? badge.coverUrl : null),

            // 2. DUNKLER VERLAUF UNTEN
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // 3. INHALT
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Nummer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: cOrange.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.verified,
                            color: cOrange, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          // Organisator-Marker: selbst erstelltes Meetup,
                          // unsigniert, zaehlt nicht zur Reputation.
                          if (badge.isOrganizer) ...[
                            const Icon(Icons.shield_outlined,
                                color: cTextSecondary, size: 11),
                            const SizedBox(width: 4),
                          ],
                          // Kennzeichnung: Praesenz konnte beim Sammeln nicht
                          // per Standort bestaetigt werden. Der Badge ist
                          // gueltig, zaehlt fuer die Reputation aber weniger.
                          if (!badge.presenceVerified && !badge.isOrganizer) ...[
                            const Icon(Icons.location_off_rounded,
                                color: cTextTertiary, size: 11),
                            const SizedBox(width: 4),
                          ],
                          Text("#${index + 1}",
                              style: const TextStyle(
                                  color: cOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Meetup Name – dynamische Schriftgröße
                  Text(
                    badge.meetupName.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badge.meetupName.length > 18 ? 11 : 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      height: 1.2,
                      shadows: const [
                        Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 6,
                            color: Colors.black),
                        Shadow(
                            offset: Offset(0, 0),
                            blurRadius: 12,
                            color: Colors.black54),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Datum
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 10, color: cOrangeLight),
                      const SizedBox(width: 4),
                      Text(
                        "${badge.date.day}.${badge.date.month}.${badge.date.year}",
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Blockhöhe
                  Row(
                    children: [
                      const Text("₿", style: TextStyle(color: cOrangeLight, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Block ${_formatBlock(badge.blockHeight)}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPACT VIEW (3 Spalten) – Für viele Badges
  // ============================================================
  Widget _buildCompactCard(
      BuildContext context, MeetupBadge badge, int index) {
    final seed = "${badge.meetupName}:${badge.blockHeight}";
    // Kurzer Name: "München, DE" → "MÜNCHEN"
    String shortName = badge.meetupName.split(',').first.trim().toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (c) => BadgeDetailsScreen(badge: badge))),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cOrange.withValues(alpha: 0.3), width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
            CustomPaint(painter: BadgeArtPainter(seed: seed)),
            // Wappen auch hier, aber zurueckhaltender — die kompakte
            // Karte hat weniger Platz und mehr Text pro Flaeche.
            MeetupCrestWatermark(
                meetupName: badge.meetupName,
                opacity: 0.17,
                widthFactor: 0.95,
                imageUrl: badge.coverUrl.isNotEmpty ? badge.coverUrl : null),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.verified, color: cOrange, size: 16),
                      Text("#${index + 1}",
                          style: TextStyle(
                              color: cOrange.withValues(alpha: 0.8),
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    shortName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: shortName.length > 12 ? 9 : 11,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      shadows: const [
                        Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 4,
                            color: Colors.black),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${badge.date.day}.${badge.date.month}.${badge.date.year}",
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}


