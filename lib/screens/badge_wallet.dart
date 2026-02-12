import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';
import 'badge_details.dart';
import 'reputation_qr.dart';

// ============================================================
// GENERATIVE ART PAINTER
// Erzeugt ein einzigartiges Muster pro Badge basierend auf
// dem Meetup-Namen und der Blockhöhe (wie ein Fingerabdruck)
// ============================================================
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
      ..color = Colors.white.withOpacity(0.03)
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

class _BadgeWalletScreenState extends State<BadgeWalletScreen> {
  bool _compactView = false;

  void _shareAllBadges() async {
    if (myBadges.isEmpty) return;

    final user = await UserProfile.load();
    final uniqueMeetups = myBadges.map((b) => b.meetupName).toSet().length;

    final summary = '''
🏆 MEINE EINUNDZWANZIG REPUTATION

Total Badges: ${myBadges.length}
Meetups besucht: $uniqueMeetups
${user.nostrNpub.isNotEmpty ? 'Nostr: ${user.nostrNpub.substring(0, 24)}...' : ''}

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
          const SnackBar(
              content: Text('Reputation in Zwischenablage kopiert'),
              backgroundColor: cOrange),
        );
      }
    }
  }

  void _shareReputationJSON() async {
    if (myBadges.isEmpty) return;

    final user = await UserProfile.load();
    final json =
        MeetupBadge.exportBadgesForReputation(
          myBadges,
          user.nostrNpub,
          nickname: user.nickname,
          telegram: user.telegramHandle,
          twitter: user.twitterHandle,
        );

    try {
      await Share.share(json, subject: 'Einundzwanzig Reputation (JSON)');
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('JSON-Daten in Zwischenablage kopiert'),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("REPUTATION TEILEN",
                style: TextStyle(
                    color: cOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share, color: cCyan),
              title: const Text("Als Text teilen",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text("Lesbar für alle (wird im Web kopiert)",
                  style: TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _shareAllBadges();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: cOrange),
              title: const Text("QR-Code anzeigen",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text("Zum Scannen vor Ort",
                  style: TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (c) => const ReputationQRScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: cPurple),
              title: const Text("Als JSON exportieren",
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text("Mit Checksumme zur Verifizierung",
                  style: TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _shareReputationJSON();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Abbrechen", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  // Blockhöhe leserlich formatieren: 850000 → 850.000
  String _formatBlock(int height) {
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
          // Toggle erst ab 7+ Badges anzeigen
          if (myBadges.length > 6)
            IconButton(
              icon: Icon(_compactView ? Icons.grid_view : Icons.view_comfy),
              tooltip: _compactView ? 'Normal' : 'Kompakt',
              onPressed: () => setState(() => _compactView = !_compactView),
            ),
          if (myBadges.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Reputation teilen',
              onPressed: _showShareOptions,
            ),
        ],
      ),
      body: myBadges.isEmpty
          ? _buildEmptyState(context)
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _compactView ? 3 : 2,
                childAspectRatio: _compactView ? 0.75 : 0.80,
                crossAxisSpacing: _compactView ? 8 : 12,
                mainAxisSpacing: _compactView ? 8 : 12,
              ),
              itemCount: myBadges.length,
              itemBuilder: (context, index) {
                final badge = myBadges[index];
                return _compactView
                    ? _buildCompactCard(context, badge, index)
                    : _buildBadgeCard(context, badge, index);
              },
            ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.collections_bookmark_outlined,
              size: 100, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text("Noch keine Badges gesammelt",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: cTextSecondary)),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Besuche Meetups und scanne NFC-Tags um Badges zu sammeln!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NORMAL VIEW (2 Spalten)
  // ============================================================
  Widget _buildBadgeCard(BuildContext context, MeetupBadge badge, int index) {
    final seed = "${badge.meetupName}:${badge.blockHeight}";

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (c) => BadgeDetailsScreen(badge: badge))),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cOrange.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
                color: cOrange.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. GENERATIVE ART
            CustomPaint(painter: BadgeArtPainter(seed: seed)),

            // 2. DUNKLER VERLAUF UNTEN
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.8),
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
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: cOrange.withOpacity(0.5)),
                        ),
                        child: const Icon(Icons.verified,
                            color: cOrange, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("#${index + 1}",
                            style: const TextStyle(
                                color: cOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
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
                            color: Colors.white.withOpacity(0.5),
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
          border: Border.all(color: cOrange.withOpacity(0.3), width: 0.8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: BadgeArtPainter(seed: seed)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
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
                              color: cOrange.withOpacity(0.8),
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
    );
  }
}
