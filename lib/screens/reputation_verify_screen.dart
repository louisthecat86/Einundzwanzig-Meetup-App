// ============================================
// REPUTATION VERIFY SCREEN v2 — Multi-Layer
// ============================================
// Prüft die Reputation einer anderen Person
// über alle 4 Beweis-Layer:
//
//   1. Physisch: Badge-Daten aus Reputation-Event
//   2. Lightning: Zap-Aktivität von Relays
//   3. Sozial: Contact-List-Analyse (mutual, common)
//   4. Identität: NIP-05, Plattform-Proofs
//
// Input: Verify-String oder npub
// Output: Multi-Layer Vertrauensbewertung
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr/nostr.dart';
import '../theme.dart';
import '../services/platform_proof_service.dart';
import '../services/reputation_publisher.dart';
import '../services/social_graph_service.dart';
import '../services/zap_verification_service.dart';
import '../services/nip05_service.dart';
import '../services/relay_config.dart';
import '../widgets/reputation_layers_widget.dart';

class ReputationVerifyScreen extends StatefulWidget {
  final String? initialInput;

  const ReputationVerifyScreen({super.key, this.initialInput});

  @override
  State<ReputationVerifyScreen> createState() => _ReputationVerifyScreenState();
}

class _ReputationVerifyScreenState extends State<ReputationVerifyScreen> {
  final TextEditingController _inputController = TextEditingController();

  bool _isVerifying = false;
  String _statusText = '';
  ProofVerifyResult? _proofResult;

