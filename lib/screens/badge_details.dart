import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';

class BadgeDetailsScreen extends StatefulWidget {
  final MeetupBadge badge;

  const BadgeDetailsScreen({super.key, required this.badge});

  @override
  State<BadgeDetailsScreen> createState() => _BadgeDetailsScreenState();
}

class _BadgeDetailsScreenState extends State<BadgeDetailsScreen> {
  MeetupBadge get b => widget.badge;

  String _formatBlock(int h) {
    if (h == 0) return 'unbekannt';
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
    if (ts == 0) return 'unbekannt';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} Uhr';
  }

  String _shortNpub(String npub) {
    if (npub.length < 20) return npub.isEmpty ? '—' : npub;
    return '${npub.substring(0, 12)}…${npub.substring(npub.length - 8)}';
  }

  String get _deliveryLabel {
    switch (b.delivery) {
      case 'rolling_qr': return 'Rolling QR-Code';
      case 'nfc':        return 'NFC-Tag';
      default:           return b.delivery;
    }
  }

  String get _sigLabel {
    if (b.sigVersion == 2) return 'Schnorr (Nostr v2) ✓';
    if (b.sigVersion == 1) return 'HMAC (Legacy v1)';
    return 'Keine Signatur';
  }

  Color get _sigColor {
    if (b.sigVersion == 2) return cGreen;
    if (b.sigVersion == 1) return cOrange;
    return cTextTertiary;
  }

  void _shareBadge() async {
    final user = await UserProfile.load();
    final reputationText = b.toReputationString();
    final hash = b.getVerificationHash();

    final shareText = '''
🏆 EINUNDZWANZIG MEETUP BADGE

$reputationText

Block: ${b.blockHeight > 0 ? _formatBlock(b.blockHeight) : 'unbekannt'}
Delivery: $_deliveryLabel
Signatur: $_sigLabel
Hash: $hash
${user.nostrNpub.isNotEmpty ? 'Npub: ${user.nostrNpub.substring(0, 20)}...' : ''}

✅ Proof of Attendance
Verifizierbar über die Einundzwanzig Meetup App
    ''';

    try {
      await Share.share(
        shareText,
        subject: 'Mein Einundzwanzig Badge - ${b.meetupName}',
      );
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Badge-Info in Zwischenablage kopiert'),
            backgroundColor: cOrange,
          ),
        );
      }
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
            tooltip: 'Badge teilen',
            onPressed: _shareBadge,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HERO BADGE ──────────────────────────────
            _heroCard(),

            const SizedBox(height: 20),

            // ── ZEITSTEMPEL / BLOCK ──────────────────────
            _sectionCard(
              title: 'Zeitstempel',
              icon: Icons.access_time_rounded,
              color: cOrange,
              rows: [
                _row('Meetup-Datum',
                    '${b.date.day.toString().padLeft(2, '0')}.${b.date.month.toString().padLeft(2, '0')}.${b.date.year}'),
                _row('₿ Blockhöhe beim Scan',
                    b.blockHeight > 0 ? _formatBlock(b.blockHeight) : 'unbekannt',
                    mono: true,
                    valueColor: b.blockHeight > 0 ? cOrange : cTextTertiary),
                if (b.claimTimestamp > 0)
                  _row('Scan-Zeitpunkt', _formatTimestamp(b.claimTimestamp)),
              ],
            ),

            const SizedBox(height: 12),

            // ── BADGE-DETAILS ────────────────────────────
            _sectionCard(
              title: 'Badge-Details',
              icon: Icons.badge_rounded,
              color: cCyan,
              rows: [
                _row('Meetup', b.meetupName),
                _row('Übertragungsweg', _deliveryLabel),
                _row('Meetup-ID', b.meetupEventId.isNotEmpty ? b.meetupEventId : '—'),
              ],
            ),

            const SizedBox(height: 12),

            // ── KRYPTOGRAPHISCHER BEWEIS ─────────────────
            _sectionCard(
              title: 'Kryptographischer Beweis',
              icon: Icons.security_rounded,
              color: cGreen,
              rows: [
                _row('Signaturtyp', _sigLabel, valueColor: _sigColor),
                _row('Organisator (npub)',
                    _shortNpub(b.signerNpub),
                    mono: true),
                if (b.sigId.isNotEmpty)
                  _row('Nostr Event-ID',
                      '${b.sigId.substring(0, 12)}…${b.sigId.substring(b.sigId.length - 8)}',
                      mono: true),
                _row('Claim-Binding',
                    b.isClaimed ? 'Gebunden ✓' : 'Nicht gebunden',
                    valueColor: b.isClaimed ? cGreen : cRed),
                if (b.isRetroactive)
                  _row('Hinweis', 'Nachträglich geclaimed', valueColor: cOrange),
              ],
            ),

            const SizedBox(height: 12),

            // ── VERIFIKATIONS-HASH ───────────────────────
            _hashCard(),

            const SizedBox(height: 24),

            // ── BUTTONS ──────────────────────────────────
            ElevatedButton.icon(
              onPressed: _shareBadge,
              icon: const Icon(Icons.share),
              label: const Text('BADGE TEILEN'),
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
              label: const Text('SCHLIESSEN',
                  style: TextStyle(color: cTextSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── WIDGETS ───────────────────────────────────────────────────

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: cCard,
        border: Border.all(color: cOrange.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cOrange.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          )
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cOrange.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, size: 72, color: cOrange),
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
          const Text(
            'PROOF OF ATTENDANCE',
            style: TextStyle(
                color: cOrange, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dieses Badge bestätigt kryptografisch, dass du physisch vor Ort warst.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cTextSecondary, fontSize: 12),
          ),
        ],
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
        border: Border.all(color: color.withOpacity(0.25)),
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

  Widget _hashCard() {
    final hash = b.getVerificationHash();
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: hash));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hash kopiert'),
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
                const Text(
                  'VERIFIKATIONS-HASH',
                  style: TextStyle(
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
