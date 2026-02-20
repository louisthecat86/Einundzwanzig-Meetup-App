// ============================================
// REPUTATION QR-CODE SCREEN v4 — CLEAN & PRO
// ============================================

import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../services/trust_score_service.dart';
import 'qr_scanner.dart';

class ReputationQRScreen extends StatefulWidget {
  const ReputationQRScreen({super.key});

  @override
  State<ReputationQRScreen> createState() => _ReputationQRScreenState();
}

class _ReputationQRScreenState extends State<ReputationQRScreen> {
  String _qrData = '';
  bool _isLoading = true;
  UserProfile _user = UserProfile();
  TrustScore? _trustScore;
  int _verifiedBadgeCount = 0;

  // Key für QR-Screenshot
  final GlobalKey _qrRepaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _generateQRData();
  }

  void _generateQRData() async {
    final user = await UserProfile.load();

    // Kein QR generieren wenn keine Badges vorhanden
    if (myBadges.isEmpty) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
      return;
    }

    final uniqueMeetups = myBadges.map((b) => b.meetupName).toSet();
    final uniqueSigners = myBadges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet();

    // Trust Score
    final sortedByDate = List<MeetupBadge>.from(myBadges)
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstBadgeDate = sortedByDate.isNotEmpty ? sortedByDate.first.date : null;
    
    final trustScore = TrustScoreService.calculateScore(
      badges: myBadges,
      firstBadgeDate: firstBadgeDate,
      coAttestorMap: null,
    );

    // Badge-Proof
    final badgeProof = MeetupBadge.generateBadgeProof(myBadges);
    final verifiedCount = MeetupBadge.countVerifiedBadges(myBadges);

    // Payload
    final Map<String, dynamic> identity = {
      'n': user.nickname.isEmpty ? 'Anon' : user.nickname,
    };
    if (user.nostrNpub.isNotEmpty) identity['np'] = user.nostrNpub;
    if (user.telegramHandle.isNotEmpty) identity['tg'] = user.telegramHandle;
    if (user.twitterHandle.isNotEmpty) identity['tw'] = user.twitterHandle;

    final Map<String, dynamic> reputation = {
      'sc': double.parse(trustScore.totalScore.toStringAsFixed(1)),
      'lv': trustScore.level,
      'bc': myBadges.length,
      'vc': verifiedCount,
      'mc': uniqueMeetups.length,
      'si': uniqueSigners.length,
      'ad': trustScore.accountAgeDays,
    };
    if (uniqueMeetups.isNotEmpty) {
      reputation['ml'] = uniqueMeetups.take(10).toList();
    }

    final Map<String, dynamic> proof = {
      'bp': badgeProof,
      'vc': verifiedCount,
      'tc': myBadges.length,
    };

    final Map<String, dynamic> qrPayload = {
      'v': 3,
      'id': identity,
      'rp': reputation,
      'pf': proof,
      't': DateTime.now().millisecondsSinceEpoch,
    };

    final jsonString = jsonEncode(qrPayload);
    final signResult = await BadgeSecurity.signQRv3(jsonString);
    final base64Json = base64Encode(utf8.encode(jsonString));

    String secureQrData;
    if (signResult.isNostr) {
      secureQrData = "21v3:$base64Json"
          ".${signResult.signature}"
          ".${signResult.eventId}"
          ".${signResult.createdAt}"
          ".${signResult.pubkeyHex}";
    } else {
      secureQrData = "21:$base64Json.${signResult.signature}";
    }

    setState(() {
      _qrData = secureQrData;
      _user = user;
      _trustScore = trustScore;
      _verifiedBadgeCount = verifiedCount;
      _isLoading = false;
    });
  }

  bool get _hasIdentity {
    if (_isLoading) return false;
    return _user.nostrNpub.isNotEmpty ||
        _user.telegramHandle.isNotEmpty ||
        _user.twitterHandle.isNotEmpty;
  }

  // =============================================
  // QR ALS BILD TEILEN
  // =============================================
  Future<void> _shareQRImage() async {
    try {
      final boundary = _qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/einundzwanzig_reputation.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Einundzwanzig Reputation',
        text: 'Meine verifizierte Meetup-Reputation',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Teilen: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =============================================
  // TRUST LEVEL → ICON + FARBE
  // =============================================
  static IconData levelIcon(String level) {
    switch (level) {
      case 'VETERAN': return Icons.bolt;
      case 'ETABLIERT': return Icons.shield;
      case 'AKTIV': return Icons.local_fire_department;
      case 'STARTER': return Icons.eco;
      default: return Icons.fiber_new;
    }
  }

  static Color levelColor(String level) {
    switch (level) {
      case 'VETERAN': return Colors.amber;
      case 'ETABLIERT': return Colors.green;
      case 'AKTIV': return cCyan;
      case 'STARTER': return cOrange;
      default: return Colors.grey;
    }
  }

  // =============================================
  // UI
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("REPUTATION"),
        actions: [
          // Scanner-Button — IMMER verfügbar
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: cCyan),
            tooltip: 'Reputation prüfen',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecureQRScanner()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : myBadges.isEmpty
              ? _buildNoBadgesView()
              : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Warnung wenn keine Identität
                  if (!_hasIdentity)
                    _buildWarningBanner(),

                  // Trust Score Header
                  if (_trustScore != null)
                    _buildTrustHeader(),

                  const SizedBox(height: 20),

                  // QR Code (mit RepaintBoundary für Screenshot)
                  RepaintBoundary(
                    key: _qrRepaintKey,
                    child: _buildQRCard(),
                  ),

                  const SizedBox(height: 20),

                  // Stats
                  _buildStatsRow(),

                  const SizedBox(height: 20),

                  // Badge-Proof Status
                  _buildProofStatus(),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActions(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildNoBadgesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: cOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, color: cOrange, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              "NOCH KEINE REPUTATION",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Text(
              "Besuche ein Meetup und scanne einen Badge um deine Reputation aufzubauen.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecureQRScanner()),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("REPUTATION PRÜFEN"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cCyan,
                  side: const BorderSide(color: cCyan, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade700.withOpacity(0.5)),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(
            "Keine Identität verknüpft. Ergänze Telegram oder Nostr in deinem Profil.",
            style: TextStyle(color: Colors.red.shade300, fontSize: 12, height: 1.4),
          )),
        ]),
      ),
    );
  }

  Widget _buildTrustHeader() {
    final score = _trustScore!;
    final color = levelColor(score.level);
    final icon = levelIcon(score.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        // Icon statt Emoji
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          score.level,
          style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        const SizedBox(height: 4),
        Text(
          "Score ${score.totalScore.toStringAsFixed(1)}",
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildQRCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cOrange.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        QrImageView(
          data: _qrData,
          version: QrVersions.auto,
          size: 260,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.L,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _hasIdentity ? Icons.verified_user : Icons.lock_outline,
              color: _hasIdentity ? Colors.green.shade700 : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _hasIdentity ? "Schnorr-signiert" : "Signiert (ohne Identität)",
              style: TextStyle(
                color: _hasIdentity ? Colors.green.shade700 : Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildStatsRow() {
    final score = _trustScore;
    return Row(children: [
      _buildStat(Icons.military_tech, "${myBadges.length}", "Badges", cOrange),
      const SizedBox(width: 10),
      _buildStat(Icons.location_on, "${score?.uniqueMeetups ?? 0}", "Meetups", cCyan),
      const SizedBox(width: 10),
      _buildStat(Icons.people_outline, "${score?.uniqueSigners ?? 0}", "Signer", cPurple),
      const SizedBox(width: 10),
      _buildStat(Icons.calendar_today, "${score?.accountAgeDays ?? 0}", "Tage", Colors.green),
    ]);
  }

  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildProofStatus() {
    final total = myBadges.length;
    final verified = _verifiedBadgeCount;
    final allVerified = total > 0 && verified == total;

    final Color c = allVerified ? Colors.green : (verified > 0 ? cOrange : Colors.grey);
    final IconData icon = allVerified ? Icons.verified : (verified > 0 ? Icons.shield_outlined : Icons.info_outline);
    final String text = allVerified
        ? "Alle $total Badges kryptographisch verifiziert"
        : verified > 0
            ? "$verified von $total Badges mit Schnorr-Beweis"
            : "Noch keine kryptographischen Beweise";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildActions() {
    return Column(children: [
      // Primär: QR als Bild teilen
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _shareQRImage,
          icon: const Icon(Icons.share, size: 20),
          label: const Text("QR ALS BILD TEILEN"),
          style: ElevatedButton.styleFrom(
            backgroundColor: cOrange,
            foregroundColor: Colors.black,
          ),
        ),
      ),
    ]);
  }
}