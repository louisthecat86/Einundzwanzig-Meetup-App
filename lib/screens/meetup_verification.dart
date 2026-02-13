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
import 'nfc_writer.dart'; 

class MeetupVerificationScreen extends StatefulWidget {
  final Meetup meetup;
  final bool initialChefMode;
  final bool verifyOnlyMode;

  const MeetupVerificationScreen({
    super.key, 
    required this.meetup,
    this.initialChefMode = false,
    this.verifyOnlyMode = false,
  });

  @override
  State<MeetupVerificationScreen> createState() => _MeetupVerificationScreenState();
}

class _MeetupVerificationScreenState extends State<MeetupVerificationScreen> with SingleTickerProviderStateMixin {
  late bool _isChefMode;
  bool _success = false;
  String _statusText = "Bereit zum Scannen";
  bool _writeModeBadge = true;

  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isChefMode = widget.initialChefMode;
    if (_isChefMode) {
      _statusText = "ADMIN MODUS AKTIV";
    }
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startNfcRead(String type) async {
    setState(() {
      _statusText = "Warte auf NFC Tag...";
    });

    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      _simulateHandshake(type);
      return;
    }

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
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
              final Map<String, dynamic> tagData = json.decode(jsonString) as Map<String, dynamic>;
              await NfcManager.instance.stopSession();

              // --- SICHERHEITS-CHECK (v1 + v2) ---
              final result = BadgeSecurity.verify(tagData);
              if (!result.isValid) {
                setState(() {
                  _statusText = "❌ FÄLSCHUNG ERKANNT!\nDieser Tag hat keine gültige Signatur.";
                  _success = false;
                });
                return; // Abbruch!
              }
              
              // Bei v2: Admin-Info merken für Anzeige
              if (result.version == 2 && result.adminNpub.isNotEmpty) {
                tagData['_verified_by'] = NostrService.shortenNpub(result.adminNpub);
              }
              // ------------------------------

