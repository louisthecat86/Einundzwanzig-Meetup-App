import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';
import '../services/badge_security.dart';
import 'qr_scanner.dart'; // <--- NEU: Import für den Scanner

class ReputationQRScreen extends StatefulWidget {
  const ReputationQRScreen({super.key});

  @override
  State<ReputationQRScreen> createState() => _ReputationQRScreenState();
}

class _ReputationQRScreenState extends State<ReputationQRScreen> {
  String _qrData = '';
  String _fullJson = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateQRData();
  }

  void _generateQRData() async {
    final user = await UserProfile.load();
    final uniqueMeetups = myBadges.map((b) => b.meetupName).toSet().length;
    
    // --- SIGNIERTER QR CODE ---
    
    // 1. Die kompakten Daten für den QR-Code
    final Map<String, dynamic> qrPayload = {
      'u': user.nickname.isEmpty ? 'Anon' : user.nickname, // User
      'c': myBadges.length,                                // Count Badges
      'm': uniqueMeetups,                                  // Count Meetups
      't': DateTime.now().millisecondsSinceEpoch,          // Timestamp
    };

    final jsonString = jsonEncode(qrPayload);

    // 2. Wir signieren die Daten mit unserem App-Secret
    final signature = BadgeSecurity.sign(jsonString, "QR", 0);

    // 3. Wir bauen den String: "21:BASE64_DATEN.SIGNATUR"
    final base64Json = base64Encode(utf8.encode(jsonString));
    final secureQrData = "21:$base64Json.$signature";

    // -------------------------------
    
    // Vollständiges JSON für manuellen Export
    final fullJsonExport = MeetupBadge.exportBadgesForReputation(myBadges, user.nostrNpub);
    
    setState(() {
      _qrData = secureQrData;
      _fullJson = fullJsonExport;
      _isLoading = false;
    });
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
      
      // --- NEU: DER SCANNER BUTTON ---
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
      ),
      // -------------------------------

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                          "Dieser QR-Code ist kryptographisch signiert. Scanne ihn mit der Einundzwanzig-App, um die Echtheit zu prüfen.",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cTextSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

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
                        const Text(
                          "🔐 Signiert",
                          style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

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

                  // Info Text
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
                              "INFO",
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
                          "• Dieser Code enthält deine Statistik und eine digitale Unterschrift der App.\n"
                          "• Eine andere Einundzwanzig-App kann prüfen, ob die Zahl der Badges manipuliert wurde.\n"
                          "• Format: 21:DATEN.SIGNATUR",
                          style: TextStyle(
                            color: cTextSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Kleiner Abstand unten, damit der FAB nicht den Text verdeckt
                  const SizedBox(height: 60),
                ],
              ),
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
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: cTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}