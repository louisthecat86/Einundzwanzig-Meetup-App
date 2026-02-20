// ============================================
// MEETUP VERIFICATION — Badge Scanner
// ============================================
// Scannt NFC-Tags und Rolling-QR-Codes.
// Unterstützt sowohl Kompakt-Format (v2c) als auch Legacy.
//
// Ablauf:
//   1. NFC oder QR lesen
//   2. Format erkennen (kompakt vs. legacy)
//   3. BadgeSecurity.verify() → Schnorr-Check + Ablauf
//   4. AdminRegistry.checkAdminByPubkey() → Signer bekannt?
//   5. Normalisieren (kompakt → volle Feldnamen)
//   6. Badge MIT kryptographischem Beweis speichern
//
// SICHERHEIT:
//   - Signatur allein reicht NICHT — der Signer-Pubkey
//     wird gegen die Admin Registry geprüft.
//   - Unbekannte Signer werden deutlich als ✗ markiert.
//   - Legacy v1 Badges werden als unsicher gekennzeichnet.
// ============================================

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';    // Ndef (cross-platform)
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import '../models/badge.dart';
import '../models/meetup.dart';
import '../models/user.dart';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../services/mempool.dart';
import '../services/rolling_qr_service.dart';
import '../services/admin_registry.dart';

class MeetupVerificationScreen extends StatefulWidget {
  final Meetup meetup;
  const MeetupVerificationScreen({super.key, required this.meetup});

  @override
  State<MeetupVerificationScreen> createState() => _MeetupVerificationScreenState();
}

class _MeetupVerificationScreenState extends State<MeetupVerificationScreen> with SingleTickerProviderStateMixin {
  bool _success = false;
  bool _isUnknownSigner = false; // Flag für unbekannten Signer
  String _statusText = "Bereit zum Scannen";

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =============================================
  // NFC LESEN
  // =============================================

  void _startNfcRead() async {
    setState(() => _statusText = "Warte auf NFC Tag...");

    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      _simulateScan();
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
              setState(() => _statusText = "✗ Kein NDEF Tag");
              return;
            }

            final ndefMessage = await ndef.read();
            if (ndefMessage == null || ndefMessage.records.isEmpty) {
              await NfcManager.instance.stopSession();
              setState(() => _statusText = "✗ Tag ist leer");
              return;
            }

            final payload = ndefMessage.records.first.payload;
            if (payload.isEmpty) {
              await NfcManager.instance.stopSession();
              setState(() => _statusText = "✗ Payload leer");
              return;
            }

            final languageCodeLength = payload.first & 0x3F;
            final textStart = 1 + languageCodeLength;
            if (payload.length <= textStart) {
              await NfcManager.instance.stopSession();
              setState(() => _statusText = "✗ Ungültiges Format");
              return;
            }

            final jsonString = utf8.decode(payload.sublist(textStart));

