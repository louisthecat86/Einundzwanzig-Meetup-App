import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // WICHTIG: Für QR Scan
import '../models/meetup.dart';
import '../models/badge.dart';
import '../models/user.dart';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../services/rolling_qr_service.dart';

class MeetupVerificationScreen extends StatefulWidget {
  final Meetup? meetup; // Kann null sein, wenn vom Dashboard gescannt wird
  final bool initialChefMode;

  const MeetupVerificationScreen({
    super.key,
    required this.meetup,
    this.initialChefMode = false,
  });

  @override
  State<MeetupVerificationScreen> createState() => _MeetupVerificationScreenState();
}

class _MeetupVerificationScreenState extends State<MeetupVerificationScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isSuccess = false;
  bool _isChefMode = false;
  String _statusText = "Bereit zum Scannen";
  
  // Animation
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _isChefMode = widget.initialChefMode;
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // NFC direkt starten
    _startNfcScan();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    _animController.dispose();
    super.dispose();
  }

  void _startNfcScan() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (mounted) setState(() => _statusText = "NFC nicht verfügbar (nutze QR)");
      return;
    }

    if (mounted) setState(() => _isScanning = true);

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // 1. Daten auslesen
          final ndef = Ndef.from(tag);
          if (ndef == null || ndef.cachedMessage == null) return;
          
          final record = ndef.cachedMessage!.records.first;
          final payload = utf8.decode(record.payload);
          
          // 2. Format bereinigen ("en" Prefix entfernen bei Text Records)
          final cleanPayload = payload.substring(3); 
          final data = jsonDecode(cleanPayload);

          // 3. Verarbeiten
          _processFoundTagData(data);
          
        } catch (e) {
          _handleError("Fehler beim Lesen: $e");
        } finally {
           // Session offen lassen für weitere Scans im Chef Modus, sonst schließen
           if (!_isChefMode) NfcManager.instance.stopSession();
        }
      },
    );
  }

  void _scanQrCode() async {
    // Öffnet den Scanner Screen (Code siehe ganz unten)
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const _QRScannerScreen())
    );

    if (result != null) {
      try {
        final data = jsonDecode(result);
        if (data['type'] == 'BADGE') {
          // Rolling QR Validierung
          if (RollingQrService().validatePayload(data)) {
            _processFoundTagData(data); 
          } else {
            _handleError("QR-Code abgelaufen! Bitte neu scannen.");
          }
        } else {
          _handleError("Falscher QR-Code Typ");
        }
      } catch (e) {
        _handleError("Ungültiger QR-Code");
      }
    }
  }

  void _processFoundTagData(Map<String, dynamic> data) async {
    // Signatur prüfen (v1 und v2)
    final verifyResult = await BadgeSecurity().verify(data);
    
    if (!verifyResult.isValid) {
      _handleError("Ungültige Signatur!");
      return;
    }

    // Badge erstellen
    final newBadge = MeetupBadge(
      meetupId: data['meetup_id'],
      meetupName: data['meetup_name'],
      meetupCountry: data['meetup_country'],
      timestamp: data['timestamp'],
      blockHeight: data['block_height'],
      signature: data['sig'],
      signerNpub: verifyResult.adminNpub, // Wer hat signiert?
      meetupEventId: null, // Wird ggf. später über Nostr geholt
      delivery: data['delivery'] ?? 'nfc', // 'nfc' oder 'rolling_qr'
    );

    // Speichern
    final user = await UserProfile.load();
    if (user != null) {
      // Duplikat-Check
      bool exists = user.badges.any((b) => b.signature == newBadge.signature);
      if (!exists) {
        user.badges.add(newBadge);
        await user.save();
        
        // NEU: Anwesenheit publishen (Co-Attestor)
        NostrService().publishAttendance(data['meetup_id'], data['meetup_name']); // ID als Event-Marker nutzen
        
        if (mounted) {
          setState(() {
            _isSuccess = true;
            _statusText = "Stempel erfolgreich eingesammelt!";
          });
        }
      } else {
        _handleError("Diesen Stempel hast du schon!");
      }
    }
  }

  void _handleError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_isChefMode ? "Admin Modus" : "Stempel sammeln"), 
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSuccess) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              Text(_statusText, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text("ZURÜCK", style: TextStyle(color: Colors.black)),
              )
            ] else ...[
              // Animation
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange.withOpacity(1.0 - _animController.value),
                        width: 10 * _animController.value,
                      ),
                    ),
                    child: const Icon(Icons.wifi_tethering, size: 60, color: Colors.orange),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text("Halte dein Handy an den NFC-Tag", style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 8),
              const Text("ODER", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // QR SCAN BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.black),
                    label: const Text("QR-CODE SCANNEN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: _scanQrCode,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// --- DER INTERNE QR SCANNER SCREEN (VOLLSTÄNDIG) ---

class _QRScannerScreen extends StatefulWidget {
  const _QRScannerScreen();

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  bool _hasScanned = false; // Verhindert mehrfaches Scannen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Code scannen"),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MobileScanner(
        // Hier wird der Scan erkannt
        onDetect: (capture) {
          if (_hasScanned) return;
          
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              setState(() => _hasScanned = true);
              Navigator.pop(context, barcode.rawValue);
              break; 
            }
          }
        },
        // Overlay (optional, sieht aber besser aus)
        overlayBuilder: (context, constraints) {
          return Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.orange,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          );
        },
      ),
    );
  }
}