              _processFoundTagData(tagData: tagData);
            } catch (e) {
              await NfcManager.instance.stopSession();
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

  void _simulateHandshake(String type) async {
    setState(() {
      _statusText = "Lese Tag... (SIMULATOR)";
    });
    await Future.delayed(const Duration(seconds: 1));
    
    // Wir müssen für den Simulator gültige Daten erzeugen
    final timestamp = DateTime.now().toIso8601String();
    final int blockHeight = 850000; // Dummy Block
    final meetupId = widget.meetup.id;

    Map<String, dynamic> tagData;
    final hasNostrKey = await NostrService.hasKey();

    if (hasNostrKey) {
      // v2: Nostr-Signierung im Simulator
      try {
        tagData = await BadgeSecurity.signWithNostr(
          meetupId: meetupId,
          timestamp: timestamp,
          blockHeight: blockHeight,
          meetupName: widget.meetup.city,
          meetupCountry: widget.meetup.country,
          tagType: type,
        );
      } catch (e) {
        // Fallback
        final sig = BadgeSecurity.signLegacy(meetupId, timestamp, blockHeight);
        tagData = {
          'timestamp': timestamp,
          'block_height': blockHeight,
          'meetup_id': meetupId,
          'sig': sig,
        };
      }
    } else {
      // v1: Legacy
      final sig = BadgeSecurity.signLegacy(meetupId, timestamp, blockHeight);
      tagData = {
        'timestamp': timestamp,
        'block_height': blockHeight,
        'meetup_id': meetupId,
        'sig': sig,
      };
    }
    
    if (type == "BADGE") {
      tagData['type'] = 'BADGE';
      // meetup_name/country kommen schon von signWithNostr bei v2
      if (!tagData.containsKey('meetup_name')) {
        tagData['meetup_name'] = widget.meetup.city;
        tagData['meetup_country'] = widget.meetup.country;
        tagData['meetup_date'] = timestamp;
      }
    } else if (type == "VERIFY") {
      tagData['type'] = 'VERIFY';
    }

    _processFoundTagData(tagData: tagData);
  }

  // --- QR-CODE SCANNER (Alternative zu NFC) ---
  void _startQRScan(String type) async {
    setState(() => _statusText = "Kamera öffnet...");

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _QRScannerScreen(expectedType: type),
      ),
    );

    if (result == null || !mounted) {
      setState(() => _statusText = "Scan abgebrochen");
      return;
    }

    try {
      final Map<String, dynamic> tagData = json.decode(result);

      // Signatur prüfen (gleich wie bei NFC)
      final verifyResult = BadgeSecurity.verify(tagData);
      if (!verifyResult.isValid) {
        setState(() {
          _statusText = "❌ FÄLSCHUNG ERKANNT!\nDieser QR-Code hat keine gültige Signatur.";
          _success = false;
        });
        return;
      }

      // Rolling Nonce prüfen (Frische-Check)
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

      // v2: Admin-Info merken
      if (verifyResult.version == 2 && verifyResult.adminNpub.isNotEmpty) {
        tagData['_verified_by'] = NostrService.shortenNpub(verifyResult.adminNpub);
      }

      _processFoundTagData(tagData: tagData);
    } catch (e) {
      setState(() {
        _statusText = "❌ Ungültiger QR-Code\n$e";
      });
    }
  }

  void _processFoundTagData({Map<String, dynamic>? tagData}) async {
    if (!mounted) return;
    
    if (tagData == null) {
      setState(() {
        _statusText = "❌ Kein gültiger Tag erkannt";
      });
      return;
    }

    final user = await UserProfile.load();
    String msg = "";
    String tagType = tagData['type'] ?? '';

    // Validierung des Modus
    if (widget.verifyOnlyMode && tagType == 'BADGE') {
      setState(() {
        _statusText = "❌ Falscher Tag!\nDas ist ein Badge-Tag.\nBitte den Verifizierungs-Tag des Admins scannen.";
      });
      return; 
    }

    if (!widget.verifyOnlyMode && tagType == 'VERIFY' && !_isChefMode) {
      setState(() {
        _statusText = "❌ Falscher Tag!\nDas ist ein Verifizierungs-Tag.\nZum Sammeln bitte den Badge-Tag scannen.";
      });
      return; 
    }
    
    int currentBlockHeight = 0;
    // Wir nehmen die Blockhöhe vom Tag, falls vorhanden, sonst laden wir sie
    if (tagData['block_height'] != null) {
      currentBlockHeight = tagData['block_height'];
    } else {
      try {
        currentBlockHeight = await MempoolService.getBlockHeight();
      } catch (e) {
        print("Mempool Fehler: $e");
      }
    }

    if (tagType == 'BADGE') {
      String meetupName = tagData['meetup_name'] ?? 'Unbekanntes Meetup';
      String meetupCountry = tagData['meetup_country'] ?? '';
      String meetupId = tagData['meetup_id'] ?? DateTime.now().toString();
      
      bool alreadyCollected = myBadges.any((b) => 
        b.meetupName.contains(meetupName) && 
        b.date.year == DateTime.now().year &&
        b.date.month == DateTime.now().month &&
        b.date.day == DateTime.now().day
      );

      if (!alreadyCollected) {
        // Signer-Info aus Tag-Daten extrahieren
        final signerNpub = tagData['admin_npub'] as String? ?? '';
        final delivery = tagData['delivery'] as String? ?? 'nfc';
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        final meetupEventId = '${meetupName.toLowerCase().replaceAll(' ', '-')}-$dateStr';

        myBadges.add(MeetupBadge(
          id: meetupId, 
          meetupName: meetupCountry.isNotEmpty ? "$meetupName, $meetupCountry" : meetupName, 
          date: DateTime.now(), 
          iconPath: "assets/badge_icon.png",
          blockHeight: currentBlockHeight,
          signerNpub: signerNpub,
          meetupEventId: meetupEventId,
          delivery: delivery,
        ));
        
        await MeetupBadge.saveBadges(myBadges);
        
        msg = "🎉 BADGE GESAMMELT!\n\n📍 $meetupName";
        if (currentBlockHeight > 0) {
          msg += "\n⛓️ Block: $currentBlockHeight";
        }
        // v2: Zeige wer signiert hat
        if (tagData['_verified_by'] != null) {
          msg += "\n🔐 Signiert von: ${tagData['_verified_by']}";
        }
      } else {
        msg = "✅ Badge bereits gesammelt\n\n📍 $meetupName";
      }
    }

    if (tagType == 'VERIFY') {
      if (!user.isAdminVerified) {
        user.isAdminVerified = true;
        if (user.nostrNpub.isNotEmpty) {
          user.isNostrVerified = true;
        }
        await user.save();
        msg = "✅ IDENTITÄT VERIFIZIERT!";
      } else {
        msg = "✅ Bereits verifiziert.";
      }
    }

    setState(() {
      _success = true;
      _statusText = msg;
    });

    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pop(context, true); 
  }

  void _showAdminLogin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("ADMIN LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Login für Organisatoren.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: "PASSWORT",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cOrange)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ABBRUCH", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            onPressed: () {
              if (_passwordController.text == widget.meetup.adminSecret) {
                setState(() {
                  _isChefMode = true;
                  _statusText = "ADMIN MODUS";
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚡️ ADMIN AKTIV")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Falsches Passwort!")));
              }
            },
            child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isChefMode ? "ADMIN TOOLS" : "SCANNER"),
        backgroundColor: _isChefMode ? Colors.red.shade900 : cDark,
        actions: [
          if (!_isChefMode) IconButton(icon: const Icon(Icons.security), onPressed: _showAdminLogin)
        ],
      ),
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
                  style: const TextStyle(
                    color: Colors.grey, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    height: 1.6,
                  ),
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
                  border: Border.all(color: _isChefMode ? Colors.red : cOrange, width: 4),
                  boxShadow: [
                    BoxShadow(color: (_isChefMode ? Colors.red : cOrange).withOpacity(0.5), blurRadius: 40, spreadRadius: 10)
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isChefMode ? Icons.edit_attributes : Icons.nfc, 
                    size: 80, 
                    color: Colors.white
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _isChefMode ? "TAG ERSTELLEN" : "TAG SCANNEN",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            
            if (_isChefMode) ...[
              const SizedBox(height: 20),
              const Text("Modus wählen:", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("BADGE"),
                    selected: _writeModeBadge,
                    onSelected: (val) => setState(() => _writeModeBadge = true),
                    selectedColor: cOrange,
                    labelStyle: TextStyle(color: _writeModeBadge ? Colors.white : Colors.black),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("VERIFY"),
                    selected: !_writeModeBadge,
                    onSelected: (val) => setState(() => _writeModeBadge = false),
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(color: !_writeModeBadge ? Colors.white : Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250, height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    final mode = _writeModeBadge ? NFCWriteMode.badge : NFCWriteMode.verify;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NFCWriterScreen(mode: mode),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _writeModeBadge ? cOrange : Colors.red,
                  ),
                  label: const Text("TAG ERSTELLEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "Legt leere NFC Tags bereit.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              )
            ] 
            else ...[
              const SizedBox(height: 40),
              if (widget.verifyOnlyMode) ...[
                SizedBox(
                  width: 250, height: 50,
                  child: ElevatedButton(
                    onPressed: () => _startNfcRead("VERIFY"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      side: const BorderSide(color: cCyan),
                    ),
                    child: const Text(
                      "VERIFIZIERUNG SCANNEN",
                      style: TextStyle(color: cCyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 250, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _startNfcRead("BADGE"),
                    icon: const Icon(Icons.nfc, color: Colors.white, size: 20),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                    label: const Text("NFC TAG SCANNEN", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 250, height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _startQRScan("BADGE"),
                    icon: const Icon(Icons.qr_code_scanner, color: cOrange, size: 20),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      side: const BorderSide(color: cOrange, width: 1),
                    ),
                    label: const Text("QR-CODE SCANNEN", style: TextStyle(color: cOrange)),
                  ),
                ),
              ],
            ],
            
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
// QR SCANNER SCREEN (für Rolling QR Check-In)
// ============================================
class _QRScannerScreen extends StatefulWidget {
  final String expectedType;
  const _QRScannerScreen({required this.expectedType});

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
      appBar: AppBar(
        title: const Text("QR-CODE SCANNEN"),
        backgroundColor: cOrange,
      ),
      body: Stack(
        children: [
          // Kamera
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

          // Scan-Rahmen Overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: cOrange, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Anweisung unten
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Text(
                  "Halte die Kamera auf den\nRolling QR-Code des Meetups",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  "Der Code ändert sich alle 30 Sekunden",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}