            try {
              final Map<String, dynamic> tagData = json.decode(jsonString) as Map<String, dynamic>;
              await NfcManager.instance.stopSession();

              // SICHERHEITS-CHECK (Kompakt + Legacy)
              final result = BadgeSecurity.verify(tagData);
              if (!result.isValid) {
                setState(() {
                  _statusText = "✗ ${result.message}";
                  _success = false;
                });
                return;
              }

              // Admin-Info für Anzeige
              if (result.version >= 2 && result.adminNpub.isNotEmpty) {
                tagData['_verified_by'] = NostrService.shortenNpub(result.adminNpub);
              }

              tagData['delivery'] = 'nfc';
              _processFoundTagData(tagData: tagData, verifyResult: result);

            } catch (e) {
              await NfcManager.instance.stopSession();
              setState(() => _statusText = "✗ Ungültiger Tag: $e");
            }
          } catch (e) {
            await NfcManager.instance.stopSession();
            setState(() => _statusText = "✗ Lesefehler: $e");
          }
        },
      );
    } catch (e) {
      setState(() => _statusText = "✗ NFC Fehler: $e");
    }
  }

  // =============================================
  // QR LESEN (Rolling QR)
  // =============================================

  void _startQRScan() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const _QRScannerScreen()),
    );

    if (result != null) {
      // Nonce-Check für Rolling QR
      if (result.containsKey('n') || result.containsKey('qr_nonce')) {
        final nonceResult = RollingQRService.validateNonce(result);
        if (!nonceResult.isValid) {
          setState(() {
            _statusText = "✗ QR-Code abgelaufen!\n${nonceResult.message}\n\nBitte direkt am Bildschirm des Organisators scannen.";
            _success = false;
          });
          return;
        }
      }

      // Sicherheits-Check
      // WICHTIG: Rolling-QR-Felder (n, ts, d) werden vor dem Signatur-Check
      // entfernt, da sie NACH dem Signieren angehängt werden und sonst
      // den Hash verfälschen würden ("Invalid event").
      final dataToVerify = Map<String, dynamic>.from(result);
      dataToVerify.remove('n');
      dataToVerify.remove('ts');
      dataToVerify.remove('d');
      dataToVerify.remove('qr_nonce');
      dataToVerify.remove('qr_time_step');

      final verifyResult = BadgeSecurity.verify(dataToVerify);
      if (!verifyResult.isValid) {
        setState(() {
          _statusText = "✗ ${verifyResult.message}";
          _success = false;
        });
        return;
      }

      if (verifyResult.version >= 2 && verifyResult.adminNpub.isNotEmpty) {
        result['_verified_by'] = NostrService.shortenNpub(verifyResult.adminNpub);
      }

      if (!result.containsKey('delivery')) result['delivery'] = 'rolling_qr';
      _processFoundTagData(tagData: result, verifyResult: verifyResult);
    }
  }

  // =============================================
  // TAG VERARBEITEN → Badge speichern
  // =============================================

  void _processFoundTagData({
    required Map<String, dynamic> tagData,
    VerifyResult? verifyResult,
  }) async {
    if (!mounted) return;

    // Kompakt-Format normalisieren
    final normalized = BadgeSecurity.normalize(tagData);

    final String meetupName = normalized['meetup_name'] ?? 'Unbekanntes Meetup';
    final String meetupCountry = normalized['meetup_country'] ?? '';
    final String meetupId = normalized['meetup_id'] ?? DateTime.now().toString();

    // Block Height
    int currentBlockHeight = normalized['block_height'] ?? 0;
    if (currentBlockHeight == 0) {
      try { currentBlockHeight = await MempoolService.getBlockHeight(); } catch (_) {}
    }

    // Duplikat-Check (ein Badge pro Meetup pro Tag)
    final fullName = meetupCountry.isNotEmpty ? "$meetupName, $meetupCountry" : meetupName;
    bool alreadyCollected = myBadges.any((b) =>
      b.meetupName == fullName &&
      b.date.year == DateTime.now().year &&
      b.date.month == DateTime.now().month &&
      b.date.day == DateTime.now().day
    );

    String msg;

    if (!alreadyCollected) {
      // Signer-Info
      final signerNpub = normalized['admin_npub'] as String? ?? '';
      final delivery = normalized['delivery'] as String? ?? tagData['delivery'] as String? ?? 'nfc';
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final meetupEventId = '${meetupName.toLowerCase().replaceAll(' ', '-')}-$dateStr';

      // Kryptographischen Beweis extrahieren
      final sig = normalized['sig'] as String? ?? tagData['s'] as String? ?? '';
      final sigId = normalized['sig_id'] as String? ?? '';
      final adminPubkey = normalized['admin_pubkey'] as String? ?? tagData['p'] as String? ?? '';
      final sigVersion = sig.length == 128 ? 2 : (sig.isNotEmpty ? 1 : 0);

      // =============================================
      // ADMIN-REGISTRY CHECK — Ist der Signer bekannt?
      // =============================================
      bool isKnownAdmin = false;
      String adminCheckInfo = '';

      if (verifyResult != null && verifyResult.version >= 2 && adminPubkey.isNotEmpty) {
        try {
          final adminResult = await AdminRegistry.checkAdminByPubkey(adminPubkey);
          isKnownAdmin = adminResult.isAdmin;
          if (isKnownAdmin) {
            final adminName = adminResult.name ?? adminResult.meetup ?? 'Verifizierter Admin';
            adminCheckInfo = '✓ Bekannter Organisator: $adminName';
          } else {
            adminCheckInfo = '✗ UNBEKANNTER SIGNER!\nDieser Pubkey ist nicht in der Admin-Registry.';
          }
        } catch (e) {
          // Offline: Cache-Miss → Warnung anzeigen
          adminCheckInfo = '! Admin-Status konnte nicht geprüft werden (offline?)';
        }
      } else if (verifyResult != null && verifyResult.version == 1) {
        // Legacy v1: Shared Secret, per Definition nicht vertrauenswürdig
        adminCheckInfo = '! Legacy-Badge (v1) — Signer nicht prüfbar';
      }

      // Originalen signierten Content für Re-Verifikation
      final contentData = Map<String, dynamic>.from(tagData);
      contentData.remove('_verified_by');
      final sigContent = jsonEncode(contentData);

      myBadges.add(MeetupBadge(
        id: meetupId,
        meetupName: fullName,
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

      // --- NEUES, CLEANES STRING FORMAT ---
      msg = "BADGE GESAMMELT!\n\n";
      msg += "Ort: $fullName\n";
      if (currentBlockHeight > 0) msg += "Block: $currentBlockHeight\n";
      if (tagData['_verified_by'] != null) msg += "Signiert von: ${tagData['_verified_by']}\n";
      if (sigVersion == 2) msg += "Beweis: Schnorr (BIP-340)";

      // Admin-Registry Ergebnis anzeigen
      if (adminCheckInfo.isNotEmpty) {
        msg += "\n\n$adminCheckInfo";
      }

      // Ablauf-Info anzeigen
      final expiryStr = BadgeSecurity.expiryInfo(tagData);
      if (expiryStr != 'Kein Ablauf') msg += "\n\nTag-Ablauf: $expiryStr";

      // Flag setzen für UI (Farbe des Icons)
      if (!isKnownAdmin && verifyResult != null && verifyResult.version >= 2 && adminPubkey.isNotEmpty) {
        _isUnknownSigner = true;
      }

    } else {
      msg = "Badge bereits gesammelt!\n\nOrt: $fullName";
    }

    setState(() {
      _success = true;
      _statusText = msg;
    });

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) Navigator.pop(context, true);
  }

  // =============================================
  // SIMULATION (kein NFC verfügbar)
  // =============================================

  void _simulateScan() async {
    setState(() => _statusText = "Simuliere Badge-Scan...");
    await Future.delayed(const Duration(seconds: 1));

    final simData = {
      'v': 2,
      't': 'B',
      'm': 'sim-meetup-de',
      'b': 850000, // Echte Blockzahl für Simulation eingefügt
      'x': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 21600,
      'delivery': 'nfc',
    };
    _processFoundTagData(tagData: simData);
  }

  // =============================================
  // UI
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("BADGE SCANNEN")),
      body: Center(
        child: _success
            ? Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon bleibt mittig und prominent
                    Icon(
                      _isUnknownSigner ? Icons.warning_amber_rounded : Icons.check_circle,
                      size: 100,
                      color: _isUnknownSigner ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(height: 30),
                    
                    // --- NEUER INFO-BLOCK (Linksbündig, im Card-Design) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isUnknownSigner 
                              ? Colors.orange.withOpacity(0.5) 
                              : Colors.green.withOpacity(0.5)
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isUnknownSigner 
                                ? Colors.orange.withOpacity(0.1) 
                                : Colors.green.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                      ),
                      child: Text(
                        _statusText, 
                        textAlign: TextAlign.left, // Linksbündig!
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w600, 
                          fontSize: 15, 
                          height: 1.6, // Zeilenabstand für bessere Lesbarkeit
                          letterSpacing: 0.3,
                        )
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animierter Kreis
                  ScaleTransition(
                    scale: _animation,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cOrange, width: 4),
                        boxShadow: [BoxShadow(color: cOrange.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: const Center(child: Icon(Icons.nfc, size: 80, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text("BADGE SCANNEN",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text("Scanne den NFC-Tag oder QR-Code\ndes Meetup-Organisators.",
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
                  ),
                  const SizedBox(height: 40),

                  // NFC Button
                  SizedBox(
                    width: 250, height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _startNfcRead,
                      icon: const Icon(Icons.nfc, color: Colors.white),
                      label: const Text("NFC TAG SCANNEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: cOrange),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR Button
                  SizedBox(
                    width: 250, height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _startQRScan,
                      icon: const Icon(Icons.qr_code_scanner, color: cCyan),
                      label: const Text("QR-CODE SCANNEN", style: TextStyle(color: cCyan, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: cCyan, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(_statusText, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================
// QR SCANNER HELPER SCREEN
// ============================================
class _QRScannerScreen extends StatefulWidget {
  const _QRScannerScreen();

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        try {
          final data = json.decode(code) as Map<String, dynamic>;
          // Ist es ein Meetup-Badge-Tag? (Kompakt oder Legacy)
          if (data.containsKey('t') || data.containsKey('type')) {
            setState(() => _isScanned = true);
            Navigator.pop(context, data);
            return;
          }
        } catch (_) {
          // Kein JSON — ignorieren
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("QR SCANNEN")),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        Positioned(
          bottom: 60, left: 40, right: 40,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
            child: const Text("Scanne den QR-Code\ndes Meetup-Organisators",
              style: TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
          ),
        ),
      ]),
    );
  }
}