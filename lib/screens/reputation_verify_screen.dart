// ============================================
// REPUTATION VERIFY SCREEN — Remote-Verifikation
// ============================================
// Prüft die Reputation einer anderen Person.
//
// Input: Verify-String oder npub
//   - Verify-String: 21rep::npub1...::plattform::username::sig=...
//   - Reiner npub: npub1...
//
// Output: Vertrauensstufe + Reputation-Details
//   - Stufe 3: Vollständig verifiziert (grün)
//   - Stufe 2: Teilweise verifiziert (gelb)
//   - Stufe 1: Nur Signatur (orange)
//   - Stufe 0: Ungültig (rot)
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/platform_proof_service.dart';
import '../services/reputation_publisher.dart';

class ReputationVerifyScreen extends StatefulWidget {
  /// Optional: Vorausgefüllter Verify-String (z.B. aus Clipboard)
  final String? initialInput;

  const ReputationVerifyScreen({super.key, this.initialInput});

  @override
  State<ReputationVerifyScreen> createState() => _ReputationVerifyScreenState();
}

class _ReputationVerifyScreenState extends State<ReputationVerifyScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isVerifying = false;
  ProofVerifyResult? _result;

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
      _result = null;
    });

    final result = await PlatformProofService.verifyProofString(input);

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _result = result;
      });
    }
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
            // Beschreibung
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
                      "um ihre Meetup-Reputation zu prüfen.",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Input-Feld
            TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '21rep::npub1...::plattform::user::sig=...\noder npub1...',
                hintStyle: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                filled: true,
                fillColor: cCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: cCyan, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, color: Colors.grey),
                  onPressed: _pasteFromClipboard,
                  tooltip: 'Einfügen',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Prüfen-Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isVerifying ? null : _verify,
                icon: _isVerifying
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.search, size: 20),
                label: Text(_isVerifying ? "PRÜFE..." : "REPUTATION PRÜFEN"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cCyan,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: cCyan.withOpacity(0.5),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Ergebnis
            if (_result != null) _buildResult(_result!),
          ],
        ),
      ),
    );
  }

  // =============================================
  // ERGEBNIS ANZEIGEN
  // =============================================

  Widget _buildResult(ProofVerifyResult result) {
    final Color color;
    final IconData icon;
    final String title;

    switch (result.level) {
      case VerifyLevel.full:
        color = Colors.green;
        icon = Icons.verified;
        title = "VOLLSTÄNDIG VERIFIZIERT";
        break;
      case VerifyLevel.partial:
        color = Colors.amber;
        icon = Icons.shield;
        title = "TEILWEISE VERIFIZIERT";
        break;
      case VerifyLevel.signatureOnly:
        color = cOrange;
        icon = Icons.lock_outline;
        title = "NUR SIGNATUR GEPRÜFT";
        break;
      case VerifyLevel.invalid:
        color = Colors.red;
        icon = Icons.dangerous;
        title = "UNGÜLTIG";
        break;
    }

    return Column(
      children: [
        // Status-Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4), width: 2),
          ),
          child: Column(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),

        // Plattform-Info (wenn vorhanden)
        if (result.platform != null && result.claimedUsername != null) ...[
          const SizedBox(height: 16),
          _buildInfoRow(Icons.language, "Plattform", result.platform!),
          _buildInfoRow(Icons.person, "Username", result.claimedUsername!),
          if (result.proofInEvent)
            _buildInfoRow(Icons.check_circle, "Plattform-Proof", "Im Reputation-Event bestätigt",
                color: Colors.green),
        ],

        // npub
        if (result.npub != null) ...[
          const SizedBox(height: 16),
          _buildInfoRow(Icons.key, "npub", _shortenNpub(result.npub!)),
        ],

        // Reputation-Details (wenn von Relay geholt)
        if (result.reputation != null) ...[
          const SizedBox(height: 20),
          _buildReputationDetails(result.reputation!),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey, size: 18),
            const SizedBox(width: 10),
            Text("$label: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: label == 'npub' ? 'monospace' : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReputationDetails(ReputationEvent rep) {
    final color = _levelColor(rep.level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nickname + Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rep.nickname,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rep.level,
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  rep.score.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("${rep.boundBadges}", "Gebunden", Colors.green),
              _buildStat("${rep.totalBadges}", "Badges", cOrange),
              _buildStat("${rep.meetupCount}", "Meetups", cCyan),
              _buildStat("${rep.signerCount}", "Signer", cPurple),
            ],
          ),

          const SizedBox(height: 16),

          // Zusatz-Info
          if (rep.since.isNotEmpty)
            _buildDetailRow("Aktiv seit", rep.since),
          if (rep.retroactiveBadges > 0)
            _buildDetailRow("Retroaktiv", "${rep.retroactiveBadges} Badges (reduzierter Wert)"),
          if (!rep.isFresh)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange.shade300, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "Letztes Update vor ${rep.ageInHours}h",
                    style: TextStyle(color: Colors.orange.shade300, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text("$label: ", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Color _levelColor(String level) {
    switch (level) {
      case 'VETERAN': return Colors.amber;
      case 'ETABLIERT': return Colors.green;
      case 'AKTIV': return cCyan;
      case 'STARTER': return cOrange;
      default: return Colors.grey;
    }
  }

  String _shortenNpub(String npub) {
    if (npub.length < 20) return npub;
    return '${npub.substring(0, 12)}...${npub.substring(npub.length - 8)}';
  }
}