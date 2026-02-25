// ============================================
// PLATFORM PROOF SCREEN — Plattform-Verknüpfung
// ============================================
// Erstellt signierte Verify-Strings für Plattformen.
//
// UX: Plattform wählen → Username eingeben → String kopieren
// Einmalig pro Plattform. String wird automatisch im
// Reputation-Event auf Relays gespeichert.
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/badge.dart';
import '../services/platform_proof_service.dart';
import '../services/reputation_publisher.dart';

class PlatformProofScreen extends StatefulWidget {
  const PlatformProofScreen({super.key});

  @override
  State<PlatformProofScreen> createState() => _PlatformProofScreenState();
}

class _PlatformProofScreenState extends State<PlatformProofScreen> {
  List<PlatformProof> _savedProofs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProofs();
  }

  void _loadProofs() async {
    final proofs = await PlatformProofService.getSavedProofs();
    if (mounted) {
      setState(() {
        _savedProofs = proofs;
        _isLoading = false;
      });
    }
  }

  // =============================================
  // NEUEN PROOF ERSTELLEN
  // =============================================

  void _createNewProof() {
    String? selectedPlatform;
    String customPlatformName = '';
    final usernameController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),

              const Text("AUF PLATTFORM TEILEN",
                style: TextStyle(color: cOrange, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text("Erstelle einen Verify-String für eine Plattform.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              const SizedBox(height: 20),

              // Plattform-Auswahl
              const Text("PLATTFORM", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlatformProofService.platforms.entries.map((entry) {
                  final info = entry.value;
                  final isSelected = selectedPlatform == entry.key;
                  // Prüfe ob bereits ein Proof existiert
                  final hasExisting = _savedProofs.any((p) => p.platform == entry.key);

                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => selectedPlatform = entry.key);
                      usernameController.clear();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? cOrange.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? cOrange : (hasExisting ? Colors.green.withOpacity(0.3) : Colors.white10),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_platformIcon(info.icon),
                            color: isSelected ? cOrange : Colors.grey, size: 18),
                          const SizedBox(width: 8),
                          Text(info.name,
                            style: TextStyle(
                              color: isSelected ? cOrange : Colors.white70,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            )),
                          if (hasExisting) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle, color: Colors.green.shade400, size: 14),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Custom-Plattform Name
              if (selectedPlatform == 'other') ...[
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => customPlatformName = v,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Name der Plattform',
                    hintStyle: TextStyle(color: Colors.grey.shade700),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],

              // Username-Eingabe
              if (selectedPlatform != null) ...[
                const SizedBox(height: 16),
                const Text("BENUTZERNAME", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: PlatformProofService.platforms[selectedPlatform]?.hint ?? 'Dein Benutzername',
                    hintStyle: TextStyle(color: Colors.grey.shade700),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.alternate_email, color: Colors.grey, size: 18),
                  ),
                ),
                const SizedBox(height: 20),

                // Erstellen-Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (usernameController.text.trim().isEmpty) return;
                      if (selectedPlatform == 'other' && customPlatformName.trim().isEmpty) return;

                      Navigator.pop(context);
                      await _generateProof(
                        platformId: selectedPlatform!,
                        username: usernameController.text.trim(),
                        customName: selectedPlatform == 'other' ? customPlatformName.trim() : null,
                      );
                    },
                    icon: const Icon(Icons.lock, size: 18),
                    label: const Text("VERIFY-STRING ERSTELLEN"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cOrange,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // PROOF GENERIEREN + ANZEIGEN
  // =============================================

  Future<void> _generateProof({
    required String platformId,
    required String username,
    String? customName,
  }) async {
    final result = await PlatformProofService.createProof(
      platformId: platformId,
      username: username,
      customPlatformName: customName,
    );

    if (!mounted) return;

    if (result.success) {
      // Reputation-Event mit neuem Proof aktualisieren
      final proofs = await PlatformProofService.getProofsForPublishing();
      ReputationPublisher.publish(
        badges: myBadges,
        platformProofs: proofs,
        force: true,
      );

      _loadProofs();
      _showVerifyString(result.verifyString, platformId, username);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  void _showVerifyString(String verifyString, String platform, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text("VERIFY-STRING ERSTELLT",
                style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kopiere diesen String in dein Profil oder deine Anzeige auf der Plattform:",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5)),
            const SizedBox(height: 16),

            // Verify-String Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: SelectableText(
                verifyString,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              "Andere können diesen String in der Einundzwanzig-App prüfen und sehen deine verifizierte Reputation.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("SCHLIEẞEN", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: verifyString));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Verify-String kopiert!"),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("KOPIEREN"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PROOF WIDERRUFEN
  // =============================================

  void _revokeProof(PlatformProof proof) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("VERKNÜPFUNG AUFHEBEN?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          "Die Plattform-Verknüpfung für \"${proof.username}\" auf ${proof.platform} "
          "wird gelöscht. Der Verify-String wird ungültig.\n\n"
          "Du musst dein Reputation-Event danach aktualisieren.",
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
              await PlatformProofService.removeProof(proof.platform);
              // Reputation ohne diesen Proof aktualisieren
              final proofs = await PlatformProofService.getProofsForPublishing();
              ReputationPublisher.publish(
                badges: myBadges,
                platformProofs: proofs,
                force: true,
              );
              Navigator.pop(context);
              _loadProofs();
            },
            child: const Text("WIDERRUFEN", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // UI
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("PLATTFORM-VERKNÜPFUNG")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info-Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cOrange.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.link, color: cOrange, size: 22),
                          const SizedBox(width: 10),
                          const Text("SO FUNKTIONIERT'S",
                            style: TextStyle(color: cOrange, fontSize: 13, fontWeight: FontWeight.w800)),
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          "1. Wähle eine Plattform und gib deinen Usernamen ein\n"
                          "2. Die App erstellt einen signierten Verify-String\n"
                          "3. Kopiere den String in dein Plattform-Profil\n"
                          "4. Andere können deinen String prüfen und sehen deine Reputation",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.6),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bestehende Proofs
                  if (_savedProofs.isNotEmpty) ...[
                    const Text("AKTIVE VERKNÜPFUNGEN",
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    ..._savedProofs.map((proof) => _buildProofCard(proof)),
                    const SizedBox(height: 20),
                  ],

                  // Neuen Proof erstellen
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _createNewProof,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(_savedProofs.isEmpty ? "PLATTFORM VERKNÜPFEN" : "WEITERE PLATTFORM"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cOrange,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProofCard(PlatformProof proof) {
    final platformInfo = PlatformProofService.platforms[proof.platform];
    final platformName = platformInfo?.name ?? proof.platform;
    final iconData = _platformIcon(platformInfo?.icon ?? 'language');
    final date = DateTime.fromMillisecondsSinceEpoch(proof.createdAt * 1000);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: Colors.green, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(platformName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(proof.username,
                    style: TextStyle(color: Colors.green.shade300, fontSize: 13, fontFamily: 'monospace')),
                  Text("Erstellt: ${date.day}.${date.month}.${date.year}",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                ],
              ),
            ),
            // Kopieren
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.grey, size: 18),
              tooltip: 'Verify-String kopieren',
              onPressed: () async {
                // String aus den gespeicherten Daten regenerieren
                final npub = await SecureKeyStore.getNpub();
                if (npub != null) {
                  final verifyString = '21rep::$npub::${proof.platform}::${proof.username}::sig=${proof.proofSig}';
                  await Clipboard.setData(ClipboardData(text: verifyString));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Kopiert!"), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                    );
                  }
                }
              },
            ),
            // Widerrufen
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
              tooltip: 'Widerrufen',
              onPressed: () => _revokeProof(proof),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _platformIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart': return Icons.shopping_cart;
      case 'send': return Icons.send;
      case 'smart_toy': return Icons.smart_toy;
      case 'hub': return Icons.hub;
      case 'language': return Icons.language;
      default: return Icons.link;
    }
  }
}