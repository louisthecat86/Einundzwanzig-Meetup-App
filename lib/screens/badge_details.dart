import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../widgets/badge_share_card.dart';
import '../widgets/meetup_crest_watermark.dart';
import 'badge_wallet.dart'; // BadgeArtPainter als Rueckfallmotiv
import '../l10n/app_localizations.dart';
import '../models/badge.dart';
import '../utils/share_origin.dart';

class BadgeDetailsScreen extends StatefulWidget {
  final MeetupBadge badge;

  const BadgeDetailsScreen({super.key, required this.badge});

  @override
  State<BadgeDetailsScreen> createState() => _BadgeDetailsScreenState();
}

class _BadgeDetailsScreenState extends State<BadgeDetailsScreen> {
  MeetupBadge get b => widget.badge;

  String _formatBlock(int h) {
    if (h == 0) return AppLocalizations.of(context).badgeUnknown;
    final s = h.toString();
    if (s.length <= 3) return s;
    final parts = <String>[];
    int i = s.length;
    while (i > 0) {
      parts.insert(0, s.substring(i - 3 < 0 ? 0 : i - 3, i));
      i -= 3;
    }
    return parts.join('.');
  }

  String _formatTimestamp(int ts) {
    if (ts == 0) return AppLocalizations.of(context).badgeUnknown;
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _shortNpub(String npub) {
    if (npub.length < 20) return npub.isEmpty ? '—' : npub;
    return '${npub.substring(0, 12)}…${npub.substring(npub.length - 8)}';
  }

  String _deliveryLabelOf(BuildContext context) {
    switch (b.delivery) {
      case 'rolling_qr': return AppLocalizations.of(context).badgeRollingQr;
      case 'nfc':        return AppLocalizations.of(context).badgeNfcTag;
      default:           return b.delivery;
    }
  }

  String _sigLabelOf(BuildContext context) {
    if (b.sigVersion == 2) return AppLocalizations.of(context).badgeSchnorrSig;
    if (b.sigVersion == 1) return 'HMAC (Legacy v1)';
    return AppLocalizations.of(context).badgeNoSignature;
  }

  Color get _sigColor {
    if (b.sigVersion == 2) return cGreen;
    if (b.sigVersion == 1) return cOrange;
    return cTextTertiary;
  }

  /// Schluessel auf die abzumalende Karte.
  final GlobalKey _shareCardKey = GlobalKey();

  /// Badge als BILD teilen.
  ///
  /// Vorher ging eine Textwand raus — Titel, Datum, Block, Signaturart,
  /// Pruefsumme. Inhaltlich richtig, aber niemand postet das. Jetzt wird
  /// die Karte abgemalt und als PNG verschickt; der Text schrumpft auf
  /// zwei Zeilen, die neben dem Bild noch Sinn ergeben.
  void _shareBadge() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Anker vor jeglichem await holen — warum: share_origin.dart (Issue #73).
    final shareOrigin = shareOriginFor(context);

    try {
      // Die Karte haengt unsichtbar im Baum. Ein Bild kann erst entstehen,
      // wenn sie einmal gezeichnet wurde — deshalb auf den naechsten Frame
      // warten, statt sofort zuzugreifen.
      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;

      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      // pixelRatio 3 bei 360x480 ergibt 1080x1440 — genug fuer jeden
      // Messenger, ohne dass die Datei unhandlich wird.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      // Bytes direkt teilen statt selbst eine Datei anzulegen:
      // path_provider hat keine Web-Implementierung, und share_plus legt
      // die temporaere Datei auf iOS und Android ohnehin selbst an.
      const fileName = 'einundzwanzig_badge.png';
      await Share.shareXFiles(
        [XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName)],
        fileNameOverrides: const [fileName],
        subject: b.meetupName,
        text: '${b.meetupName} · ${b.date.day.toString().padLeft(2, '0')}.'
            '${b.date.month.toString().padLeft(2, '0')}.${b.date.year}\n'
            '${t.badgeShareTagline}',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(t.repShareError(e.toString())),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(b.meetupName.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppLocalizations.of(context).badgeShare,
            onPressed: _shareBadge,
          ),
        ],
      ),
      body: Stack(children: [
        // Die teilbare Karte liegt weit ausserhalb des Bildschirms. Sie muss
        // im Baum stehen und GEZEICHNET werden, sonst liefert toImage()
        // nichts — Offstage genuegt dafuer nicht, weil es das Zeichnen
        // gerade unterbindet.
        Positioned(
          left: -kShareCardSize.width * 2,
          top: 0,
          child: RepaintBoundary(
            key: _shareCardKey,
            child: BadgeShareCard(badge: b),
          ),
        ),
        SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HERO BADGE ──────────────────────────────
            _heroCard(context),

            const SizedBox(height: 20),

            // ── ZEITSTEMPEL / BLOCK ──────────────────────
            _sectionCard(
              title: AppLocalizations.of(context).badgeTimestamp,
              icon: Icons.access_time_rounded,
              color: cOrange,
              rows: [
                _row(AppLocalizations.of(context).badgeMeetupDate,
                    '${b.date.day.toString().padLeft(2, '0')}.${b.date.month.toString().padLeft(2, '0')}.${b.date.year}'),
                _row(AppLocalizations.of(context).badgeBlockAtScan,
                    b.blockHeight > 0 ? _formatBlock(b.blockHeight) : AppLocalizations.of(context).badgeUnknown,
                    mono: true,
                    valueColor: b.blockHeight > 0 ? cOrange : cTextTertiary),
                if (b.claimTimestamp > 0)
                  _row(AppLocalizations.of(context).badgeScanTime, _formatTimestamp(b.claimTimestamp)),
              ],
            ),

            const SizedBox(height: 12),

            // ── BADGE-DETAILS ────────────────────────────
            _sectionCard(
              title: AppLocalizations.of(context).badgeDetailsTitle,
              icon: Icons.badge_rounded,
              color: cCyan,
              rows: [
                _row(AppLocalizations.of(context).badgeMeetup, b.meetupName),
                _row(AppLocalizations.of(context).badgeTransmission, _deliveryLabelOf(context)),
                _row(AppLocalizations.of(context).badgeMeetupId, b.meetupEventId.isNotEmpty ? b.meetupEventId : '—'),
              ],
            ),

            const SizedBox(height: 12),

            // ── KRYPTOGRAPHISCHER BEWEIS ─────────────────
            _sectionCard(
              title: AppLocalizations.of(context).badgeProofTitle,
              icon: Icons.security_rounded,
              color: cGreen,
              rows: [
                _row(AppLocalizations.of(context).badgeSignatureType, _sigLabelOf(context), valueColor: _sigColor),
                _row(AppLocalizations.of(context).badgeOrganizerNpub,
                    _shortNpub(b.signerNpub),
                    mono: true),
                if (b.sigId.isNotEmpty)
                  _row('Nostr Event-ID',
                      '${b.sigId.substring(0, 12)}…${b.sigId.substring(b.sigId.length - 8)}',
                      mono: true),
                _row(AppLocalizations.of(context).badgeClaimBinding,
                    b.isClaimed ? AppLocalizations.of(context).badgeBound : AppLocalizations.of(context).badgeNotBound,
                    valueColor: b.isClaimed ? cGreen : cRed),
                if (b.isRetroactive)
                  _row(AppLocalizations.of(context).badgeNote, AppLocalizations.of(context).badgeClaimedLater, valueColor: cOrange),
                // Praesenz-Kennzeichnung: nur anzeigen, wenn NICHT geprueft —
                // der Normalfall braucht keinen Hinweis.
                if (!b.presenceVerified)
                  _row(AppLocalizations.of(context).badgeUnverified,
                      AppLocalizations.of(context).badgeUnverifiedInfo,
                      valueColor: cTextTertiary),
              ],
            ),

            const SizedBox(height: 12),

            // ── VERIFIKATIONS-HASH ───────────────────────
            _hashCard(context),

            const SizedBox(height: 24),

            // ── BUTTONS ──────────────────────────────────
            ElevatedButton.icon(
              onPressed: _shareBadge,
              icon: const Icon(Icons.share),
              label: Text(AppLocalizations.of(context).badgeShareCaps),
              style: ElevatedButton.styleFrom(
                backgroundColor: cOrange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: cTextSecondary),
              label: Text(AppLocalizations.of(context).badgeClose,
                  style: const TextStyle(color: cTextSecondary)),
            ),
          ],
        ),
        ),
      ]),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────

  Widget _heroCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cCard,
        border: Border.all(color: cOrange.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cOrange.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          )
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      // Der Inhalt liegt jetzt in einem Stack, damit das Meetup-Wappen
      // dahinter sichtbar wird. Abgerundet beschnitten, sonst schaut es
      // ueber die Ecken hinaus.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            child: Column(
        children: [
          // MEDAILLON: Frueher lag das Wappen frei ueber der Karte und wirkte
          // aufgeklebt. Jetzt sitzt es IM Kreis, wo vorher nur der Haken war
          // — der Kreis war ohnehin schon der Blickfang. Der Haken rutscht
          // als kleine Plakette an den Rand und bleibt damit lesbar.
          // Ohne Wappen sieht die Karte exakt aus wie bisher.
          // Das Wappen steht fuer sich — KEIN Kreis dahinter. Der Ring hat
          // das quadratische Logo nur eingeengt und wie einen Aufkleber
          // wirken lassen. Jetzt fuellt es den Raum, leicht abgerundet,
          // mit dem Haken als Plakette unten rechts.
          SizedBox(
            width: 168,
            height: 168,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: MeetupCrestFace(
                    meetupName: b.meetupName,
                    // Das eigene Bild des Badges zuerst — bei Event-Badges
                    // ist es das einzige, das es gibt.
                    imageUrl: b.coverUrl.isNotEmpty ? b.coverUrl : null,
                    // OHNE WAPPEN: Statt eines einsamen Symbols in viel
                    // Leerraum dieselbe generative Grafik wie auf der
                    // Wallet-Karte — gleicher Startwert, also dasselbe
                    // Muster. Das fuellt die Flaeche und bleibt wiedererkennbar.
                    fallback: CustomPaint(
                      painter: BadgeArtPainter(
                          seed: "${b.meetupName}:${b.blockHeight}"),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -6,
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(color: cCard, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, size: 30, color: cOrange),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Text(
            b.meetupName.toUpperCase(),
            style: const TextStyle(
              color: cText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('₿', style: TextStyle(color: cOrange, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text(
                'Block ${_formatBlock(b.blockHeight)}',
                style: const TextStyle(
                  color: cOrange,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: cBorder),
          const SizedBox(height: 12),
          // ORGANISATOR-MARKER klar abgrenzen: Er ist unsigniert und
          // dokumentiert nur, dass man dieses Meetup selbst erstellt hat.
          // Frueher stand hier auch bei ihm "bestaetigt kryptografisch,
          // dass du physisch vor Ort warst" — bei einem Badge ganz OHNE
          // Signatur. Das hat den Score von 0 unerklaerlich gemacht.
          Text(
            b.isOrganizer
                ? AppLocalizations.of(context).badgeOrganizerTitle
                : AppLocalizations.of(context).badgeProofOfAttendance,
            style: TextStyle(
                color: b.isOrganizer ? cTextSecondary : cOrange,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            b.isOrganizer
                ? AppLocalizations.of(context).badgeOrganizerDesc
                : AppLocalizations.of(context).badgeProofDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cTextSecondary, fontSize: 12),
          ),
        ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: cBorder),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool mono = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    color: cTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? cText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hashCard(BuildContext context) {
    final hash = b.getVerificationHash();
    return GestureDetector(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        final copiedText = AppLocalizations.of(context).badgeHashCopied;
        await Clipboard.setData(ClipboardData(text: hash));
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(copiedText),
              backgroundColor: cCard,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fingerprint, size: 14, color: cPurple),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).badgeVerificationHash,
                  style: const TextStyle(
                      color: cPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2),
                ),
                const Spacer(),
                const Icon(Icons.copy, size: 13, color: cTextTertiary),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              hash,
              style: const TextStyle(
                color: cTextSecondary,
                fontSize: 10,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



