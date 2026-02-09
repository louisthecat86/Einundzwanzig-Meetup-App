import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';

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
    
    // QR-Code: Lesbare Zusammenfassung + komprimierte Badge-Hashes
    final badgeHashes = myBadges.map((b) => b.getVerificationHash()).join(',');
    final qrText = 'EINUNDZWANZIG REPUTATION\n'
                   'Badges: ${myBadges.length}\n'
                   'Meetups: $uniqueMeetups\n'
                   '${user.nostrNpub.isNotEmpty ? 'Npub: ${user.nostrNpub}\n' : ''}'
                   'Hashes: $badgeHashes\n'
                   'Verifizieren: einundzwanzig.space';
    
    // Vollständiges JSON für Kopieren
    final json = MeetupBadge.exportBadgesForReputation(myBadges, user.nostrNpub);
    
    setState(() {
      _qrData = qrText;
      _fullJson = json;
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
                        const Icon(Icons.qr_code_2, color: cOrange, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          "DEINE REPUTATION",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cOrange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Zeige diesen QR-Code, um deine Meetup-Teilnahmen nachzuweisen.",
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
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 280,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
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
                          onPressed: () => _copyToClipboard(_qrData, 'QR-Code Text'),
                          icon: const Icon(Icons.copy, size: 20),
                          label: const Text('TEXT KOPIEREN'),
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
                          label: const Text('JSON'),
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
                              "SO FUNKTIONIERT'S",
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
                          "• Dieser QR-Code zeigt deine Reputation lesbar an\n"
                          "• Scanne ihn mit jedem QR-Scanner (Smartphone-Kamera)\n"
                          "• Für technische Verifizierung: JSON-Button nutzen\n"
                          "• Zeige ihn bei satoshikleinanzeigen.space oder Meetups",
                          style: TextStyle(
                            color: cTextSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
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