  // Multi-Layer State
  SocialAnalysis? _socialAnalysis;
  ZapStats? _zapStats;
  Nip05Result? _nip05Result;
  bool _layersLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialInput != null && widget.initialInput!.isNotEmpty) {
      _inputController.text = widget.initialInput!;
      _verify();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _verify() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _statusText = 'Prüfe Signatur...';
      _proofResult = null;
      _socialAnalysis = null;
      _zapStats = null;
      _nip05Result = null;
    });

    final result = await PlatformProofService.verifyProofString(input);

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _proofResult = result;
      });

      if (result.npub != null && result.level != VerifyLevel.invalid) {
        _loadLayers(result.npub!);
      }
    }
  }

  // =============================================
  // MULTI-LAYER ANALYSE (parallel im Hintergrund)
  // =============================================

  void _loadLayers(String npub) async {
    setState(() => _layersLoading = true);

    String pubkeyHex;
    try {
      pubkeyHex = Nip19.decodePubkey(npub);
    } catch (e) {
      setState(() => _layersLoading = false);
      return;
    }

    // Alle 3 Layer parallel laden
    await Future.wait([
      _loadSocial(pubkeyHex),
      _loadZaps(pubkeyHex),
      _loadNip05(pubkeyHex),
    ]);

    if (mounted) setState(() => _layersLoading = false);
  }

  Future<void> _loadSocial(String pubkeyHex) async {
    try {
      if (mounted) setState(() => _statusText = 'Analysiere Nostr-Netzwerk...');
      final analysis = await SocialGraphService.analyze(pubkeyHex);
      if (mounted) setState(() => _socialAnalysis = analysis);
    } catch (_) {}
  }

  Future<void> _loadZaps(String pubkeyHex) async {
    try {
      if (mounted) setState(() => _statusText = 'Prüfe Lightning-Aktivität...');
      final stats = await ZapVerificationService.analyzeZapActivity(pubkeyHex, useCache: false);
      if (mounted) setState(() => _zapStats = stats);
    } catch (_) {}
  }

  Future<void> _loadNip05(String pubkeyHex) async {
    try {
      if (mounted) setState(() => _statusText = 'Prüfe NIP-05...');
      final relays = await RelayConfig.getActiveRelays();
      final nip05 = await Nip05Service.fetchNip05FromProfile(pubkeyHex, relays);
      if (nip05 != null && nip05.isNotEmpty) {
        final result = await Nip05Service.verify(nip05, pubkeyHex);
        if (mounted) setState(() => _nip05Result = result);
      }
    } catch (_) {}
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _inputController.text = data.text!;
      _verify();
    }
  }

  // =============================================
  // UI
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("REPUTATION PRÜFEN")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cCyan.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user, color: cCyan, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Füge den Verify-String oder npub einer Person ein, "
                      "um ihre Reputation über alle Beweis-Layer zu prüfen.",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input
            TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '21rep::npub1...::plattform::user::sig=...\noder npub1...',
                hintStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                filled: true,
                fillColor: cCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cCyan, width: 2)),
                suffixIcon: IconButton(icon: const Icon(Icons.paste, color: Colors.grey), onPressed: _pasteFromClipboard),
              ),
            ),

            const SizedBox(height: 16),

            // Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isVerifying ? null : _verify,
                icon: _isVerifying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.search, size: 20),
                label: Text(_isVerifying ? "PRÜFE..." : "REPUTATION PRÜFEN"),
                style: ElevatedButton.styleFrom(backgroundColor: cCyan, foregroundColor: Colors.black, disabledBackgroundColor: cCyan.withOpacity(0.5)),
              ),
            ),

            const SizedBox(height: 24),

            // Ergebnis
            if (_proofResult != null) ...[
              _buildResultHeader(_proofResult!),
              const SizedBox(height: 16),

              // Plattform-Info
              if (_proofResult!.platform != null && _proofResult!.claimedUsername != null) ...[
                _buildInfoRow(Icons.language, "Plattform", _proofResult!.platform!),
                _buildInfoRow(Icons.person, "Username", _proofResult!.claimedUsername!),
                if (_proofResult!.proofInEvent)
                  _buildInfoRow(Icons.check_circle, "Plattform-Proof", "Im Event bestätigt", color: Colors.green),
              ],

              if (_proofResult!.npub != null)
                _buildInfoRow(Icons.key, "npub", _shortenNpub(_proofResult!.npub!)),

              const SizedBox(height: 20),

              // Layer-Loading Indikator
              if (_layersLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cCyan)),
                    const SizedBox(width: 10),
                    Text(_statusText, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ]),
                ),

              // Multi-Layer Widget
              if (_proofResult!.reputation != null || _socialAnalysis != null || _zapStats != null)
                ReputationLayersWidget(
                  badgeCount: _proofResult!.reputation?.totalBadges,
                  boundBadges: _proofResult!.reputation?.boundBadges,
                  meetupCount: _proofResult!.reputation?.meetupCount,
                  signerCount: _proofResult!.reputation?.signerCount,
                  meetupScore: _proofResult!.reputation?.score,
                  since: _proofResult!.reputation?.since,
                  accountAgeDays: _proofResult!.reputation?.accountAgeDays,
                  zapStats: _zapStats,
                  socialAnalysis: _socialAnalysis,
                  nip05: _nip05Result,
                  humanityVerified: _proofResult!.reputation?.humanityVerified ?? false,
                  platformProofCount: _proofResult!.reputation?.platformProofs.length,
                  totalScore: _proofResult!.reputation?.score,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // =============================================
  // ERGEBNIS-HEADER
  // =============================================

  Widget _buildResultHeader(ProofVerifyResult result) {
    final Color color;
    final IconData icon;
    final String title;

    switch (result.level) {
      case VerifyLevel.full:
        color = Colors.green; icon = Icons.verified; title = "VOLLSTÄNDIG VERIFIZIERT"; break;
      case VerifyLevel.partial:
        color = Colors.amber; icon = Icons.shield; title = "TEILWEISE VERIFIZIERT"; break;
      case VerifyLevel.signatureOnly:
        color = cOrange; icon = Icons.lock_outline; title = "NUR SIGNATUR GEPRÜFT"; break;
      case VerifyLevel.invalid:
        color = Colors.red; icon = Icons.dangerous; title = "UNGÜLTIG"; break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        if (result.reputation != null) ...[
          Text(result.reputation!.nickname,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
        ],
        Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(result.message, textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.5)),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: color ?? Colors.grey, size: 18),
          const SizedBox(width: 10),
          Text("$label: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Expanded(child: Text(value,
            style: TextStyle(color: color ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
              fontFamily: label == 'npub' ? 'monospace' : null),
            overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  String _shortenNpub(String npub) {
    if (npub.length < 20) return npub;
    return '${npub.substring(0, 12)}...${npub.substring(npub.length - 8)}';
  }
}