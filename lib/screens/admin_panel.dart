import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../models/user.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import '../services/rolling_qr_service.dart'; // Import für den zentralen Session-Manager
import 'admin_management.dart';
import 'meetup_session_wizard.dart'; // Der Wizard für den Ablauf
import 'rolling_qr_screen.dart'; // NEU: Import für den direkten Sprung zum QR Code

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isSuperAdmin = false;
  String _adminNpub = '';
  String _promotionSource = '';

  // --- Session State ---
  DateTime? _sessionExpiry;
  Timer? _countdownTimer;
  String _timeLeft = "";

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _checkSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  // Prüft, ob noch eine 6-Stunden Session läuft
  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    // THE FIX: Korrekter Abruf als int (Unix Timestamp)
    final int? expiryUnix = prefs.getInt('rqr_session_expires');

    if (expiryUnix != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiryUnix * 1000);
      if (DateTime.now().isBefore(expiry)) {
        setState(() {
          _sessionExpiry = expiry;
        });
        _startTimer();
      } else {
        // Session ist abgelaufen
        await RollingQRService.endSession();
        setState(() {
          _sessionExpiry = null;
        });
      }
    } else {
      setState(() {
        _sessionExpiry = null;
      });
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionExpiry != null) {
        final diff = _sessionExpiry!.difference(DateTime.now());
        if (diff.isNegative) {
          _checkSession(); // Timer beenden und UI resetten
        } else {
          if (mounted) {
            setState(() {
              _timeLeft = "${diff.inHours}h ${(diff.inMinutes % 60).toString().padLeft(2, '0')}m ${(diff.inSeconds % 60).toString().padLeft(2, '0')}s";
            });
          }
        }
      }
    });
  }

  // Startet eine brandneue 6-Stunden Session
  Future<void> _startNewSession() async {
    final user = await UserProfile.load();
    final meetupId = user.homeMeetupId.isNotEmpty ? user.homeMeetupId : 'unknown-meetup';
    final compactId = meetupId.toLowerCase().replaceAll(' ', '-');

    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: cOrange))
    );

    try {
      await RollingQRService.getOrCreateSession(
          meetupId: compactId, 
          meetupName: meetupId, 
          meetupCountry: '', 
          blockHeight: 0
      );
      
      if (mounted) {
        Navigator.pop(context); // Lade-Dialog schließen
        _checkSession(); // Timer und UI updaten

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MeetupSessionWizard()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Lade-Dialog schließen
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // Bricht die Session manuell ab (z.B. Meetup früher beendet)
  Future<void> _endSessionEarly() async {
    await RollingQRService.endSession();
    _countdownTimer?.cancel();
    setState(() {
      _sessionExpiry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSessionActive = _sessionExpiry != null;

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
                    "Erstelle NFC Tags und Rolling QR-Codes für dein Meetup. Teilnehmer scannen diese, um Badges zu sammeln.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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

            // --- UNIFIED SESSION CONTROLLER ---
            Text(
              "MEETUP SESSION",
              style: TextStyle(color: cOrange, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),

            if (isSessionActive) ...[
              // ACTIVE SESSION UI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.5), width: 1.5),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      "SESSION LÄUFT",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Endet in $_timeLeft",
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // THE FIX: Direkter Sprung zum QR Code!
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RollingQRScreen()),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("AKTIVES MEETUP ÖFFNEN", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: cCard,
                            title: const Text("Session beenden?", style: TextStyle(color: Colors.white)),
                            content: const Text("Damit sperrst du die aktuelle Blockzeit. Du kannst danach eine neue Session starten.", style: TextStyle(color: Colors.grey)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbrechen", style: TextStyle(color: Colors.grey))),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Beenden", style: TextStyle(color: Colors.red))),
                            ],
                          )
                        );
                        if (confirm == true) _endSessionEarly();
                      },
                      child: const Text("Meetup vorzeitig beenden", style: TextStyle(color: Colors.redAccent)),
                    )
                  ],
                ),
              ),
            ] else ...[
              // INACTIVE SESSION UI
              _buildAdminTile(
                context: context,
                icon: Icons.power_settings_new,
                color: cOrange,
                title: "MEETUP STARTEN",
                subtitle: "Generiert einen neuen kryptographischen Beweis für die nächsten 6 Stunden.",
                onTap: () async {
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: cCard,
                      title: const Text("Neues Meetup starten?", style: TextStyle(color: Colors.white)),
                      content: const Text("Dies erstellt eine eindeutige Signatur (Blockzeit) für die nächsten 6 Stunden. In dieser Zeit ist die Erstellung neuer Sessions gesperrt.", style: TextStyle(color: Colors.grey)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbrechen", style: TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black),
                          onPressed: () => Navigator.pop(context, true), 
                          child: const Text("Starten")
                        ),
                      ],
                    )
                  );
                  if (confirm == true) _startNewSession();
                },
              ),
            ],
            
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
                    "1. Starte ein neues Meetup (Session).\n"
                    "2. Beschreibe danach NFC Tags oder zeige den QR-Code.\n"
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