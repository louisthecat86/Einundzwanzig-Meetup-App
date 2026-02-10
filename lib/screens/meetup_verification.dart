import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:convert';
import '../theme.dart';
import '../models/badge.dart';
import '../models/meetup.dart';
import '../models/user.dart'; 
import '../services/mempool.dart'; // <--- WICHTIG: Damit wir die Blockzeit holen können

class MeetupVerificationScreen extends StatefulWidget {
  final Meetup meetup;
  final bool initialChefMode; // <--- NEU: Ermöglicht direkten Admin-Start
  final bool verifyOnlyMode; // <--- NEU: Nur Verifizierung, keine Badges

  const MeetupVerificationScreen({
    super.key, 
    required this.meetup,
    this.initialChefMode = false, // Standardmäßig aus
    this.verifyOnlyMode = false, // Standardmäßig aus
  });

  @override
  State<MeetupVerificationScreen> createState() => _MeetupVerificationScreenState();
}

class _MeetupVerificationScreenState extends State<MeetupVerificationScreen> with SingleTickerProviderStateMixin {
  late bool _isChefMode; // <--- Jetzt 'late', weil wir es im Init setzen
  bool _success = false;
  String _statusText = "Bereit zum Scannen";
  
  // true = "Badge für alle", false = "Admin Verifizierung"
  bool _writeModeBadge = true; 

  late AnimationController _controller;
  late Animation<double> _animation;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Wir übernehmen den Startwert vom Widget (für den roten Dashboard-Button)
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

