// ============================================
// SECURE QR SCANNER v4 — MULTI-LAYER VERIFIKATION
// ============================================
//
// v4: Nach dem Scan werden alle Trust-Layer live
//     geladen und angezeigt:
//     - Platform Proofs aus QR-Payload (sofort)
//     - NIP-05 Verifikation (live von Relays)
//     - Social Graph Analyse (live von Relays)
//     - Zap-Aktivität / Humanity Proof (live)
//
// Format: "21v3:BASE64.SIGNATURE.EVENTID.CREATEDAT.PUBKEY"
// ============================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nostr/nostr.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../services/social_graph_service.dart';
import '../services/zap_verification_service.dart';
import '../services/nip05_service.dart';
import '../services/relay_config.dart';
import '../theme.dart';

class SecureQRScanner extends StatefulWidget {
  const SecureQRScanner({super.key});

  @override
  State<SecureQRScanner> createState() => _SecureQRScannerState();
}

class _SecureQRScannerState extends State<SecureQRScanner> {
  bool _isScanned = false;
  late final MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && (code.startsWith("21:") || code.startsWith("21v2:") || code.startsWith("21v3:"))) {
        setState(() => _isScanned = true);
        _verifyAndShow(code);
        break;
      }
    }
  }

  // =============================================
  // QR-CODE AUS GALERIE LADEN
  // =============================================
  void _pickFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;

      final barcodes = await _scannerController.analyzeImage(path);

      if (barcodes == null || barcodes.barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kein QR-Code im Bild gefunden'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      for (final barcode in barcodes.barcodes) {
        final code = barcode.rawValue;
        if (code != null && (code.startsWith("21:") || code.startsWith("21v2:") || code.startsWith("21v3:"))) {
          setState(() => _isScanned = true);
          _verifyAndShow(code);
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR-Code gefunden, aber kein Einundzwanzig-Format'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verifyAndShow(String fullCode) {
    try {
      final bool isV3 = fullCode.startsWith("21v3:");
      final bool isV2 = fullCode.startsWith("21v2:");
      
      String cleanCode;
      if (isV3) {
        cleanCode = fullCode.substring(5);
      } else if (isV2) {
        cleanCode = fullCode.substring(5);
      } else {
        cleanCode = fullCode.substring(3);
      }

      final parts = cleanCode.split('.');

      // v3: ECHTE SCHNORR-VERIFIKATION
      if (isV3 && parts.length >= 5) {
        final dataBase64 = parts[0];
        final signature = parts[1];
        final eventId = parts[2];
        final createdAt = int.tryParse(parts[3]) ?? 0;
        final pubkeyHex = parts[4];

        final jsonString = utf8.decode(base64.decode(dataBase64));

        final result = BadgeSecurity.verifyQRv3(
          jsonData: jsonString,
          signature: signature,
          eventId: eventId,
          createdAt: createdAt,
          pubkeyHex: pubkeyHex,
        );

        if (result.isValid) {
          final data = jsonDecode(jsonString);
          _showV3Result(data, signerNpub: result.signerNpub, verifyMessage: result.message);
        } else {
          _showFailed(title: "SIGNATUR UNGÜLTIG", subtitle: result.message);
        }
        return;
      }

      // v2: Legacy mit Pubkey
      if (isV2 && parts.length >= 3) {
        final dataBase64 = parts[0];
        final signature = parts[1];
        final pubkeyHex = parts[2];
        final jsonString = utf8.decode(base64.decode(dataBase64));

        final result = BadgeSecurity.verifyQRLegacy(
          jsonData: jsonString,
          signature: signature,
          pubkeyHex: pubkeyHex,
        );

        if (result.isValid) {
          final data = jsonDecode(jsonString);
          _showV2Result(data, signerNpub: result.signerNpub);
        } else {
          _showFailed(title: "SIGNATUR UNGÜLTIG", subtitle: result.message);
        }
        return;
      }

      // v1: Legacy ohne Pubkey
      if (!isV3 && !isV2 && parts.length >= 2) {
        final dataBase64 = parts[0];
        final signature = parts[1];
        final jsonString = utf8.decode(base64.decode(dataBase64));

        final result = BadgeSecurity.verifyQRLegacy(
          jsonData: jsonString,
          signature: signature,
        );

        if (result.isValid) {
          final data = jsonDecode(jsonString);
          _showV1Result(data);
        } else {
          _showFailed(title: "SIGNATUR UNGÜLTIG", subtitle: result.message);
        }
        return;
      }

      _showFailed(title: "FORMAT UNBEKANNT", subtitle: "QR-Code konnte nicht gelesen werden.");
    } catch (e) {
      _showFailed(title: "LESEFEHLER", subtitle: "Fehler beim Verarbeiten: $e");
    }
  }

  void _showV3Result(Map<String, dynamic> data, {required String signerNpub, required String verifyMessage}) {
    final id = data['id'] as Map<String, dynamic>? ?? {};
    final rp = data['rp'] as Map<String, dynamic>? ?? {};
    final pf = data['pf'] as Map<String, dynamic>? ?? {};
    final pp = data['pp'] as Map<String, dynamic>? ?? {};

    final bool hasRealIdentity =
        (id['np'] != null && id['np'].toString().isNotEmpty) ||
        (id['tg'] != null && id['tg'].toString().isNotEmpty) ||
        (id['tw'] != null && id['tw'].toString().isNotEmpty);

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => _VerificationResultScreen(
        isValid: true, version: 3,
        title: "VERIFIZIERT",
        subtitle: verifyMessage,
        identity: id, hasIdentity: hasRealIdentity,
        signerNpub: signerNpub,
        trustLevel: rp['lv'] as String? ?? '',
        trustScore: (rp['sc'] as num?)?.toDouble() ?? 0,
        badgeCount: rp['bc'] as int? ?? 0,
        verifiedBadgeCount: rp['vc'] as int? ?? pf['vc'] as int? ?? 0,
        boundBadgeCount: rp['bb'] as int? ?? pf['bb'] as int? ?? 0,
        meetupCount: rp['mc'] as int? ?? 0,
        signerCount: rp['si'] as int? ?? 0,
        accountAgeDays: rp['ad'] as int? ?? 0,
        meetupList: (rp['ml'] as List?)?.cast<String>() ?? [],
        badgeProof: pf['bp'] as String? ?? '',
        proofTotalCount: pf['tc'] as int? ?? 0,
        proofVerifiedCount: pf['vc'] as int? ?? 0,
        platformProofsFromQR: pp,
      ),
    ));
  }

  void _showV2Result(Map<String, dynamic> data, {String? signerNpub}) {
    final id = data['id'] as Map<String, dynamic>? ?? {};
    final bool hasRealIdentity =
        (id['np'] != null && id['np'].toString().isNotEmpty) ||
        (id['tg'] != null && id['tg'].toString().isNotEmpty) ||
        (id['tw'] != null && id['tw'].toString().isNotEmpty);

    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => _VerificationResultScreen(
        isValid: true, version: 2,
        title: "VERIFIZIERT (v2)",
        subtitle: "Legacy-Signatur gültig — kein Badge-Proof",
        identity: id, hasIdentity: hasRealIdentity,
        signerNpub: signerNpub,
        badgeCount: data['c'] as int? ?? 0,
        meetupCount: data['m'] as int? ?? 0,
      ),
    ));
  }

  void _showV1Result(Map<String, dynamic> data) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => _VerificationResultScreen(
        isValid: true, version: 1,
        title: "VERIFIZIERT (v1)",
        subtitle: "Älteres Format — keine Identitätsbindung",
        identity: {'n': data['u'] ?? 'Anon'},
        hasIdentity: false,
        badgeCount: data['c'] as int? ?? 0,
        meetupCount: data['m'] as int? ?? 0,
      ),
    ));
  }

  void _showFailed({required String title, required String subtitle}) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (context) => _VerificationResultScreen(
        isValid: false, version: 0, title: title, subtitle: subtitle,
        identity: null, hasIdentity: false,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("REPUTATION PRÜFEN"),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined, color: cCyan),
            tooltip: 'QR aus Galerie laden',
            onPressed: _isScanned ? null : _pickFromGallery,
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),
        Positioned(
          bottom: 60, left: 24, right: 24,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isScanned ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text("QR AUS GALERIE LADEN"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Scanne einen Einundzwanzig\nReputation QR-Code",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// VERIFIZIERUNGS-ERGEBNIS SCREEN v2 — Multi-Layer
// ============================================================
// Jetzt ein StatefulWidget das nach dem Scan live
// die Trust-Layer über Nostr-Relays nachlädt:
//   - NIP-05 Verifikation
//   - Social Graph Analyse
//   - Zap-Aktivität
// Platform Proofs werden direkt aus dem QR gelesen.
// ============================================================
class _VerificationResultScreen extends StatefulWidget {
  final bool isValid;
  final int version;
  final String title;
  final String subtitle;
  final Map<String, dynamic>? identity;
  final bool hasIdentity;
  final String? signerNpub;
  final String trustLevel;
  final double trustScore;
  final int badgeCount;
  final int verifiedBadgeCount;
  final int boundBadgeCount;
  final int meetupCount;
  final int signerCount;
  final int accountAgeDays;
  final List<String> meetupList;
  final String badgeProof;
  final int proofTotalCount;
  final int proofVerifiedCount;
  final Map<String, dynamic> platformProofsFromQR; // NEU

  const _VerificationResultScreen({
    required this.isValid,
    required this.version,
    required this.title,
    required this.subtitle,
    required this.identity,
    required this.hasIdentity,
    this.signerNpub,
    this.trustLevel = '',
    this.trustScore = 0,
    this.badgeCount = 0,
    this.verifiedBadgeCount = 0,
    this.boundBadgeCount = 0,
    this.meetupCount = 0,
    this.signerCount = 0,
    this.accountAgeDays = 0,
    this.meetupList = const [],
    this.badgeProof = '',
    this.proofTotalCount = 0,
    this.proofVerifiedCount = 0,
    this.platformProofsFromQR = const {},
  });

  @override
  State<_VerificationResultScreen> createState() => _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<_VerificationResultScreen> {
  // Live-geladene Layer-Daten
  SocialAnalysis? _socialAnalysis;
  ZapStats? _zapStats;
  Nip05Result? _nip05Result;
  bool _layersLoading = false;
  String _layerStatus = '';

  @override
  void initState() {
    super.initState();
    // Wenn npub vorhanden, lade Trust-Layer im Hintergrund
    if (widget.isValid && widget.identity != null) {
      final npub = widget.identity!['np'] as String?;
      if (npub != null && npub.isNotEmpty) {
        _loadLayers(npub);
      }
    }
  }

  // =============================================
  // MULTI-LAYER LIVE-LADEN (parallel)
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

    await Future.wait([
      _loadSocial(pubkeyHex),
      _loadZaps(pubkeyHex),
      _loadNip05(pubkeyHex),
    ]);

    if (mounted) setState(() => _layersLoading = false);
  }

  Future<void> _loadSocial(String pubkeyHex) async {
    try {
      if (mounted) setState(() => _layerStatus = 'Analysiere Netzwerk...');
      final analysis = await SocialGraphService.analyze(pubkeyHex);
      if (mounted) setState(() => _socialAnalysis = analysis);
    } catch (_) {}
  }

  Future<void> _loadZaps(String pubkeyHex) async {
    try {
      if (mounted) setState(() => _layerStatus = 'Prüfe Lightning...');
      final stats = await ZapVerificationService.analyzeZapActivity(pubkeyHex, useCache: false);
      if (mounted) setState(() => _zapStats = stats);
    } catch (_) {}
  }

  Future<void> _loadNip05(String pubkeyHex) async {
    try {
      if (mounted) setState(() => _layerStatus = 'Prüfe NIP-05...');
      final relays = await RelayConfig.getActiveRelays();
      final nip05 = await Nip05Service.fetchNip05FromProfile(pubkeyHex, relays);
      if (nip05 != null && nip05.isNotEmpty) {
        final result = await Nip05Service.verify(nip05, pubkeyHex);
        if (mounted) setState(() => _nip05Result = result);
      }
    } catch (_) {}
  }

  // =============================================
  // Icons & Farben
  // =============================================
  static IconData _levelIcon(String level) {
    switch (level) {
      case 'VETERAN': return Icons.bolt;
      case 'ETABLIERT': return Icons.shield;
      case 'AKTIV': return Icons.local_fire_department;
      case 'STARTER': return Icons.eco;
      default: return Icons.fiber_new;
    }
  }

  Color get _levelColor {
    switch (widget.trustLevel) {
      case 'VETERAN': return Colors.amber;
      case 'ETABLIERT': return Colors.green;
      case 'AKTIV': return cCyan;
      case 'STARTER': return cOrange;
      default: return Colors.grey;
    }
  }

  // =============================================
  // UI
  // =============================================
  @override
  Widget build(BuildContext context) {
    final Color statusColor = !widget.isValid ? Colors.red : widget.hasIdentity ? Colors.green : Colors.orange;

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("ERGEBNIS")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ===== KOMPAKTER STATUS HEADER =====
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 2),
            ),
            child: Row(children: [
              Icon(widget.isValid ? Icons.verified : Icons.gpp_bad, color: statusColor, size: 36),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: TextStyle(color: statusColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              )),
              if (widget.version > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Text("v${widget.version}", style: const TextStyle(color: Colors.white30, fontSize: 10, fontFamily: 'monospace')),
                ),
            ]),
          ),

          // ===== TRUST SCORE (kompakt) =====
          if (widget.isValid && widget.version >= 3 && widget.trustLevel.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cCard, borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _levelColor.withOpacity(0.25)),
              ),
              child: Column(children: [
                // Kompakte Row: Icon + Level + Score
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _levelColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_levelIcon(widget.trustLevel), color: _levelColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.trustLevel, style: TextStyle(color: _levelColor, fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(
                        "${widget.badgeCount} Badges · ${widget.meetupCount} Meetups · ${widget.signerCount} Signer",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                      ),
                    ],
                  )),
                  Text(
                    widget.trustScore.toStringAsFixed(1),
                    style: TextStyle(color: _levelColor, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                  ),
                ]),

                // Mini-Stats
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _miniStat(Icons.military_tech, "${widget.badgeCount}", "Badges", cOrange),
                  _miniStat(Icons.location_on, "${widget.meetupCount}", "Meetups", cCyan),
                  _miniStat(Icons.people_outline, "${widget.signerCount}", "Signer", cPurple),
                  _miniStat(Icons.link, "${widget.boundBadgeCount}", "Gebunden", Colors.green),
                  _miniStat(Icons.calendar_today, "${widget.accountAgeDays}", "Tage", Colors.grey),
                ]),
              ]),
            ),
          ],

          // ===== BADGE-PROOF =====
          if (widget.isValid && widget.version >= 3 && widget.badgeProof.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildProofCard(),
          ],

          // ===== MULTI-LAYER TRUST (NEU!) =====
          if (widget.isValid && widget.version >= 3) ...[
            const SizedBox(height: 16),

            // Loading-Indikator
            if (_layersLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: cCyan)),
                  const SizedBox(width: 10),
                  Text(_layerStatus, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ]),
              ),

            // NIP-05
            _buildNip05Section(),

            // Humanity / Lightning
            _buildLightningSection(),

            // Platform Proofs (aus QR-Payload)
            if (widget.platformProofsFromQR.isNotEmpty)
              _buildPlatformProofsSection(),

            // Social Graph
            _buildSocialSection(),
          ],

          // ===== MEETUP-LISTE (gehashte Namen) =====
          if (widget.isValid && widget.meetupList.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMeetupList(),
          ],

          // ===== IDENTITÄT =====
          if (widget.isValid && widget.identity != null) ...[
            const SizedBox(height: 14),
            _buildIdentityCard(),
          ],

          // v1/v2 einfache Stats
          if (widget.isValid && widget.version < 3 && (widget.badgeCount > 0 || widget.meetupCount > 0)) ...[
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _statBox(Icons.military_tech, "${widget.badgeCount}", "Badges", cOrange)),
              const SizedBox(width: 12),
              Expanded(child: _statBox(Icons.location_on, "${widget.meetupCount}", "Meetups", cCyan)),
            ]),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black),
              child: const Text("ZURÜCK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }

  // =============================================
  // NIP-05 SECTION
  // =============================================
  Widget _buildNip05Section() {
    if (_nip05Result == null && !_layersLoading) return const SizedBox.shrink();
    if (_nip05Result == null) return const SizedBox.shrink();

    final valid = _nip05Result!.valid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _layerRow(
        icon: Icons.alternate_email,
        color: valid ? cCyan : Colors.red,
        title: valid ? _nip05Result!.nip05 : "NIP-05 ungültig",
        subtitle: valid ? _nip05Result!.domainLabel : _nip05Result!.nip05,
      ),
    );
  }

  // =============================================
  // LIGHTNING / HUMANITY SECTION
  // =============================================
  Widget _buildLightningSection() {
    if (_zapStats == null && !_layersLoading) return const SizedBox.shrink();
    if (_zapStats == null) return const SizedBox.shrink();

    final hasZaps = _zapStats!.totalCount > 0;
    final hasProof = _zapStats!.hasLightningProof;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasZaps ? Colors.amber.withOpacity(0.25) : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.bolt, color: hasZaps ? Colors.amber : Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text("LIGHTNING",
                style: TextStyle(color: hasZaps ? Colors.amber : Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 8),
            if (hasProof)
              _detailRow(Icons.verified_user, "Mensch verifiziert", "Lightning-Beweis aktiv", Colors.green),
            if (hasZaps) ...[
              _detailRow(Icons.arrow_upward, "${_zapStats!.sentCount} gesendet",
                "${_zapStats!.uniqueRecipientCount} verschiedene Empfänger",
                _zapStats!.sentCount > 5 ? Colors.green : Colors.grey),
              _detailRow(Icons.arrow_downward, "${_zapStats!.receivedCount} empfangen",
                "${_zapStats!.uniqueSenderCount} verschiedene Sender",
                _zapStats!.receivedCount > 0 ? Colors.green : Colors.grey),
              if (_zapStats!.activeMonths > 0)
                _detailRow(Icons.schedule, "${_zapStats!.activeMonths} Monate aktiv",
                  _zapStats!.activityLabel, Colors.amber),
            ] else
              _detailRow(Icons.info_outline, "Keine Zap-Aktivität", "Kein Lightning-Beweis gefunden", Colors.grey),
          ],
        ),
      ),
    );
  }

  // =============================================
  // PLATFORM PROOFS (aus QR-Payload)
  // =============================================
  Widget _buildPlatformProofsSection() {
    // QR-Format: pp: { "telegram": {"u": "satoshi", "s": "sig..."}, ... }
    final proofs = widget.platformProofsFromQR;
    if (proofs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.link, color: Colors.purple, size: 16),
              const SizedBox(width: 8),
              Text("VERKNÜPFTE PLATTFORMEN",
                style: TextStyle(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 8),
            ...proofs.entries.map((entry) {
              final platform = entry.key;
              final data = entry.value as Map<String, dynamic>? ?? {};
              final username = data['u'] as String? ?? data['username'] as String? ?? '';
              final hasSig = (data['s'] as String? ?? data['proof_sig'] as String? ?? '').isNotEmpty;

              return _detailRow(
                _platformIcon(platform),
                '${_platformLabel(platform)}${username.isNotEmpty ? ': @$username' : ''}',
                hasSig ? 'Signatur verifiziert' : 'Verknüpft',
                hasSig ? Colors.green : Colors.amber,
              );
            }),
          ],
        ),
      ),
    );
  }

  // =============================================
  // SOCIAL GRAPH
  // =============================================
  Widget _buildSocialSection() {
    if (_socialAnalysis == null && !_layersLoading) return const SizedBox.shrink();
    if (_socialAnalysis == null) return const SizedBox.shrink();

    final sa = _socialAnalysis!;
    final hasConnection = sa.isMutual || sa.iFollow || sa.followsMe || sa.commonContactCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasConnection ? cCyan.withOpacity(0.25) : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.hub, color: hasConnection ? cCyan : Colors.grey, size: 16),
              const SizedBox(width: 8),
              Text("SOZIALES NETZWERK",
                style: TextStyle(color: hasConnection ? cCyan : Colors.grey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ]),
            const SizedBox(height: 8),

            // Direkte Verbindung
            if (sa.isMutual)
              _detailRow(Icons.sync_alt, "Gegenseitiger Follow", "Direkte bidirektionale Verbindung", Colors.green)
            else if (sa.iFollow)
              _detailRow(Icons.person_add, "Du folgst", "Einseitige Verbindung", cCyan)
            else if (sa.followsMe)
              _detailRow(Icons.person, "Folgt dir", "Einseitige Verbindung", cCyan)
            else
              _detailRow(Icons.person_off, "Kein direkter Follow", "", Colors.grey),

            // Gemeinsame Kontakte
            _detailRow(Icons.group, "${sa.commonContactCount} gemeinsame Kontakte",
              sa.commonContactCount > 3 ? "Starke Netzwerk-Überlappung"
                  : sa.commonContactCount > 0 ? "Teilweise verbunden" : "Keine Überlappung",
              sa.commonContactCount > 0 ? Colors.green : Colors.grey),

            // Organisator-Endorsement
            if (sa.orgFollowerCount > 0)
              _detailRow(Icons.verified_user, "${sa.orgFollowerCount} Organisatoren folgen",
                "Endorsement von bekannten Admins", Colors.green),

            // Hop-Distanz
            if (sa.hops > 0)
              _detailRow(Icons.route, "${sa.hops} Hop${sa.hops > 1 ? 's' : ''} entfernt",
                sa.hops == 1 ? "Direkte Verbindung" : "Über gemeinsame Kontakte",
                sa.hops == 1 ? Colors.green : Colors.amber),
          ],
        ),
      ),
    );
  }

  // =============================================
  // MEETUP-LISTE
  // =============================================
  Widget _buildMeetupList() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.location_on, color: cCyan, size: 16), SizedBox(width: 8),
          Text("BESUCHTE MEETUPS", style: TextStyle(color: cCyan, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: widget.meetupList.map((m) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: cCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(m, style: const TextStyle(color: cCyan, fontSize: 11)),
          )
        ).toList()),
      ]),
    );
  }

  // =============================================
  // PROOF CARD
  // =============================================
  Widget _buildProofCard() {
    final allVerified = widget.proofVerifiedCount == widget.proofTotalCount && widget.proofTotalCount > 0;
    final Color c = allVerified ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(allVerified ? Icons.verified : Icons.shield_outlined, color: c, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "${widget.proofVerifiedCount} von ${widget.proofTotalCount} Badges kryptographisch verifiziert",
            style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            "Proof: ${widget.badgeProof.length > 16 ? '${widget.badgeProof.substring(0, 16)}...' : widget.badgeProof}",
            style: const TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'monospace'),
          ),
        ])),
      ]),
    );
  }

  // =============================================
  // IDENTITÄT
  // =============================================
  Widget _buildIdentityCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.hasIdentity ? cPurple.withOpacity(0.4) : Colors.orange.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.fingerprint, color: widget.hasIdentity ? cPurple : Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            widget.hasIdentity ? "IDENTITÄT" : "KEINE IDENTITÄT",
            style: TextStyle(color: widget.hasIdentity ? cPurple : Colors.orange, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
          ),
        ]),
        const SizedBox(height: 10),
        _idLine("Nickname", widget.identity!['n'] ?? 'Anon', Icons.person),
        if (widget.identity!['np'] != null && widget.identity!['np'].toString().isNotEmpty)
          _idLine("Nostr", widget.identity!['np'], Icons.key, mono: true),
        if (widget.identity!['tg'] != null && widget.identity!['tg'].toString().isNotEmpty)
          _idLine("Telegram", "@${widget.identity!['tg']}", Icons.send),
        if (widget.identity!['tw'] != null && widget.identity!['tw'].toString().isNotEmpty)
          _idLine("Twitter/X", "@${widget.identity!['tw']}", Icons.alternate_email),

        if (!widget.hasIdentity) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.orange.shade300, size: 14),
              const SizedBox(width: 8),
              const Expanded(child: Text("Keine verifizierbare Identität.",
                style: TextStyle(color: Colors.orange, fontSize: 11))),
            ]),
          ),
        ],
        if (widget.hasIdentity && widget.signerNpub != null && widget.signerNpub!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.lock_outline, color: Colors.green, size: 13),
            const SizedBox(width: 6),
            Text("Signiert: ${NostrService.shortenNpub(widget.signerNpub!)}",
              style: const TextStyle(color: Colors.green, fontSize: 10, fontFamily: 'monospace')),
          ]),
        ],
      ]),
    );
  }

  // =============================================
  // HELPERS
  // =============================================

  Widget _layerRow({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ],
        )),
      ]),
    );
  }

  Widget _detailRow(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w600)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ],
        )),
      ]),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 1),
      Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 9)),
    ]);
  }

  Widget _idLine(String label, String value, IconData icon, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: cOrange), const SizedBox(width: 8),
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11))),
        Expanded(child: Text(value, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: mono ? 'monospace' : null), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _statBox(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 11)),
      ]),
    );
  }

  /// Icon für bekannte Plattformen
  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'telegram': return Icons.send;
      case 'satoshikleinanzeigen': return Icons.shopping_cart;
      case 'robosats': return Icons.smart_toy;
      case 'nostr': return Icons.hub;
      default: return Icons.language;
    }
  }

  /// Anzeigename für bekannte Plattformen
  String _platformLabel(String platform) {
    switch (platform) {
      case 'telegram': return 'Telegram';
      case 'satoshikleinanzeigen': return 'Satoshi-Kleinanzeigen';
      case 'robosats': return 'RoboSats';
      case 'nostr': return 'Nostr';
      case 'other': return 'Andere';
      default: return platform;
    }
  }
}