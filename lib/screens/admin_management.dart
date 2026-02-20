// ============================================
// ADMIN MANAGEMENT SCREEN v3 (WEB OF TRUST)
// Dezentrales Peer-to-Peer Vouching (Ritterschlag)
// ============================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import '../theme.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  List<AdminEntry> _admins = [];
  bool _isLoading = true;
  bool _isPublishing = false;
  bool _isRefreshing = false;
  Duration? _cacheAge;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    final admins = await AdminRegistry.getAdminList();
    final age = await AdminRegistry.cacheAge();
    if (mounted) {
      setState(() {
        _admins = admins;
        _cacheAge = age;
        _isLoading = false;
      });
    }
  }

  // --- QR SCANNER FÜR NPUB ---
  Future<String?> _scanNpub() async {
    return await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _NpubScannerScreen()),
    );
  }

  // --- ADMIN HINZUFÜGEN (DER RITTERSCHLAG) ---
  void _addAdmin() {
    final npubController = TextEditingController();
    final meetupController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: Row(
          children: const [
            Icon(Icons.shield, color: cPurple),
            SizedBox(width: 8),
            Text("CO-ADMIN RITTERN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Du bürgst mit deiner eigenen Reputation für diesen neuen Organisator.",
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              
              // npub Feld mit Scan-Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: npubController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11),
                      decoration: InputDecoration(
                        labelText: "npub (Pflicht)",
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintText: "npub1...",
                        filled: true, fillColor: cDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: cCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: cCyan),
                      onPressed: () async {
                        final scannedNpub = await _scanNpub();
                        if (scannedNpub != null && mounted) {
                          setState(() {
                            npubController.text = scannedNpub;
                          });
                        }
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meetupController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Meetup (z.B. München)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Name / Alias (optional)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true, fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ABBRECHEN", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cPurple, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await AdminRegistry.addAdmin(AdminEntry(
                  npub: npubController.text.trim(),
                  meetup: meetupController.text.trim(),
                  name: nameController.text.trim(),
                ));
                if (mounted) {
                  Navigator.pop(context);
                  _loadAdmins();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Co-Admin hinzugefügt! Vergiss nicht zu publishen."), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("VERBÜRGEN", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- ADMIN ENTFERNEN ---
  void _removeAdmin(AdminEntry admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("VERTRAUEN ENTZIEHEN?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          "Möchtest du ${admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub)} "
          "das Vertrauen als Admin für ${admin.meetup} entziehen?\n\n"
          "Du musst die Liste danach neu publishen, damit das Netzwerk davon erfährt.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ABBRECHEN", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await AdminRegistry.removeAdmin(admin.npub);
              if (mounted) {
                Navigator.pop(context);
                _loadAdmins();
              }
            },
            child: const Text("ENTFERNEN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- AUF RELAYS PUBLISHEN (Der eigentliche Beweis) ---
  void _publishToRelays() async {
    setState(() {
      _isPublishing = true;
      _statusMessage = 'Signiere und sende an Nostr...';
    });

    try {
      final result = await AdminRegistry.createAndPublishAdminListEvent();
      final data = jsonDecode(result);
      final sentTo = data['sent_to'] ?? 0;

      setState(() {
        _isPublishing = false;
        _statusMessage = '✅ Dein Web of Trust ist live ($sentTo Relays)!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Deine Delegation wurde kryptografisch signiert und im Netzwerk veröffentlicht!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isPublishing = false;
        _statusMessage = '❌ Fehler: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- VON RELAYS LADEN ---
  void _refreshFromRelays() async {
    setState(() {
      _isRefreshing = true;
      _statusMessage = 'Synchronisiere Web of Trust...';
    });

    try {
      final count = await AdminRegistry.forceRefresh();
      if (count >= 0) {
        await _loadAdmins();
        setState(() {
          _isRefreshing = false;
          _statusMessage = '✅ Web of Trust aktuell ($count Admins verifiziert)';
        });
      } else {
        setState(() {
          _isRefreshing = false;
          _statusMessage = '⚠️ Keine neuen Updates gefunden';
        });
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _statusMessage = '❌ Sync fehlgeschlagen: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("MEIN WEB OF TRUST"),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cCyan))
                : const Icon(Icons.sync, color: cCyan),
            tooltip: "Web of Trust synchronisieren",
            onPressed: _isRefreshing ? null : _refreshFromRelays,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAdmin,
        backgroundColor: cPurple,
        icon: const Icon(Icons.shield, color: Colors.white),
        label: const Text("RITTERSCHLAG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cPurple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info & Status Header
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cPurple.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hub, color: cPurple, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "DEINE DELEGATIONEN",
                                  style: TextStyle(color: cPurple, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Du hast dich für ${_admins.length} Organisator${_admins.length != 1 ? 'en' : ''} verbürgt.",
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_statusMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _statusMessage.startsWith('✅') ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: _statusMessage.startsWith('✅') ? Colors.green
                                  : _statusMessage.startsWith('❌') ? Colors.redAccent
                                  : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // PUBLISH Button (Immer sichtbar, wenn Änderungen da sind, aber hier zur Sicherheit immer aktiv wenn >0)
                if (_admins.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isPublishing ? null : _publishToRelays,
                      icon: _isPublishing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.satellite_alt, color: Colors.white),
                      label: Text(
                        _isPublishing ? "SIGNIERE & PUBLIZIERE..." : "AUF NOSTR PUBLISHEN",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cOrange, // Orange als Call-to-Action
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Das Netzwerk erfährt erst von deinen neuen Co-Admins,\nwenn du deine Signatur auf Nostr veröffentlichst.",
                    style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],

                // Admin-Liste
                if (_admins.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: const [
                        Icon(Icons.group_off, size: 64, color: Colors.white12),
                        SizedBox(height: 16),
                        Text("Du hast noch niemanden delegiert.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(height: 12),
                        Text(
                          "Tippe unten auf 'RITTERSCHLAG',\num einem neuen Organisator in deinem\nMeetup das Vertrauen auszusprechen.",
                          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ..._admins.map((admin) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cPurple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.verified_user, color: cPurple, size: 24),
                      ),
                      title: Text(
                        admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (admin.meetup.isNotEmpty)
                            Text("📍 ${admin.meetup}", style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            NostrService.shortenNpub(admin.npub, chars: 8),
                            style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                        tooltip: "Vertrauen entziehen",
                        onPressed: () => _removeAdmin(admin),
                      ),
                    ),
                  )),

                const SizedBox(height: 100), // Platz für FAB
              ],
            ),
    );
  }
}

// ============================================
// HELPER SCREEN: NPUB QR SCANNER
// ============================================
class _NpubScannerScreen extends StatefulWidget {
  const _NpubScannerScreen();

  @override
  State<_NpubScannerScreen> createState() => _NpubScannerScreenState();
}

class _NpubScannerScreenState extends State<_NpubScannerScreen> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      String? code = barcode.rawValue;
      if (code != null) {
        // Bereinigen (oft ist ein "nostr:" davor)
        code = code.trim().toLowerCase();
        if (code.startsWith('nostr:')) {
          code = code.replaceFirst('nostr:', '');
        }

        // Prüfen, ob es ein valider npub ist
        if (code.startsWith('npub1') && code.length > 50) {
          setState(() => _isScanned = true);
          Navigator.pop(context, code);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("NPUB SCANNEN"), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Positioned(
            bottom: 60, left: 40, right: 40,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cPurple),
              ),
              child: const Text(
                "Scanne den Nostr-QR-Code (npub) des neuen Organisators.",
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4), 
                textAlign: TextAlign.center
              ),
            ),
          ),
        ],
      ),
    );
  }
}
