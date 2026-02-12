// ============================================
// ADMIN MANAGEMENT SCREEN v2
// Publish to relays + refresh from relays
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  filled: true, fillColor: cDark,
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
                  filled: true, fillColor: cDark,
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
          "als Admin für ${admin.meetup} entfernt werden?\n\n"
          "Vergiss nicht danach neu zu publishen!",
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

  // --- AUF RELAYS PUBLISHEN ---
  void _publishToRelays() async {
    setState(() {
      _isPublishing = true;
      _statusMessage = 'Sende an Nostr Relays...';
    });

    try {
      final result = await AdminRegistry.createAndPublishAdminListEvent();
      final data = jsonDecode(result);
      final sentTo = data['sent_to'] ?? 0;

      setState(() {
        _isPublishing = false;
        _statusMessage = '✅ An $sentTo Relay(s) gesendet!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Admin-Liste an $sentTo Relay(s) published!"),
            backgroundColor: Colors.green,
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
      _statusMessage = 'Lade von Nostr Relays...';
    });

    try {
      final count = await AdminRegistry.forceRefresh();
      if (count >= 0) {
        await _loadAdmins();
        setState(() {
          _isRefreshing = false;
          _statusMessage = '✅ $count Admin(s) von Relays geladen';
        });
      } else {
        setState(() {
          _isRefreshing = false;
          _statusMessage = '⚠️ Kein Event auf Relays gefunden';
        });
      }
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _statusMessage = '❌ $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("ADMIN-VERWALTUNG"),
        actions: [
          // Refresh von Relays
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cCyan))
                : const Icon(Icons.refresh, color: cCyan),
            tooltip: "Von Relays laden",
            onPressed: _isRefreshing ? null : _refreshFromRelays,
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Header
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
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
                      if (_statusMessage.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _statusMessage.startsWith('✅') ? Colors.green
                                : _statusMessage.startsWith('❌') ? Colors.red
                                : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // PUBLISH Button
                if (_admins.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isPublishing ? null : _publishToRelays,
                      icon: _isPublishing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.publish, color: Colors.white),
                      label: Text(
                        _isPublishing ? "WIRD GESENDET..." : "AUF NOSTR PUBLISHEN",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sendet die Admin-Liste als signiertes Nostr Event an alle Relays. "
                    "Alle Apps können die Liste dann automatisch laden.",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                // Admin-Liste
                if (_admins.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: const [
                        Icon(Icons.group_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Noch keine Admins", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        SizedBox(height: 8),
                        Text(
                          "Tippe + um Meetup-Organisatoren hinzuzufügen.\n"
                          "Tippe 🔄 oben rechts um die Liste von Nostr-Relays zu laden.",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
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