  // --- NFC HANDSHAKE ---
  // type: "BADGE" oder "VERIFY"
  void _startNfcRead(String type) async {
    setState(() {
      _statusText = "Warte auf NFC Tag...";
    });

    // Fallback für Web/Desktop: Simulation
    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      _simulateHandshake(type);
      return;
    }

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (tag) async {
          try {
            // Versuche NDEF-Daten zu lesen
            final ndef = Ndef.from(tag);
            if (ndef == null || ndef.cachedMessage == null) {
              setState(() => _statusText = "❌ Kein NDEF-Tag erkannt");
              await NfcManager.instance.stopSession(errorMessage: 'Kein NDEF-Tag');
              return;
            }
            
            final records = ndef.cachedMessage!.records;
            if (records.isEmpty) {
              setState(() => _statusText = "❌ Kein NDEF-Record gefunden");
              await NfcManager.instance.stopSession(errorMessage: 'Tag ist leer');
              return;
            }
            
            // Lese das erste Text-Record
            final record = records[0];
            String jsonString;
            
            // Text-Record dekodieren
            if (record.typeNameFormat == NdefTypeNameFormat.nfcWellKnown) {
              final payload = record.payload;
              // Text-Record hat das Format: [Status-Byte][Language-Code][Text]
              // Status-Byte enthält die Länge des Language-Codes in den unteren 6 Bits
              if (payload.isNotEmpty) {
                final languageCodeLength = payload[0] & 0x3F;
                final textStartIndex = 1 + languageCodeLength;
                jsonString = utf8.decode(payload.sublist(textStartIndex));
              } else {
                setState(() => _statusText = "❌ Leeres Payload");
                await NfcManager.instance.stopSession(errorMessage: 'Leeres Payload');
                return;
              }
            } else {
              setState(() => _statusText = "❌ Unbekanntes Record-Format");
              await NfcManager.instance.stopSession(errorMessage: 'Unbekanntes Format');
              return;
            }
            
            Map<String, dynamic>? tagData = json.decode(jsonString);
            await NfcManager.instance.stopSession(alertMessage: 'Tag erfolgreich gelesen!');
            _processFoundTagData(tagData: tagData);
          } catch (e) {
            setState(() => _statusText = "❌ Fehler beim Lesen: $e");
            await NfcManager.instance.stopSession(errorMessage: e.toString());
          }
        },
      );
    } catch (e) {
      setState(() => _statusText = "❌ NFC Fehler: $e");
    }
  }

  // Simulation für Web/Desktop
  void _simulateHandshake(String type) async {
    setState(() {
      _statusText = _isChefMode ? "Schreibe Tag... (SIM)" : "Lese Tag... (SIM)";
    });
    await Future.delayed(const Duration(seconds: 1));
    Map<String, dynamic>? tagData;
    if (type == "BADGE") {
      tagData = {
        'type': 'BADGE',
        'meetup_id': widget.meetup.id,
        'meetup_name': widget.meetup.city,
        'meetup_country': widget.meetup.country,
        'meetup_date': DateTime.now().toIso8601String(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } else if (type == "VERIFY") {
      tagData = {
        'type': 'VERIFY',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    _processFoundTagData(tagData: tagData);
  }

  // --- VERARBEITUNG DER DATEN ---
  void _processFoundTagData({Map<String, dynamic>? tagData}) async {
    if (tagData == null) {
      setState(() {
        _statusText = "❌ Kein gültiger Tag erkannt";
      });
      return;
    }

    final user = await UserProfile.load();
    String msg = "";
    String tagType = tagData['type'] ?? '';

    // A) Blockhöhe laden (Asynchron von Mempool.space)
    int currentBlockHeight = 0;
    try {
      currentBlockHeight = await MempoolService.getBlockHeight();
    } catch (e) {
      // Offline fallback
    }

    // B) Badge Logik
    if (tagType == 'BADGE') {
      String meetupName = tagData['meetup_name'] ?? 'Unbekanntes Meetup';
      String meetupCountry = tagData['meetup_country'] ?? '';
      String meetupId = tagData['meetup_id'] ?? DateTime.now().toString();
      
      // Prüfe ob Badge bereits gesammelt wurde
      bool alreadyCollected = myBadges.any((b) => 
        b.meetupName == meetupName && 
        b.date.year == DateTime.now().year &&
        b.date.month == DateTime.now().month &&
        b.date.day == DateTime.now().day
      );

      if (!alreadyCollected) {
        myBadges.add(MeetupBadge(
          id: meetupId, 
          meetupName: meetupCountry.isNotEmpty ? "$meetupName, $meetupCountry" : meetupName, 
          date: DateTime.now(), 
          iconPath: "assets/badge_icon.png",
          blockHeight: currentBlockHeight, // Echte Blockzeit vom Mempool
        ));
        
        // Badges speichern
        await MeetupBadge.saveBadges(myBadges);
        
        msg = "🎉 BADGE GESAMMELT!\n\n📍 $meetupName";
        if (meetupCountry.isNotEmpty) msg += ", $meetupCountry";
        if (currentBlockHeight > 0) {
          msg += "\n⛓️ Block: $currentBlockHeight";
        }
      } else {
        msg = "✅ Badge bereits gesammelt\n\n📍 $meetupName";
      }
    }

    // C) Verifizierungs Logik
    if (tagType == 'VERIFY') {
      if (!user.isAdminVerified) {
        user.isAdminVerified = true;
        // Wenn der Nutzer einen Nostr npub hat, verifizieren wir diesen auch
        if (user.nostrNpub.isNotEmpty) {
          user.isNostrVerified = true;
        }
        await user.save(); // WICHTIG: Speichern!
        msg = "IDENTITÄT VERIFIZIERT! ✅";
        if (user.nostrNpub.isNotEmpty) {
          msg += "\nNostr-Identität bestätigt.";
        }
      } else {
        msg = "Bereits verifiziert.";
      }
    }

    setState(() {
      _success = true;
      _statusText = msg;
    });

    // Kurz warten, dann schließen
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ADMIN AKTIV ⚡️")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falsches Passwort!")));
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
              Text(_statusText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          )
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ANIMATION KREIS
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
              _isChefMode ? "TAG BESCHREIBEN" : "TAG SCANNEN",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            
            // --- ADMIN MODUS ---
            if (_isChefMode) ...[
              const SizedBox(height: 20),
              // Wahl zwischen Badge und Verify
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text("BADGE"),
                    selected: _writeModeBadge,
                    onSelected: (val) => setState(() => _writeModeBadge = true),
                    selectedColor: cOrange,
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("VERIFY"),
                    selected: !_writeModeBadge,
                    onSelected: (val) => setState(() => _writeModeBadge = false),
                    selectedColor: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 250, height: 50,
                child: ElevatedButton(
                  onPressed: () => _startNfcRead(_writeModeBadge ? "BADGE" : "VERIFY"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                  child: const Text("TAG ERSTELLEN", style: TextStyle(color: Colors.white)),
                ),
              ),
            ] 
            
            // --- PLEB MODUS ---
            else ...[
              const SizedBox(height: 40),
              // Wenn verifyOnlyMode: NUR Verifizierung
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
                      "VERIFIZIERUNGS-TAG SCANNEN",
                      style: TextStyle(color: cCyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                // Normaler Modus: Badge sammeln
                SizedBox(
                  width: 250, height: 50,
                  child: ElevatedButton(
                    onPressed: () => _startNfcRead("BADGE"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                    child: const Text("BADGE FINDEN", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ]
          ],
        ),
      ),
    );
  }
}