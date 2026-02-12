import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/meetup.dart';
import '../models/user.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import 'nfc_writer.dart';
import 'admin_management.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isSuperAdmin = false;
  String _adminNpub = '';

  @override
  void initState() {
    super.initState();
    _checkSuperAdmin();
  }

  void _checkSuperAdmin() async {
    final user = await UserProfile.load();
    final npub = await NostrService.getNpub();
    if (mounted) {
      setState(() {
        _isSuperAdmin = npub == AdminRegistry.superAdminNpub;
        _adminNpub = npub ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("ADMIN BEREICH"),
      ),
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
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "ORGANISATOR TOOLS",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Erstelle NFC Tags für dein Meetup und verifiziere neue Teilnehmer.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  // Nostr Admin Status
                  if (_adminNpub.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.key, color: cPurple, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            NostrService.shortenNpub(_adminNpub, chars: 6),
                            style: const TextStyle(color: cPurple, fontFamily: 'monospace', fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Option 1: Badge Tag erstellen
            _buildAdminTile(
              context: context,
              icon: Icons.bookmark,
              color: cOrange,
              title: "MEETUP TAG ERSTELLEN",
              subtitle: "Teilnehmer können diesen Tag scannen um ein Badge zu erhalten",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NFCWriterScreen(mode: NFCWriteMode.badge),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Option 2: Verifizierungs-Tag erstellen
            _buildAdminTile(
              context: context,
              icon: Icons.verified_user,
              color: cCyan,
              title: "VERIFIZIERUNGS-TAG ERSTELLEN",
              subtitle: "Neue Nutzer scannen diesen Tag zur Identitätsbestätigung",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NFCWriterScreen(mode: NFCWriteMode.verify),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Option 3: Admin-Verwaltung (nur Super-Admin)
            if (_isSuperAdmin) ...[
              _buildAdminTile(
                context: context,
                icon: Icons.group,
                color: cPurple,
                title: "ADMIN-VERWALTUNG",
                subtitle: "Meetup-Organisatoren hinzufügen oder entfernen",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminManagementScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
            ] else ...[
              // Kein Super-Admin → trotzdem Divider
            ],
            
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
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: cOrange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "HINWEIS",
                        style: TextStyle(
                          color: cOrange,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "• Der Meetup Tag kann von allen Teilnehmern gescannt werden\n"
                    "• Der Verifizierungs-Tag ist nur für neue Nutzer gedacht\n"
                    "• Nach erfolgreicher Verifizierung verschwindet diese Funktion beim Nutzer",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.6,
                      color: cTextSecondary,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: cTextTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}