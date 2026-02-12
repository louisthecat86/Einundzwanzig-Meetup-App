// ============================================
// ADMIN MANAGEMENT SCREEN
// Nur für den Super-Admin sichtbar
// Verwaltet die Liste vertrauenswürdiger Admins
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Duration? _cacheAge;

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

  // --- ADMIN HINZUFÜGEN ---
  void _addAdmin() {
    final npubController = TextEditingController();
    final meetupController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("ADMIN HINZUFÜGEN",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: npubController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  labelText: "npub (Pflicht)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: "npub1...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meetupController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Meetup (z.B. München)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: cDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Name (optional)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: cDark,
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
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
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
                    const SnackBar(content: Text("✅ Admin hinzugefügt"), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("HINZUFÜGEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text("ADMIN ENTFERNEN?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          "Soll ${admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub)} "
          "als Admin für ${admin.meetup} entfernt werden?",
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

  // --- NOSTR EVENT EXPORTIEREN ---
  void _exportEvent() async {
    try {
      final eventJson = await AdminRegistry.createAdminListEvent();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: cCard,
            title: const Text("NOSTR EVENT", style: TextStyle(color: cPurple, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dieses Event auf Nostr-Relays publishen um die Admin-Liste dezentral zu verteilen:",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      eventJson,
                      style: const TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: cPurple),
                icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                label: const Text("KOPIEREN", style: TextStyle(color: Colors.white)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: eventJson));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Event kopiert!"), backgroundColor: cPurple),
                  );
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("SCHLIEßEN", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("ADMIN-VERWALTUNG"),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload, color: cPurple),
            tooltip: "Nostr Event exportieren",
            onPressed: _exportEvent,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAdmin,
        backgroundColor: cOrange,
        icon: const Icon(Icons.person_add, color: Colors.black),
        label: const Text("ADMIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : _admins.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.group_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Noch keine Admins registriert",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Füge Meetup-Organisatoren über deren npub hinzu. "
                          "Sie werden automatisch als Admin in der App erkannt.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Info Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: cCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cPurple.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.admin_panel_settings, color: cPurple, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_admins.length} ADMIN${_admins.length != 1 ? 'S' : ''} REGISTRIERT",
                                  style: const TextStyle(color: cPurple, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                if (_cacheAge != null)
                                  Text(
                                    "Cache: vor ${_cacheAge!.inMinutes} Min aktualisiert",
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Admin-Liste
                    ..._admins.map((admin) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: cCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person, color: cOrange, size: 24),
                        ),
                        title: Text(
                          admin.name.isNotEmpty ? admin.name : NostrService.shortenNpub(admin.npub),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (admin.meetup.isNotEmpty)
                              Text("📍 ${admin.meetup}", style: const TextStyle(color: cCyan, fontSize: 12)),
                            Text(
                              NostrService.shortenNpub(admin.npub, chars: 6),
                              style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => _removeAdmin(admin),
                        ),
                      ),
                    )),

                    const SizedBox(height: 80), // Platz für FAB
                  ],
                ),
    );
  }
}