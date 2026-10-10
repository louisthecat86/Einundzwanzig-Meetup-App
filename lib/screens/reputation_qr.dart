// ============================================
// REPUTATION QR-CODE SCREEN v6 — PROOF OF REPUTATION
// ============================================
// v6: Privacy-Meetups (gehashte Namen), eingebettete
//     Plattform-Proofs, kein separater Verify-String nötig
// ============================================

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../theme.dart';
import '../widgets/reputation_card_visual.dart';
import '../l10n/app_localizations.dart';
import '../models/badge.dart';
import '../models/user.dart';
import '../services/badge_security.dart';
import '../services/trust_score_service.dart';
import '../services/reputation_publisher.dart';
import '../services/platform_proof_service.dart';
import 'package:crypto/crypto.dart';
import 'qr_scanner.dart';
import 'reputation_card_screen.dart';
import '../utils/share_origin.dart';

class ReputationQRScreen extends StatefulWidget {
  const ReputationQRScreen({super.key});

  @override
  State<ReputationQRScreen> createState() => _ReputationQRScreenState();
}

class _ReputationQRScreenState extends State<ReputationQRScreen> {
  String _qrData = '';
  bool _isLoading = true;
  bool _isPublishing = false;
  UserProfile _user = UserProfile();
  TrustScore? _trustScore;
  int _verifiedBadgeCount = 0;
  int _boundBadgeCount = 0;
  int _platformProofCount = 0;
  String? _lastPublishInfo;

