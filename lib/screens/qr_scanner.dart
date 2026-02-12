import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../services/badge_security.dart';
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
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.startsWith("21:")) {
        setState(() => _isScanned = true);
        _verifyAndShow(code);
        break;
      }
    }
  }

  void _verifyAndShow(String fullCode) {
    try {
      // 1. "21:" wegmachen
      final cleanCode = fullCode.substring(3);

      // 2. Am Punkt trennen
      final parts = cleanCode.split('.');
      if (parts.length != 2) throw Exception("Format ungültig");

      final dataBase64 = parts[0];
      final signatureOnQr = parts[1];

      // 3. Daten decodieren
      final jsonString = utf8.decode(base64.decode(dataBase64));

      // 4. Signatur nachrechnen
      final calculatedSignature = BadgeSecurity.sign(jsonString, "QR", 0);

      if (signatureOnQr == calculatedSignature) {
        // ✅ SIGNATUR GÜLTIG
        final data = jsonDecode(jsonString);
        final int version = data['v'] ?? 1;

        if (version >= 2 && data['id'] != null) {
          // v2: Identity-bound QR Code
          _showIdentityResult(data);
        } else {
          // v1: Alter QR Code ohne Identität
          _showLegacyResult(data);
        }
      } else {
        // ❌ FÄLSCHUNG
        _showResultScreen(
          isValid: false,
          title: "FÄLSCHUNG ERKANNT",
          subtitle: "Die Signatur stimmt nicht!",
          identity: null,
          badgeCount: 0,
          meetupCount: 0,
          hasIdentity: false,
        );
      }
    } catch (e) {
      _showResultScreen(
        isValid: false,
        title: "UNGÜLTIGER CODE",
        subtitle: "Dieses Format wird nicht erkannt.",
        identity: null,
        badgeCount: 0,
        meetupCount: 0,
        hasIdentity: false,
      );
    }
  }

  void _showIdentityResult(Map<String, dynamic> data) {
    final id = data['id'] as Map<String, dynamic>;
    final bool hasRealIdentity =
        (id['np'] != null && id['np'].toString().isNotEmpty) ||
        (id['tg'] != null && id['tg'].toString().isNotEmpty) ||
        (id['tw'] != null && id['tw'].toString().isNotEmpty);

    _showResultScreen(
      isValid: true,
      title: "VERIFIZIERT",
      subtitle: hasRealIdentity
          ? "Signatur gültig & Identität gebunden"
          : "Signatur gültig, aber keine Identität verknüpft",
      identity: id,
      badgeCount: data['c'] ?? 0,
      meetupCount: data['m'] ?? 0,
      hasIdentity: hasRealIdentity,
    );
  }

  void _showLegacyResult(Map<String, dynamic> data) {
    _showResultScreen(
      isValid: true,
      title: "VERIFIZIERT (v1)",
      subtitle: "Signatur gültig – älteres Format ohne Identitätsbindung",
      identity: {'n': data['u'] ?? 'Anon'},
      badgeCount: data['c'] ?? 0,
      meetupCount: data['m'] ?? 0,
      hasIdentity: false,
    );
  }

  void _showResultScreen({
    required bool isValid,
    required String title,
    required String subtitle,
    required Map<String, dynamic>? identity,
    required int badgeCount,
    required int meetupCount,
    required bool hasIdentity,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => _VerificationResultScreen(
          isValid: isValid,
          title: title,
          subtitle: subtitle,
          identity: identity,
          badgeCount: badgeCount,
          meetupCount: meetupCount,
          hasIdentity: hasIdentity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("REPUTATION PRÜFEN")),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // Overlay mit Anleitung
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Scanne einen Einundzwanzig\nReputation QR-Code",
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// VERIFIZIERUNGS-ERGEBNIS SCREEN
// Zeigt Identität, Stats und Gültigkeit prominent an
// ============================================================
class _VerificationResultScreen extends StatelessWidget {
  final bool isValid;
  final String title;
  final String subtitle;
  final Map<String, dynamic>? identity;
  final int badgeCount;
  final int meetupCount;
  final bool hasIdentity;

  const _VerificationResultScreen({
    required this.isValid,
    required this.title,
    required this.subtitle,
    required this.identity,
    required this.badgeCount,
    required this.meetupCount,
    required this.hasIdentity,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = !isValid
        ? Colors.red
        : hasIdentity
            ? Colors.green
            : Colors.orange;

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("ERGEBNIS")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // STATUS HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    isValid ? Icons.verified : Icons.gpp_bad,
                    color: statusColor,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            if (isValid && identity != null) ...[
              const SizedBox(height: 24),

              // IDENTITÄTS-BLOCK
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasIdentity
                        ? cPurple.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fingerprint,
                          color: hasIdentity ? cPurple : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasIdentity ? "IDENTITÄT" : "ACHTUNG: KEINE IDENTITÄT",
                          style: TextStyle(
                            color: hasIdentity ? cPurple : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nickname
                    _identityLine(
                      "Nickname",
                      identity!['n'] ?? 'Anon',
                      Icons.person,
                    ),

                    // Nostr
                    if (identity!['np'] != null && identity!['np'].toString().isNotEmpty)
                      _identityLine(
                        "Nostr",
                        identity!['np'],
                        Icons.key,
                        isMono: true,
                      ),

                    // Telegram
                    if (identity!['tg'] != null && identity!['tg'].toString().isNotEmpty)
                      _identityLine(
                        "Telegram",
                        "@${identity!['tg']}",
                        Icons.send,
                      ),

                    // Twitter
                    if (identity!['tw'] != null && identity!['tw'].toString().isNotEmpty)
                      _identityLine(
                        "Twitter/X",
                        "@${identity!['tw']}",
                        Icons.alternate_email,
                      ),

                    if (!hasIdentity) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "⚠️ Dieser QR-Code hat keine verknüpfte Identität (kein Nostr/Telegram/Twitter). "
                          "Die Reputation könnte von jemand anderem stammen. "
                          "Frage die Person nach einem verifizierbaren Account!",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],

                    if (hasIdentity) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "✅ Prüfe, ob die Person vor dir tatsächlich "
                          "Zugang zu den oben genannten Accounts hat "
                          "(z.B. Telegram-Chat öffnen lassen).",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // STATS
              Row(
                children: [
                  Expanded(
                    child: _statBox(
                      icon: Icons.military_tech,
                      label: "Badges",
                      value: "$badgeCount",
                      color: cOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statBox(
                      icon: Icons.location_on,
                      label: "Meetups",
                      value: "$meetupCount",
                      color: cCyan,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // ZURÜCK BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  "ZURÜCK",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityLine(String label, String value, IconData icon,
      {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cOrange),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: isMono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
