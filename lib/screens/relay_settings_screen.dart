// ============================================
// RELAY SETTINGS SCREEN — Nostr-Relay Verwaltung
// ============================================
// Zeigt Default-Relays (ein/ausschaltbar) und
// benutzerdefinierte Relays (hinzufügen/entfernen).
//
// Erreichbar über: Dashboard → Einstellungen → Nostr-Relays
// ============================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/relay_config.dart';

class RelaySettingsScreen extends StatefulWidget {
  const RelaySettingsScreen({super.key});

  @override
  State<RelaySettingsScreen> createState() => _RelaySettingsScreenState();
}

class _RelaySettingsScreenState extends State<RelaySettingsScreen> {
  Map<String, bool> _relayStatus = {};
  List<String> _customRelays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final status = await RelayConfig.getRelayStatus();
    final custom = await RelayConfig.getCustomRelays();
    if (mounted) {
      setState(() {
        _relayStatus = status;
        _customRelays = custom;
        _isLoading = false;
      });
    }
  }

  void _toggleDefault(String url, bool enabled) async {
    await RelayConfig.setDefaultRelayEnabled(url, enabled);
    _load();
  }

  void _addCustomRelay() {
    final controller = TextEditingController(text: 'wss://');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("RELAY HINZUFÜGEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'wss://mein-relay.de',
            hintStyle: TextStyle(color: Colors.grey.shade700),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ABBRECHEN", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await RelayConfig.addCustomRelay(controller.text);
                Navigator.pop(context);
                _load();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            child: const Text("HINZUFÜGEN", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _removeCustomRelay(String url) async {
    await RelayConfig.removeCustomRelay(url);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("NOSTR-RELAYS")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cCyan.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.hub, color: cCyan, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Relays verteilen deine Reputation im Nostr-Netzwerk. "
                            "Die App nutzt alle aktiven Relays gleichzeitig für maximale Erreichbarkeit.",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Default-Relays
                  const Text("DEFAULT-RELAYS",
                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),

                  ...RelayConfig.defaultRelays.map((url) {
                    final enabled = _relayStatus[url] ?? true;
                    return _buildRelayTile(
                      url: url,
                      enabled: enabled,
                      isDefault: true,
                      onToggle: (v) => _toggleDefault(url, v),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Custom-Relays
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("EIGENE RELAYS",
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      GestureDetector(
                        onTap: _addCustomRelay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cOrange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: cOrange, size: 14),
                              SizedBox(width: 4),
                              Text("HINZUFÜGEN", style: TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_customRelays.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "Keine eigenen Relays konfiguriert.",
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ..._customRelays.map((url) => _buildRelayTile(
                      url: url,
                      enabled: true,
                      isDefault: false,
                      onRemove: () => _removeCustomRelay(url),
                    )),

                  const SizedBox(height: 30),

                  // Aktive Relays Zusammenfassung
                  FutureBuilder<List<String>>(
                    future: RelayConfig.getActiveRelays(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: count > 0 ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: count > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              count > 0 ? Icons.check_circle : Icons.error_outline,
                              color: count > 0 ? Colors.green : Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              count > 0 ? "$count aktive Relays" : "Keine Relays aktiv!",
                              style: TextStyle(
                                color: count > 0 ? Colors.green.shade300 : Colors.red.shade300,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRelayTile({
    required String url,
    required bool enabled,
    required bool isDefault,
    Function(bool)? onToggle,
    VoidCallback? onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: enabled ? Colors.green.withOpacity(0.2) : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              enabled ? Icons.cloud_done : Icons.cloud_off,
              color: enabled ? Colors.green : Colors.grey.shade700,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                url,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey.shade600,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDefault && onToggle != null)
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: Colors.green,
              ),
            if (!isDefault && onRemove != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                onPressed: onRemove,
                tooltip: 'Entfernen',
              ),
          ],
        ),
      ),
    );
  }
}