  // Key für QR-Screenshot
  final GlobalKey _qrRepaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _generateQRData();
  }

  void _generateQRData() async {
    final user = await UserProfile.load();

    // Plattform-Proofs zählen
    final proofs = await PlatformProofService.getSavedProofs();

    // Kein QR generieren wenn keine Badges vorhanden
    if (myBadges.isEmpty) {
      setState(() {
        _user = user;
        _platformProofCount = proofs.length;
        _isLoading = false;
      });
      return;
    }

    // ZAEHLGRUNDLAGE (Fix Aug. 2026): Bisher wurde hier ueber ALLE Badges
    // gezaehlt — auch ueber unsignierte Organisator-Marker, die man sich
    // durch blosses Erstellen eines Meetups selbst ausstellt. Der lokale
    // Score liess sie korrekt weg, das VEROEFFENTLICHTE Reputations-Event
    // zaehlte sie aber mit. Wer 50 Sessions anlegt, haette den Relays
    // "50 Badges, 50 Meetups" gemeldet, ohne je bestaetigt worden zu sein.
    // Ab jetzt gilt ueberall dieselbe Regel wie im Trust Score:
    // signiert UND nicht selbst ausgestellt.
    final countedBadges =
        myBadges.where((b) => b.isNostrSigned && !b.isOrganizer).toList();
    final uniqueMeetups = countedBadges.map((b) => b.meetupName).toSet();
    final uniqueSigners =
        countedBadges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet();

    // Trust Score
    final sortedByDate = List<MeetupBadge>.from(myBadges)
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstBadgeDate = sortedByDate.isNotEmpty ? sortedByDate.first.date : null;
    
    final trustScore = TrustScoreService.calculateScore(
      badges: myBadges,
      firstBadgeDate: firstBadgeDate,
      coAttestorMap: null,
    );

    // Badge-Proof (v2 wenn gebundene Badges vorhanden, sonst v1)
    final badgeProofV2 = MeetupBadge.generateBadgeProofV2(myBadges);
    final badgeProofV1 = MeetupBadge.generateBadgeProof(myBadges);
    final badgeProof = badgeProofV2.isNotEmpty ? badgeProofV2 : badgeProofV1;
    final verifiedCount = MeetupBadge.countVerifiedBadges(myBadges);
    final boundCount = MeetupBadge.countBoundBadges(myBadges);

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
      'bc': countedBadges.length,
      'vc': verifiedCount,
      'mc': uniqueMeetups.length,
      'si': uniqueSigners.length,
      'ad': trustScore.accountAgeDays,
    };
    if (uniqueMeetups.isNotEmpty) {
      // Privacy: Meetup-Namen hashen — Beweis der Teilnahme
      // ohne zu verraten welches Meetup genau.
      // Verifizierer mit gleichem Meetup-Namen kann den Hash reproduzieren.
      reputation['ml'] = uniqueMeetups.take(10).map((name) {
        final hash = sha256.convert(utf8.encode('21meetup:$name')).toString();
        return hash.substring(0, 12); // 12 Hex-Zeichen = 48 Bit
      }).toList();
    }
    // NEU: Gebundene Badges
    reputation['bb'] = boundCount;

    final Map<String, dynamic> proof = {
      'bp': badgeProof,
      'pv': badgeProofV2.isNotEmpty ? 2 : 1,
      'vc': verifiedCount,
      'tc': countedBadges.length,
      'bb': boundCount,
    };

    // Platform-Proofs kompakt für QR (Signatur + Username)
    // Scanner kann damit direkt verifizieren ohne separaten String
    final Map<String, dynamic> platformProofs = {};
    for (final p in proofs) {
      platformProofs[p.platform] = {
        'u': p.username,
        's': p.proofSig,
      };
    }

    final Map<String, dynamic> qrPayload = {
      'v': 6,  // v6: Privacy-Meetups + eingebettete Platform-Proofs
      'id': identity,
      'rp': reputation,
      'pf': proof,
      if (platformProofs.isNotEmpty) 'pp': platformProofs,
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
      _boundBadgeCount = boundCount;
      _platformProofCount = proofs.length;
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
    final shareText = AppLocalizations.of(context).reputationVerified;
    // Anker vor jeglichem await holen — warum: share_origin.dart (Issue #73).
    final shareOrigin = shareOriginFor(context);
    try {
      // Fix: Beim ersten Aufruf kann der RenderRepaintBoundary noch nicht
      // vollständig gerendert sein. Wir warten auf den nächsten Frame.
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;

      final boundary = _qrRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      // Die Bytes direkt teilen, statt selbst eine Datei in
      // getTemporaryDirectory() zu schreiben: path_provider hat keine
      // Web-Implementierung, weshalb das im Browser mit einer
      // MissingPluginException endete und Teilen dort unmoeglich war.
      // share_plus legt die temporaere Datei auf iOS/Android selbst an, wenn
      // die XFile keinen Pfad hat. `name` greift im Web,
      // `fileNameOverrides` auf den nativen Plattformen — cross_file
      // ignoriert `name` dort.
      const fileName = 'einundzwanzig_reputation.png';
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
          SnackBar(content: Text(AppLocalizations.of(context).repShareError(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  // =============================================
  // REPUTATION AUF RELAYS PUBLIZIEREN
  // =============================================
  void _publishToRelays() async {
    setState(() {
      _isPublishing = true;
      _lastPublishInfo = null;
    });

    final proofs = await PlatformProofService.getProofsForPublishing();
    final result = await ReputationPublisher.publish(
      badges: myBadges,
      platformProofs: proofs,
      force: true,
    );

    if (mounted) {
      setState(() {
        _isPublishing = false;
        _lastPublishInfo = result.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
        title: Text(AppLocalizations.of(context).reputationTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, color: cTextSecondary),
            tooltip: AppLocalizations.of(context).rcShareImage,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReputationCardScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: cTextSecondary),
            tooltip: AppLocalizations.of(context).reputationCheck,
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
              ? _buildNoBadgesView(context)
              : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Warnung wenn keine Identität
                  if (!_hasIdentity)
                    _buildWarningBanner(context),

                  // QR Code (mit RepaintBoundary für Screenshot)
                  RepaintBoundary(
                    key: _qrRepaintKey,
                    child: _buildQRCard(context),
                  ),

                  const SizedBox(height: 20),

                  // Stats
                  _buildStatsBlock(context),

                  const SizedBox(height: 20),

                  // Badge-Proof Status (erweitert)
                  _buildProofStatus(context),

                  const SizedBox(height: 24),

                  // Action Buttons (erweitert)
                  _buildActions(context),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildNoBadgesView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: cOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium, color: cOrange, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).reputationNoBadges,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).reputationBuildHint1 +
            AppLocalizations.of(context).reputationBuildHint2,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),

          // QR Scanner
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SecureQRScanner()),
              ),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(AppLocalizations.of(context).reputationScanQr),
              style: ElevatedButton.styleFrom(
                backgroundColor: cOrange.withValues(alpha: 0.12),
                foregroundColor: cOrange,
              ),
            ),
          ),
          ],
        ),
    );
  }

  Widget _buildWarningBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(
            AppLocalizations.of(context).reputationNoIdentity,
            style: TextStyle(color: Colors.red.shade300, fontSize: 12, height: 1.4),
          )),
        ]),
      ),
    );
  }


  Widget _buildQRCard(BuildContext context) {
    final t = AppLocalizations.of(context);
    final nickname = _user.nickname.isNotEmpty ? _user.nickname : 'Anon';
    final level = _trustScore?.level ?? '';

    return ReputationCardVisual(
      nickname: nickname,
      score: _trustScore?.totalScore ?? 0.0,
      level: level,
      badgeCount: _verifiedBadgeCount,
      meetupCount: _trustScore?.uniqueMeetups ?? 0,
      signerCount: _trustScore?.uniqueSigners ?? 0,
      isSigned: _hasIdentity,
      levelColor: levelColor(level),
      levelIcon: levelIcon(level),
      scoreLabel: t.reputationScoreLabel,
      badgesLabel: t.reputationBadges,
      meetupsLabel: t.reputationMeetups,
      signersLabel: t.reputationSigners,
      signedLabel: t.reputationSchnorrSigned,
      unsignedLabel: t.reputationUnsigned,
      // 220 statt 260: Der QR sitzt jetzt in einer gestalteten Karte und
      // teilt sich den Platz. Zum Abscannen reicht das mit Abstand.
      qrCode: QrImageView(
        data: _qrData,
        version: QrVersions.auto,
        size: 220,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final score = _trustScore;
    return Row(children: [
      _buildStat(Icons.military_tech, "${score?.totalBadges ?? 0}", AppLocalizations.of(context).reputationBadges, cOrange),
      const SizedBox(width: 10),
      _buildStat(Icons.location_on, "${score?.uniqueMeetups ?? 0}", AppLocalizations.of(context).reputationMeetups, cCyan),
      const SizedBox(width: 10),
      _buildStat(Icons.people_outline, "${score?.uniqueSigners ?? 0}", AppLocalizations.of(context).reputationSigners, cPurple),
      const SizedBox(width: 10),
      _buildStat(Icons.link, "$_boundBadgeCount", AppLocalizations.of(context).reputationBound, Colors.green),
    ]);
  }

  /// Statistik-Reihe plus Erklaerzeile zu nicht gezaehlten Badges.
  Widget _buildStatsBlock(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(context),
          _organizerHint(context),
        ],
      );

  /// Erklaert die Luecke zwischen Wallet-Anzahl und gezaehlten Badges.

  /// Ohne diesen Hinweis wirkt "1 Badge, 0 Meetups, Score 0.0" wie ein Fehler.

  Widget _organizerHint(BuildContext context) {

    // Eigene Meetups SICHTBAR machen, statt sie nur wegzurechnen: Wer
    // organisiert, leistet den Aufwand — das gehoert gewuerdigt, nur eben
    // klar getrennt vom Score (man kann sich nicht selbst bestaetigen).
    // Gezaehlt werden MEETUPS, nicht Marker-Badges: zwei Marker fuer
    // denselben Abend waeren sonst zwei "organisierte Meetups".
    final n = myBadges
        .where((b) => b.isOrganizer)
        .map((b) => b.meetupEventId.isNotEmpty ? b.meetupEventId : b.id)
        .toSet()
        .length;

    if (n == 0) return const SizedBox.shrink();

    return Padding(

      padding: const EdgeInsets.only(top: 10),

      child: Row(children: [

        const Icon(Icons.shield_outlined, color: cTextSecondary, size: 13),

        const SizedBox(width: 7),

        Expanded(

          child: Text(AppLocalizations.of(context).reputationOrganizerNote(n),

              style: const TextStyle(color: cTextTertiary, fontSize: 11.5, height: 1.35)),

        ),

      ]),

    );

  }


  Widget _buildStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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

  Widget _buildProofStatus(BuildContext context) {
    // Auch hier nur zaehlbare Badges: Ein unsignierter Organisator-Marker
    // haette "alle verifiziert" sonst dauerhaft verhindert, obwohl er gar
    // nicht verifizierbar IST.
    final total = myBadges.where((b) => b.isNostrSigned && !b.isOrganizer).length;
    final verified = _verifiedBadgeCount;
    final bound = _boundBadgeCount;
    final allBound = total > 0 && bound == total;
    final allVerified = total > 0 && verified == total;

    // Höchste Stufe bestimmen
    final Color c;
    final IconData icon;
    final String text;

    if (allBound) {
      c = Colors.green;
      icon = Icons.verified;
      text = AppLocalizations.of(context).repAllBound(total);
    } else if (bound > 0) {
      c = cCyan;
      icon = Icons.link;
      text = AppLocalizations.of(context).repBoundOf(bound, total) +
          (verified > bound ? AppLocalizations.of(context).repBoundExtra(verified) : '');
    } else if (allVerified) {
      c = cOrange;
      icon = Icons.shield_outlined;
      text = AppLocalizations.of(context).repAllVerified(total);
    } else if (verified > 0) {
      c = cOrange;
      icon = Icons.shield_outlined;
      text = AppLocalizations.of(context).repVerifiedSchnorr(verified, total);
    } else {
      c = Colors.grey;
      icon = Icons.info_outline;
      text = AppLocalizations.of(context).reputationNoProofs;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
          // Plattform-Proofs Info
          if (_platformProofCount > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.language, color: Colors.green.shade400, size: 16),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).repPlatformLinksActive(_platformProofCount),
                style: TextStyle(color: Colors.green.shade400, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  // =============================================
  // ACTION BUTTONS (erweitert)
  // =============================================

  Widget _buildActions(BuildContext context) {
    return Column(children: [
      // Primär: QR als Bild teilen
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _shareQRImage,
          icon: const Icon(Icons.share, size: 20),
          label: Text(AppLocalizations.of(context).reputationShareImage),
          style: ElevatedButton.styleFrom(
            backgroundColor: cOrange,
            foregroundColor: Colors.black,
          ),
        ),
      ),

      const SizedBox(height: 12),

      // Relay-Publish
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isPublishing ? null : _publishToRelays,
          icon: _isPublishing
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.cloud_upload, size: 20),
          label: Text(_isPublishing ? AppLocalizations.of(context).reputationPublishing : AppLocalizations.of(context).reputationUpdateRelays),
          style: ElevatedButton.styleFrom(
            backgroundColor: cCyan.withValues(alpha: 0.15),
            foregroundColor: cCyan,
            disabledBackgroundColor: cCyan.withValues(alpha: 0.08),
          ),
        ),
      ),

      // Letzter Publish-Status
      if (_lastPublishInfo != null) ...[
        const SizedBox(height: 6),
        Text(
          _lastPublishInfo!,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],

      const SizedBox(height: 16),
    ]);
  }

}


