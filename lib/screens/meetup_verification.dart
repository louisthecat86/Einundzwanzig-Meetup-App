import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../theme.dart';
import '../models/badge.dart';
import '../models/meetup.dart';
import '../models/user.dart'; 
import '../services/mempool.dart';
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
        },
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              await NfcManager.instance.stopSession(errorMessage: "Kein NDEF Tag");
              return;
            }

            final cachedMessage = ndef.cachedMessage;
            if (cachedMessage == null || cachedMessage.records.isEmpty) {
              await NfcManager.instance.stopSession(errorMessage: "Tag ist leer");
              return;
            }

            final payload = cachedMessage.records.first.payload;
            if (payload.isEmpty) {
               await NfcManager.instance.stopSession(errorMessage: "Payload leer");
              return;
            }

            final languageCodeLength = payload.first & 0x3F;
            final textStart = 1 + languageCodeLength;
            
            if (payload.length <= textStart) {
               await NfcManager.instance.stopSession(errorMessage: "Format ungültig");
              return;
            }

            final jsonString = utf8.decode(payload.sublist(textStart));
            
            try {
              final Map<String, dynamic> tagData = json.decode(jsonString) as Map<String, dynamic>;
              // Erfolgreich gelesen -> Feedback geben
              await NfcManager.instance.stopSession(alertMessage: "Tag gelesen!");
              _processFoundTagData(tagData: tagData);
            } catch (e) {
               await NfcManager.instance.stopSession(errorMessage: "Keine gültigen Meetup-Daten");
            }
            
          } catch (e) {
            print("[ERROR] Fehler beim Tag-Lesen: $e");
            await NfcManager.instance.stopSession(errorMessage: "Lesefehler");
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

    int currentBlockHeight = 0;
    try {
      currentBlockHeight = await MempoolService.getBlockHeight();
    } catch (e) {
      print("[ERROR] Blockhöhe konnte nicht geladen werden: $e");
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
        myBadges.add(MeetupBadge(
          id: meetupId, 
          meetupName: meetupCountry.isNotEmpty ? "$meetupName, $meetupCountry" : meetupName, 
          date: DateTime.now(), 
          iconPath: "assets/badge_icon.png",
          blockHeight: currentBlockHeight,
        ));
        
        await MeetupBadge.saveBadges(myBadges);
        
        msg = "🎉 BADGE GESAMMELT!\n\n📍 $meetupName";
        if (currentBlockHeight > 0) {
          msg += "\n⛓️ Block: $currentBlockHeight";
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
                  child: ElevatedButton(
                    onPressed: () => _startNfcRead("BADGE"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                    child: const Text("BADGE EINSAMMELN", style: TextStyle(color: Colors.white)),
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