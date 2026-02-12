import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import 'qr_scanner.dart';

class ReputationQRScreen extends StatefulWidget {
  const ReputationQRScreen({super.key});

  @override
  State<ReputationQRScreen> createState() => _ReputationQRScreenState();
}

class _ReputationQRScreenState extends State<ReputationQRScreen> {
  String _qrData = '';
  String _fullJson = '';
  bool _isLoading = true;
  late UserProfile _user;

  @override
  void initState() {
    super.initState();
    _generateQRData();
  }

  void _generateQRData() async {
    final user = await UserProfile.load();
    final uniqueMeetups = myBadges.map((b) => b.meetupName).toSet().length;

    // --- IDENTITY-BOUND QR CODE ---

    // 1. Identitäts-Block: Alle verknüpften Identitäten
    final Map<String, dynamic> identity = {
      'n': user.nickname.isEmpty ? 'Anon' : user.nickname,
    };
    // Nur nicht-leere Felder aufnehmen (spart Platz im QR)
    if (user.nostrNpub.isNotEmpty) identity['np'] = user.nostrNpub;
    if (user.telegramHandle.isNotEmpty) identity['tg'] = user.telegramHandle;
    if (user.twitterHandle.isNotEmpty) identity['tw'] = user.twitterHandle;

    // 2. Payload mit Identität + Stats
    final Map<String, dynamic> qrPayload = {
      'v': 2,                                              // Version 2 (identity-bound)
      'id': identity,                                      // Identitäts-Block
      'c': myBadges.length,                                // Badge-Count
      'm': uniqueMeetups,                                  // Meetup-Count
      't': DateTime.now().millisecondsSinceEpoch,          // Timestamp
    };

    final jsonString = jsonEncode(qrPayload);

    // 3. Signatur: Nostr (wenn Key vorhanden) oder Legacy
    String signature;
    String? signerPubkey;
    final hasKey = await NostrService.hasKey();
    
    if (hasKey) {
      signature = await BadgeSecurity.signQR(jsonString);
      final keys = await NostrService.loadKeys();
      signerPubkey = keys?['npub'];
    } else {
      signature = BadgeSecurity.signLegacy(jsonString, "QR", 0);
    }

    // 4. Format: "21:BASE64_DATEN.SIGNATUR" (optional .PUBKEY für v2)
    final base64Json = base64Encode(utf8.encode(jsonString));
    String secureQrData;
    if (signerPubkey != null) {
      // v2: Pubkey mit einbauen für Verifikation
      secureQrData = "21v2:$base64Json.$signature.${NostrService.npubToHex(signerPubkey)}";
    } else {
      secureQrData = "21:$base64Json.$signature";
    }

    // Vollständiges JSON für manuellen Export (ebenfalls mit Identität)
    final fullJsonExport = MeetupBadge.exportBadgesForReputation(
      myBadges,
      user.nostrNpub,
      nickname: user.nickname,
      telegram: user.telegramHandle,
      twitter: user.twitterHandle,
    );

    setState(() {
      _qrData = secureQrData;
      _fullJson = fullJsonExport;
      _user = user;
      _isLoading = false;
    });
  }

  // Prüft ob MINDESTENS eine echte Identität verknüpft ist
  bool get _hasIdentity {
    if (_isLoading) return false;
    return _user.nostrNpub.isNotEmpty ||
        _user.telegramHandle.isNotEmpty ||
        _user.twitterHandle.isNotEmpty;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label in Zwischenablage kopiert'),
        backgroundColor: cOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("REPUTATION QR-CODE"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecureQRScanner()),
          );
        },
        backgroundColor: cCyan,
        icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
        label: const Text(
            "PRÜFEN",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // WARNUNG wenn keine Identität verknüpft
                  if (!_hasIdentity) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade700),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.red, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "KEINE IDENTITÄT VERKNÜPFT",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Ohne Nostr npub, Telegram oder Twitter kann dieser QR-Code nicht an deine Identität gebunden werden. Gehe in dein Profil und füge mindestens einen Account hinzu.",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Info Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cOrange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.verified_user, color: cOrange, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "VERIFIZIERTE REPUTATION",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cOrange,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Dieser QR-Code ist kryptographisch signiert und an deine Identität gebunden. Änderungen an den Daten machen die Signatur ungültig.",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cTextSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // IDENTITÄTS-KARTE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cPurple.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.fingerprint, color: cPurple, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "VERKNÜPFTE IDENTITÄT",
                              style: TextStyle(
                                color: cPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildIdentityRow(
                          "Nickname",
                          _user.nickname.isEmpty ? 'Anon' : _user.nickname,
                          Icons.person,
                          true, // immer vorhanden
                        ),
                        if (_user.nostrNpub.isNotEmpty)
                          _buildIdentityRow(
                            "Nostr",
                            _user.nostrNpub.length > 24
                                ? "${_user.nostrNpub.substring(0, 24)}..."
                                : _user.nostrNpub,
                            Icons.key,
                            true,
                          ),
                        if (_user.telegramHandle.isNotEmpty)
                          _buildIdentityRow(
                            "Telegram",
                            "@${_user.telegramHandle}",
                            Icons.send,
                            true,
                          ),
                        if (_user.twitterHandle.isNotEmpty)
                          _buildIdentityRow(
                            "Twitter/X",
                            "@${_user.twitterHandle}",
                            Icons.alternate_email,
                            true,
                          ),
                        if (!_hasIdentity)
                          _buildIdentityRow(
                            "Status",
                            "Keine verifizierbare Identität",
                            Icons.warning_amber,
                            false,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: cOrange.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 260,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _hasIdentity
                              ? "🔐 Signiert & Identitätsgebunden"
                              : "🔐 Signiert (ohne Identität)",
                          style: TextStyle(
                            color: _hasIdentity ? Colors.green.shade700 : Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        icon: Icons.military_tech,
                        label: "Badges",
                        value: "${myBadges.length}",
                        color: cOrange,
                      ),
                      _buildStatCard(
                        icon: Icons.location_on,
                        label: "Meetups",
                        value: "${myBadges.map((b) => b.meetupName).toSet().length}",
                        color: cCyan,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _copyToClipboard(_qrData, 'Signierter Code'),
                          icon: const Icon(Icons.copy, size: 20),
                          label: const Text('CODE KOPIEREN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cOrange,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(_fullJson, 'JSON-Daten'),
                          icon: const Icon(Icons.code, size: 20),
                          label: const Text('JSON EXPORT'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cCyan,
                            side: const BorderSide(color: cCyan),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, color: cCyan, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "WIE FUNKTIONIERT DAS?",
                              style: TextStyle(
                                color: cCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "• Deine Identität (Nostr/Telegram/Twitter) ist Teil der signierten Daten.\n"
                          "• Wer den QR-Code scannt, sieht deine verknüpften Accounts.\n"
                          "• Wird die Identität geändert, ist die Signatur ungültig → Fälschung erkannt.\n"
                          "• So kann der QR-Code nicht einfach weitergegeben oder verkauft werden.",
                          style: TextStyle(
                            color: cTextSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildIdentityRow(String label, String value, IconData icon, bool isPresent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isPresent ? cOrange : Colors.red.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isPresent ? Colors.white : Colors.red.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: label == "Nostr" ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: cTextSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}