// ============================================
// MEETUP VERIFICATION SCREEN — Nur Badge-Scanning
// ============================================
// Teilnehmer scannen hier NFC-Tags oder QR-Codes
// um Badges zu sammeln. Es gibt nur noch EINEN Tag-Typ: BADGE.
// ============================================

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../theme.dart';
import '../models/badge.dart';
import '../models/meetup.dart';
import '../models/user.dart'; 
import '../services/mempool.dart';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../services/rolling_qr_service.dart';

class MeetupVerificationScreen extends StatefulWidget {
  final Meetup meetup;

  const MeetupVerificationScreen({
    super.key, 
    required this.meetup,
  });

  @override
  State<MeetupVerificationScreen> createState() => _MeetupVerificationScreenState();
}

class _MeetupVerificationScreenState extends State<MeetupVerificationScreen> with SingleTickerProviderStateMixin {
  bool _success = false;
  String _statusText = "Bereit zum Scannen";

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =============================================
  // NFC TAG LESEN
  // =============================================
  void _startNfcRead() async {
    setState(() => _statusText = "Warte auf NFC Tag...");

    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      _simulateHandshake();
      return;
    }

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              await NfcManager.instance.stopSession();
              return;
            }

            final ndefMessage = await ndef.read();
            if (ndefMessage == null || ndefMessage.records.isEmpty) {
              await NfcManager.instance.stopSession();
              return;
            }

            final payload = ndefMessage.records.first.payload;
            if (payload.isEmpty) {
              await NfcManager.instance.stopSession();
              return;
            }

            final languageCodeLength = payload.first & 0x3F;
            final textStart = 1 + languageCodeLength;
            
            if (payload.length <= textStart) {
              await NfcManager.instance.stopSession();
              return;
            }

            final jsonString = utf8.decode(payload.sublist(textStart));
            
            try {
              Map<String, dynamic> tagData = json.decode(jsonString) as Map<String, dynamic>;
              await NfcManager.instance.stopSession();

              // Compact-Format normalisieren (falls nötig)
              tagData = BadgeSecurity.normalize(tagData);

              // Signatur prüfen
              final result = BadgeSecurity.verify(tagData);
              if (!result.isValid) {
                setState(() {
                  _statusText = "❌ FÄLSCHUNG ERKANNT!\nDieser Tag hat keine gültige Signatur.";
                  _success = false;
                });
                return;
              }
              
              // Bei v2: Admin-Info merken
              if (result.version == 2 && result.adminNpub.isNotEmpty) {
                tagData['_verified_by'] = NostrService.shortenNpub(result.adminNpub);
              }

              _processFoundTagData(tagData: tagData);
            } catch (e) {
              await NfcManager.instance.stopSession();
              setState(() => _statusText = "❌ Ungültiger Tag: $e");
            }
            
          } catch (e) {
            print("[ERROR] Fehler beim Tag-Lesen: $e");
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      setState(() => _statusText = "❌ NFC Start-Fehler: $e");
    }
  }

  // =============================================
  // SIMULATOR (wenn kein NFC verfügbar)
  // =============================================
  void _simulateHandshake() async {
    setState(() => _statusText = "Lese Tag... (SIMULATOR)");
    await Future.delayed(const Duration(seconds: 1));
    
    final timestamp = DateTime.now().toIso8601String();
    final int blockHeight = 850000;
    final meetupId = widget.meetup.id;

    Map<String, dynamic> tagData;
    final hasNostrKey = await NostrService.hasKey();

    if (hasNostrKey) {
      try {
        tagData = await BadgeSecurity.signWithNostr(
          meetupId: meetupId,
          timestamp: timestamp,
          blockHeight: blockHeight,
          meetupName: widget.meetup.city,
          meetupCountry: widget.meetup.country,
          tagType: 'BADGE',
        );
      } catch (e) {
        final sig = BadgeSecurity.signLegacy(meetupId, timestamp, blockHeight);
        tagData = {
          'type': 'BADGE',
          'timestamp': timestamp,
          'block_height': blockHeight,
          'meetup_id': meetupId,
          'meetup_name': widget.meetup.city,
          'meetup_country': widget.meetup.country,
          'sig': sig,
        };
      }
    } else {
      final sig = BadgeSecurity.signLegacy(meetupId, timestamp, blockHeight);
      tagData = {
        'type': 'BADGE',
        'timestamp': timestamp,
        'block_height': blockHeight,
        'meetup_id': meetupId,
        'meetup_name': widget.meetup.city,
        'meetup_country': widget.meetup.country,
        'sig': sig,
      };
    }

    tagData = BadgeSecurity.normalize(tagData);
    _processFoundTagData(tagData: tagData);
  }

  // =============================================
  // QR-CODE SCANNER
  // =============================================
  void _startQRScan() async {
    setState(() => _statusText = "Kamera öffnet...");

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _QRScannerScreen()),
    );

    if (result == null || !mounted) {
      setState(() => _statusText = "Scan abgebrochen");
      return;
    }

    try {
      Map<String, dynamic> tagData = json.decode(result);
      tagData = BadgeSecurity.normalize(tagData);

      // Signatur prüfen
      final verifyResult = BadgeSecurity.verify(tagData);
      if (!verifyResult.isValid) {
        setState(() {
          _statusText = "❌ FÄLSCHUNG ERKANNT!\nDieser QR-Code hat keine gültige Signatur.";
          _success = false;
        });
        return;
      }

      // Rolling Nonce prüfen
      if (tagData['qr_nonce'] != null) {
        final nonceResult = await RollingQRService.validateNonce(tagData);
        if (!nonceResult.isValid) {
          setState(() {
            _statusText = "❌ QR-CODE ABGELAUFEN!\n${nonceResult.message}\n\nBitte den aktuellen Code scannen.";
            _success = false;
          });
          return;
        }
      }

      if (verifyResult.version == 2 && verifyResult.adminNpub.isNotEmpty) {
        tagData['_verified_by'] = NostrService.shortenNpub(verifyResult.adminNpub);
      }

      _processFoundTagData(tagData: tagData);
    } catch (e) {
      setState(() => _statusText = "❌ Ungültiger QR-Code\n$e");
    }
  }

  // =============================================
  // TAG-DATEN VERARBEITEN → BADGE SPEICHERN
  // =============================================
  void _processFoundTagData({Map<String, dynamic>? tagData}) async {
    if (!mounted) return;
    
    if (tagData == null) {
      setState(() => _statusText = "❌ Kein gültiger Tag erkannt");
      return;
    }

    String tagType = tagData['type'] ?? '';

    // Nur BADGE-Tags akzeptieren
    if (tagType != 'BADGE' && tagType != 'B') {
      setState(() => _statusText = "❌ Unbekannter Tag-Typ: $tagType");
      return;
    }

    int currentBlockHeight = 0;
    if (tagData['block_height'] != null) {
      currentBlockHeight = tagData['block_height'];
    } else {
      try { currentBlockHeight = await MempoolService.getBlockHeight(); } catch (e) {}
    }

    String meetupName = tagData['meetup_name'] ?? 'Unbekanntes Meetup';
    String meetupCountry = tagData['meetup_country'] ?? '';
    String meetupId = tagData['meetup_id'] ?? DateTime.now().toString();
    
    // Duplikat-Check: Gleiches Meetup am gleichen Tag?
    bool alreadyCollected = myBadges.any((b) => 
      b.meetupName.contains(meetupName) && 
      b.date.year == DateTime.now().year &&
      b.date.month == DateTime.now().month &&
      b.date.day == DateTime.now().day
    );

    String msg;

    if (!alreadyCollected) {
      // Signer-Info extrahieren
      final signerNpub = tagData['admin_npub'] as String? ?? '';
      final delivery = tagData['delivery'] as String? ?? 'nfc';
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final meetupEventId = '${meetupName.toLowerCase().replaceAll(' ', '-')}-$dateStr';

      // Kryptographischen Beweis extrahieren
      final sig = tagData['sig'] as String? ?? '';
      final sigId = tagData['sig_id'] as String? ?? '';
      final adminPubkey = tagData['admin_pubkey'] as String? ?? '';
      final sigVersion = (tagData['v'] as int?) ?? (sig.length == 128 ? 2 : 1);
      
      // Originalen signierten Content rekonstruieren (für Re-Verifikation)
      final contentData = Map<String, dynamic>.from(tagData);
      contentData.remove('sig');
      contentData.remove('sig_id');
      contentData.remove('admin_pubkey');
      contentData.remove('_verified_by');
      final sigContent = jsonEncode(contentData);

      myBadges.add(MeetupBadge(
        id: meetupId, 
        meetupName: meetupCountry.isNotEmpty ? "$meetupName, $meetupCountry" : meetupName, 
        date: DateTime.now(), 
        iconPath: "assets/badge_icon.png",
        blockHeight: currentBlockHeight,
        signerNpub: signerNpub,
        meetupEventId: meetupEventId,
        delivery: delivery,
        // Kryptographischer Beweis
        sig: sig,
        sigId: sigId,
        adminPubkey: adminPubkey,
        sigVersion: sigVersion,
        sigContent: sigContent,
      ));
      
      await MeetupBadge.saveBadges(myBadges);
      
      msg = "🎉 BADGE GESAMMELT!\n\n📍 $meetupName";
      if (currentBlockHeight > 0) msg += "\n⛓️ Block: $currentBlockHeight";
      if (tagData['_verified_by'] != null) msg += "\n🔐 Signiert von: ${tagData['_verified_by']}";
    } else {
      msg = "✅ Badge bereits gesammelt\n\n📍 $meetupName";
    }

    setState(() {
      _success = true;
      _statusText = msg;
    });

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pop(context, true); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BADGE SCANNEN")),
      body: Center(
        child: _success 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              Text("ERFOLG!", style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  _statusText, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16, height: 1.6),
                ),
              ),
            ],
          )
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cOrange, width: 4),
                  boxShadow: [BoxShadow(color: cOrange.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)],
                ),
                child: const Center(child: Icon(Icons.nfc, size: 80, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "BADGE SCANNEN",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            
            const SizedBox(height: 40),
            
            // NFC Button
            SizedBox(
              width: 250, height: 50,
              child: ElevatedButton.icon(
                onPressed: _startNfcRead,
                icon: const Icon(Icons.nfc, color: Colors.white, size: 20),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                label: const Text("NFC TAG SCANNEN", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            
            // QR Button
            SizedBox(
              width: 250, height: 50,
              child: ElevatedButton.icon(
                onPressed: _startQRScan,
                icon: const Icon(Icons.qr_code_scanner, color: cOrange, size: 20),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  side: const BorderSide(color: cOrange, width: 1),
                ),
                label: const Text("QR-CODE SCANNEN", style: TextStyle(color: cOrange)),
              ),
            ),
            
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// QR SCANNER SCREEN
// ============================================
class _QRScannerScreen extends StatefulWidget {
  const _QRScannerScreen();

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("QR-CODE SCANNEN"), backgroundColor: cOrange),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.contains('meetup_id')) {
                  _hasScanned = true;
                  Navigator.pop(context, rawValue);
                  return;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: cOrange, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Column(children: const [
              Text("Halte die Kamera auf den\nRolling QR-Code des Meetups",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text("Der Code ändert sich alle 30 Sekunden",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}