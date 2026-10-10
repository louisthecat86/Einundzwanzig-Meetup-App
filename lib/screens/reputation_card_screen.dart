import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/shadows.dart';
import '../l10n/level_labels.dart';
import '../models/user.dart';
import '../models/badge.dart';
import '../services/trust_score_service.dart';
import '../services/badge_claim_service.dart';
import '../utils/share_origin.dart';

/// Teilbares Reputations-Profil als schön gestaltete Karte.
/// Export als PNG via RepaintBoundary -> share_plus.
class ReputationCardScreen extends StatefulWidget {
  const ReputationCardScreen({super.key});
  @override
  State<ReputationCardScreen> createState() => _ReputationCardScreenState();
}

class _ReputationCardScreenState extends State<ReputationCardScreen> {
  final GlobalKey _cardKey = GlobalKey();

  UserProfile? _user;
  TrustScore? _score;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await UserProfile.load();
    final badges = await MeetupBadge.loadBadges();
    await BadgeClaimService.ensureBadgesClaimed(badges);

    TrustScore score;
    if (badges.isEmpty) {
      score = TrustScoreService.calculateScore(badges: [], firstBadgeDate: null);
    } else {
      final sorted = List<MeetupBadge>.from(badges)..sort((a, b) => a.date.compareTo(b.date));
      score = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: sorted.first.date,
        coAttestorMap: null,
      );
    }
    if (!mounted) return;
    setState(() {
      _user = user;
      _score = score;
      _loading = false;
    });
  }

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final shareText = AppLocalizations.of(context).rcShareText;
    // Anker vor jeglichem await holen — warum: share_origin.dart (Issue #73).
    final shareOrigin = shareOriginFor(context);
    try {
      // Auf vollständiges Rendering des Boundary warten
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;

      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _sharing = false);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() => _sharing = false);
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      // Bytes direkt teilen statt selbst eine Datei zu schreiben —
      // path_provider hat keine Web-Implementierung. share_plus legt die
      // temporaere Datei auf iOS/Android selbst an. `name` greift im Web,
      // `fileNameOverrides` nativ.
      const fileName = 'einundzwanzig_reputation_card.png';
      await Share.shareXFiles(
        [XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: const [fileName],
        subject: 'Einundzwanzig Reputation',
        text: shareText,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).rcShareError(e.toString())),
            backgroundColor: cRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
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
        title: Text(t.rcTitle,
            style: const TextStyle(
                color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cOrange, strokeWidth: 2))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Die exportierbare Karte
                RepaintBoundary(
                  key: _cardKey,
                  child: _buildCard(t),
                ),
                const SizedBox(height: 24),
                _buildShareButton(t),
              ]),
            ),
    );
  }

  Widget _buildCard(AppLocalizations t) {
    final score = _score!;
    final user = _user!;
    final hasData = score.totalBadges > 0;
    final displayName = user.nickname.isNotEmpty
        ? user.nickname
        : (user.fullName.isNotEmpty ? user.fullName : t.rcMember);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1207), Color(0xFF23140B), cDark],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cOrange.withValues(alpha: 0.45), width: 1.2),
        boxShadow: shadowForElevation(4, accent: cOrange),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cOrange.withValues(alpha: 0.16),
              ),
            ),
          ),
          Column(
            children: [
              // Header: Branding
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.bolt, color: cOrange, size: 18),
                const SizedBox(width: 6),
                Text(
                  'EINUNDZWANZIG',
                  style: TextStyle(
                    color: cOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFamily: fontMono,
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                t.rcMember,
                style: const TextStyle(color: cTextSecondary, fontSize: 11, letterSpacing: 1),
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: cText, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),

              if (!hasData) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cSurface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cTileBorder, width: 0.5),
                  ),
                  child: Column(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cOrange.withValues(alpha: 0.13),
                        border: Border.all(color: cOrange.withValues(alpha: 0.24), width: 1),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: cOrange, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.rcNoData,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scanne deinen ersten Badge bei einem Meetup, um deine Reputation sichtbar zu machen.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.45),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Score-Hero
                _buildScoreHero(t, score),
                const SizedBox(height: 20),
                // Stat-Grid
                _buildStatGrid(t, score),
              ],

              const SizedBox(height: 20),
              Container(height: 0.5, color: cTileBorder),
              const SizedBox(height: 12),
              Text(
                '21Adress · Web of Trust',
                style: TextStyle(color: cTextTertiary, fontSize: 9, letterSpacing: 1, fontFamily: fontMono),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHero(AppLocalizations t, TrustScore score) {
    final levelText = localizedLevel(context, score.level);
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
          gradient: gradientOrange,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.3), blurRadius: 20)],
        ),
        child: Column(children: [
          Text(score.totalScore.toStringAsFixed(1),
              style: const TextStyle(
                  color: Colors.black, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 2),
          Text(t.rcLabelScore.toUpperCase(),
              style: const TextStyle(
                  color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
        ]),
      ),
      const SizedBox(height: 12),
      // Level-Badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cOrange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cOrange.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shield_rounded, color: cOrange, size: 14),
          const SizedBox(width: 6),
          Text(levelText.toUpperCase(),
              style: const TextStyle(
                  color: cOrange, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
      ),
    ]);
  }

  Widget _buildStatGrid(AppLocalizations t, TrustScore score) {
    final stats = [
      [Icons.style_rounded, '${score.totalBadges}', t.rcLabelBadges],
      [Icons.groups_rounded, '${score.uniqueMeetups}', t.rcLabelMeetups],
      [Icons.location_city_rounded, '${score.uniqueCities}', t.rcLabelCities],
      [Icons.verified_user_rounded, '${score.uniqueSigners}', t.rcLabelSigners],
      [Icons.calendar_month_rounded, '${score.accountAgeDays}', t.rcLabelAge],
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: stats.map((s) {
        return Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          child: Column(children: [
            Icon(s[0] as IconData, color: cOrange, size: 18),
            const SizedBox(height: 6),
            Text(s[1] as String,
                style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(s[2] as String,
                style: const TextStyle(color: cTextSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildShareButton(AppLocalizations t) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: cOrange,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: _sharing ? null : _shareImage,
        icon: _sharing
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Icon(Icons.ios_share_rounded, size: 18),
        label: Text(_sharing ? t.rcSaving : t.rcShareImage,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}
