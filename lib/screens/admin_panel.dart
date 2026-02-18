import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import 'nfc_writer.dart';
import 'admin_management.dart';
import 'rolling_qr_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isSuperAdmin = false;
  String _adminNpub = '';
  String _promotionSource = '';

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  void _loadAdminInfo() async {
    final user = await UserProfile.load();
    final npub = await NostrService.getNpub();
    if (mounted) {
      setState(() {
        _isSuperAdmin = npub == AdminRegistry.superAdminNpub;
        _adminNpub = npub ?? '';
        _promotionSource = user.promotionSource;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("ORGANISATOR")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified, size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "ORGANISATOR TOOLS",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Erstelle NFC Tags und Rolling QR-Codes für dein Meetup. "
                    "Teilnehmer scannen diese um Badges zu sammeln.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  // Status-Badges
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_adminNpub.isNotEmpty)
                        _buildStatusChip(
                          icon: Icons.key,
                          label: NostrService.shortenNpub(_adminNpub, chars: 6),
                          color: cPurple,
                        ),
                      _buildStatusChip(
                        icon: _promotionSource == 'trust_score' ? Icons.trending_up : Icons.star,
                        label: _promotionSource == 'trust_score' 
                            ? 'Via Trust Score'
                            : _promotionSource == 'seed_admin'
                                ? 'Seed Admin'
                                : 'Organisator',
                        color: _promotionSource == 'trust_score' ? Colors.green : cOrange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // NFC Tag erstellen
            _buildAdminTile(
              context: context,
              icon: Icons.nfc,
              color: cOrange,
              title: "NFC TAG ERSTELLEN",
              subtitle: "NFC-Tag auf den Tisch legen, Teilnehmer halten Handy dran",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NFCWriterScreen()),
                );
              },
            ),
            
            const SizedBox(height: 16),

            // Rolling QR-Code
            _buildAdminTile(
              context: context,
              icon: Icons.qr_code_2,
              color: cOrange,
              title: "ROLLING QR-CODE",
              subtitle: "QR-Code auf dem Handy anzeigen, ändert sich alle 30 Sekunden",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RollingQRScreen()),
                );
              },
            ),

            // Admin-Verwaltung (nur Super-Admin)
            if (_isSuperAdmin) ...[
              const SizedBox(height: 32),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt, color: cPurple, size: 16),
                    SizedBox(width: 6),
                    Text("SEED ADMIN", style: TextStyle(color: cPurple, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildAdminTile(
                context: context,
                icon: Icons.group_add,
                color: cPurple,
                title: "ORGANISATOREN DELEGIEREN",
                subtitle: "Neue Organisatoren in anderen Städten per Nostr-Event ernennen",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminManagementScreen()),
                  );
                },
              ),
            ],

            const SizedBox(height: 32),
            
            // Info Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cOrange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.info_outline, color: cOrange, size: 20),
                    SizedBox(width: 8),
                    Text("SO FUNKTIONIERT'S", style: TextStyle(color: cOrange, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    "1. Erstelle einen NFC Tag oder starte den Rolling QR-Code\n"
                    "2. Teilnehmer scannen mit ihrer App\n"
                    "3. Jeder Scan = ein Badge für den Teilnehmer\n"
                    "4. Badges bauen Reputation auf → mehr Reputation = neue Organisatoren",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.6, color: cTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 11)),
        ],
      ),
    );
  }
  
  Widget _buildAdminTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cBorder, width: 1),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)),
              ],
            )),
            const Icon(Icons.arrow_forward_ios, color: cTextTertiary, size: 18),
          ]),
        ),
      ),
    );
  }
}