// ============================================
// SECURE QR SCANNER v3 — ECHTE SCHNORR-VERIFIKATION
// ============================================
//
// v3: Nostr-Event wird rekonstruiert → event.isValid()
//   → Echte BIP-340 Schnorr-Signatur-Verifikation
//
// Format: "21v3:BASE64.SIGNATURE.EVENTID.CREATEDAT.PUBKEY"
// ============================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../theme.dart';

class SecureQRScanner extends StatefulWidget {
  const SecureQRScanner({super.key});

  @override
  State<SecureQRScanner> createState() => _SecureQRScannerState();
}

class _SecureQRScannerState extends State<SecureQRScanner> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && (code.startsWith("21:") || code.startsWith("21v2:") || code.startsWith("21v3:"))) {
        setState(() => _isScanned = true);
        _verifyAndShow(code);
        break;
      }
    }
  }

  void _verifyAndShow(String fullCode) {
    try {
      final bool isV3 = fullCode.startsWith("21v3:");
      final bool isV2 = fullCode.startsWith("21v2:");
      
      String cleanCode;
      if (isV3) {
        cleanCode = fullCode.substring(5);
      } else if (isV2) {
        cleanCode = fullCode.substring(5);
      } else {
        cleanCode = fullCode.substring(3);
      }

      final parts = cleanCode.split('.');

      // v3: ECHTE SCHNORR-VERIFIKATION
      if (isV3 && parts.length >= 5) {
        final dataBase64 = parts[0];
        final signature = parts[1];
        final eventId = parts[2];
        final createdAt = int.tryParse(parts[3]) ?? 0;
        final pubkeyHex = parts[4];

        final jsonString = utf8.decode(base64.decode(dataBase64));

        final result = BadgeSecurity.verifyQRv3(
          jsonData: jsonString,
          signature: signature,
          eventId: eventId,
          createdAt: createdAt,
          pubkeyHex: pubkeyHex,
        );

        if (result.isValid) {
          final data = jsonDecode(jsonString);
          _showV3Result(data, signerNpub: result.signerNpub, verifyMessage: result.message);
        } else {
          _showFailed(title: "SIGNATUR UNGÜLTIG", subtitle: result.message);
        }
        return;
      }

      // v2: Legacy mit Pubkey
      if (isV2 && parts.length >= 3) {
        final dataBase64 = parts[0];
        final signature = parts[1];
        final pubkeyHex = parts[2];
        final jsonString = utf8.decode(base64.decode(dataBase64));

        final result = BadgeSecurity.verifyQRLegacy(
          jsonData: jsonString,
          signature: signature,
          pubkeyHex: pubkeyHex,
        );

        if (result.isValid) {
          final data = jsonDecode(jsonString);
          _showV2Result(data, signerNpub: result.signerNpub);
        } else {
          _showFailed(title: "NICHT VERIFIZIERBAR", subtitle: result.message);
        }
        return;
      }

      // v1: Legacy HMAC
      if (parts.length >= 2) {
        final dataBase64 = parts[0];
        final signature = parts[1];
        final jsonString = utf8.decode(base64.decode(dataBase64));

        final result = BadgeSecurity.verifyQRLegacy(
          jsonData: jsonString,
          signature: signature,
        );

        if (result.isValid) {
          final data = jsonDecode(jsonString);
          _showV1Result(data);
        } else {
          _showFailed(title: "FÄLSCHUNG ERKANNT", subtitle: "Die Signatur stimmt nicht!");
        }
        return;
      }

      _showFailed(title: "UNGÜLTIGES FORMAT", subtitle: "Zu wenige Daten im QR-Code.");

    } catch (e) {
      _showFailed(title: "FEHLER", subtitle: "QR-Code konnte nicht gelesen werden: $e");
    }
  }

  void _showV3Result(Map<String, dynamic> data, {required String signerNpub, required String verifyMessage}) {
    final id = data['id'] as Map<String, dynamic>? ?? {};
    final rp = data['rp'] as Map<String, dynamic>? ?? {};
    final pf = data['pf'] as Map<String, dynamic>? ?? {};

    final bool hasRealIdentity =
        (id['np'] != null && id['np'].toString().isNotEmpty) ||
        (id['tg'] != null && id['tg'].toString().isNotEmpty) ||
        (id['tw'] != null && id['tw'].toString().isNotEmpty);

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => _VerificationResultScreen(
        isValid: true, version: 3,
        title: "VERIFIZIERT",
        subtitle: verifyMessage,
        identity: id, hasIdentity: hasRealIdentity,
        signerNpub: signerNpub,
        trustLevel: rp['lv'] as String? ?? '',
        trustScore: (rp['sc'] as num?)?.toDouble() ?? 0,
        badgeCount: rp['bc'] as int? ?? 0,
        verifiedBadgeCount: rp['vc'] as int? ?? pf['vc'] as int? ?? 0,
        meetupCount: rp['mc'] as int? ?? 0,
        signerCount: rp['si'] as int? ?? 0,
        accountAgeDays: rp['ad'] as int? ?? 0,
        meetupList: (rp['ml'] as List?)?.cast<String>() ?? [],
        badgeProof: pf['bp'] as String? ?? '',
        proofTotalCount: pf['tc'] as int? ?? 0,
        proofVerifiedCount: pf['vc'] as int? ?? 0,
      ),
    ));
  }

  void _showV2Result(Map<String, dynamic> data, {String? signerNpub}) {
    final id = data['id'] as Map<String, dynamic>? ?? {};
    final bool hasRealIdentity =
        (id['np'] != null && id['np'].toString().isNotEmpty) ||
        (id['tg'] != null && id['tg'].toString().isNotEmpty) ||
        (id['tw'] != null && id['tw'].toString().isNotEmpty);

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => _VerificationResultScreen(
        isValid: true, version: 2,
        title: "VERIFIZIERT (v2)",
        subtitle: "Legacy-Signatur gültig — kein Badge-Proof",
        identity: id, hasIdentity: hasRealIdentity,
        signerNpub: signerNpub,
        badgeCount: data['c'] as int? ?? 0,
        meetupCount: data['m'] as int? ?? 0,
      ),
    ));
  }

  void _showV1Result(Map<String, dynamic> data) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => _VerificationResultScreen(
        isValid: true, version: 1,
        title: "VERIFIZIERT (v1)",
        subtitle: "Älteres Format — keine Identitätsbindung",
        identity: {'n': data['u'] ?? 'Anon'},
        hasIdentity: false,
        badgeCount: data['c'] as int? ?? 0,
        meetupCount: data['m'] as int? ?? 0,
      ),
    ));
  }

  void _showFailed({required String title, required String subtitle}) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => _VerificationResultScreen(
        isValid: false, version: 0, title: title, subtitle: subtitle,
        identity: null, hasIdentity: false,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("REPUTATION PRÜFEN")),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        Positioned(
          bottom: 60, left: 40, right: 40,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
            child: const Text("Scanne einen Einundzwanzig\nReputation QR-Code",
              style: TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// VERIFIZIERUNGS-ERGEBNIS SCREEN
// ============================================================
class _VerificationResultScreen extends StatelessWidget {
  final bool isValid;
  final int version;
  final String title;
  final String subtitle;
  final Map<String, dynamic>? identity;
  final bool hasIdentity;
  final String? signerNpub;
  final String trustLevel;
  final double trustScore;
  final int badgeCount;
  final int verifiedBadgeCount;
  final int meetupCount;
  final int signerCount;
  final int accountAgeDays;
  final List<String> meetupList;
  final String badgeProof;
  final int proofTotalCount;
  final int proofVerifiedCount;

  const _VerificationResultScreen({
    required this.isValid,
    required this.version,
    required this.title,
    required this.subtitle,
    required this.identity,
    required this.hasIdentity,
    this.signerNpub,
    this.trustLevel = '',
    this.trustScore = 0,
    this.badgeCount = 0,
    this.verifiedBadgeCount = 0,
    this.meetupCount = 0,
    this.signerCount = 0,
    this.accountAgeDays = 0,
    this.meetupList = const [],
    this.badgeProof = '',
    this.proofTotalCount = 0,
    this.proofVerifiedCount = 0,
  });

  // Icons statt Emojis
  static IconData _levelIcon(String level) {
    switch (level) {
      case 'VETERAN': return Icons.bolt;
      case 'ETABLIERT': return Icons.shield;
      case 'AKTIV': return Icons.local_fire_department;
      case 'STARTER': return Icons.eco;
      default: return Icons.fiber_new;
    }
  }

  Color get _levelColor {
    switch (trustLevel) {
      case 'VETERAN': return Colors.amber;
      case 'ETABLIERT': return Colors.green;
      case 'AKTIV': return cCyan;
      case 'STARTER': return cOrange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = !isValid ? Colors.red : hasIdentity ? Colors.green : Colors.orange;

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("ERGEBNIS")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // STATUS HEADER
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
            ),
            child: Column(children: [
              Icon(isValid ? Icons.verified : Icons.gpp_bad, color: statusColor, size: 56),
              const SizedBox(height: 14),
              Text(title, style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12), textAlign: TextAlign.center),
              if (version > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    "Protokoll v$version${version == 3 ? ' · Schnorr' : version == 2 ? ' · Legacy+ID' : ' · Legacy'}",
                    style: const TextStyle(color: Colors.white30, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ]),
          ),

          // TRUST SCORE (v3)
          if (isValid && version >= 3 && trustLevel.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cCard, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _levelColor.withOpacity(0.3)),
              ),
              child: Column(children: [
                // Icon statt Emoji
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _levelColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_levelIcon(trustLevel), color: _levelColor, size: 24),
                ),
                const SizedBox(height: 10),
                Text(trustLevel, style: TextStyle(color: _levelColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text("Score ${trustScore.toStringAsFixed(1)}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 16),
                // Stats
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _miniStat(Icons.military_tech, "$badgeCount", "Badges", cOrange),
                  _miniStat(Icons.location_on, "$meetupCount", "Meetups", cCyan),
                  _miniStat(Icons.people_outline, "$signerCount", "Signer", cPurple),
                  _miniStat(Icons.calendar_today, "$accountAgeDays", "Tage", Colors.green),
                ]),
              ]),
            ),
          ],

          // BADGE-PROOF (v3)
          if (isValid && version >= 3 && badgeProof.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildProofCard(),
          ],

          // MEETUP-LISTE (v3)
          if (isValid && meetupList.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [
                  Icon(Icons.location_on, color: cCyan, size: 18), SizedBox(width: 8),
                  Text("BESUCHTE MEETUPS", style: TextStyle(color: cCyan, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: meetupList.map((m) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: cCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(m, style: const TextStyle(color: cCyan, fontSize: 12)),
                  )
                ).toList()),
              ]),
            ),
          ],

          // IDENTITÄT
          if (isValid && identity != null) ...[
            const SizedBox(height: 20),
            _buildIdentityCard(),
          ],

          // v1/v2 einfache Stats
          if (isValid && version < 3 && (badgeCount > 0 || meetupCount > 0)) ...[
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _statBox(Icons.military_tech, "$badgeCount", "Badges", cOrange)),
              const SizedBox(width: 12),
              Expanded(child: _statBox(Icons.location_on, "$meetupCount", "Meetups", cCyan)),
            ]),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black),
              child: const Text("ZURÜCK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildProofCard() {
    final allVerified = proofVerifiedCount == proofTotalCount && proofTotalCount > 0;
    final Color c = allVerified ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(allVerified ? Icons.verified : Icons.shield_outlined, color: c, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "$proofVerifiedCount von $proofTotalCount Badges kryptographisch verifiziert",
            style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            "Proof: ${badgeProof.length > 16 ? '${badgeProof.substring(0, 16)}...' : badgeProof}",
            style: const TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'monospace'),
          ),
        ])),
      ]),
    );
  }

  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasIdentity ? cPurple.withOpacity(0.4) : Colors.orange.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.fingerprint, color: hasIdentity ? cPurple : Colors.orange, size: 18),
          const SizedBox(width: 8),
          Text(
            hasIdentity ? "IDENTITÄT" : "KEINE IDENTITÄT",
            style: TextStyle(color: hasIdentity ? cPurple : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
          ),
        ]),
        const SizedBox(height: 12),
        _idLine("Nickname", identity!['n'] ?? 'Anon', Icons.person),
        if (identity!['np'] != null && identity!['np'].toString().isNotEmpty)
          _idLine("Nostr", identity!['np'], Icons.key, mono: true),
        if (identity!['tg'] != null && identity!['tg'].toString().isNotEmpty)
          _idLine("Telegram", "@${identity!['tg']}", Icons.send),
        if (identity!['tw'] != null && identity!['tw'].toString().isNotEmpty)
          _idLine("Twitter/X", "@${identity!['tw']}", Icons.alternate_email),

        if (!hasIdentity) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.orange.shade300, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text("Keine verifizierbare Identität. Die Reputation könnte von jemand anderem stammen.",
                style: TextStyle(color: Colors.orange, fontSize: 11, height: 1.4))),
            ]),
          ),
        ],
        if (hasIdentity) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                const Expanded(child: Text("Prüfe ob die Person Zugang zu den oben genannten Accounts hat.",
                  style: TextStyle(color: Colors.green, fontSize: 11, height: 1.4))),
              ]),
              if (signerNpub != null && signerNpub!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.lock_outline, color: Colors.green, size: 14),
                  const SizedBox(width: 8),
                  Text("Signiert: ${NostrService.shortenNpub(signerNpub!)}",
                    style: const TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace')),
                ]),
              ],
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 10)),
    ]);
  }

  Widget _idLine(String label, String value, IconData icon, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: cOrange), const SizedBox(width: 8),
        SizedBox(width: 65, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12))),
        Expanded(child: Text(value, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _statBox(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 12)),
      ]),
    );
  }
}