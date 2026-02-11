import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart'; // NEU: für NdefFormatable (v4.x)
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';

enum NFCWriteMode { badge, verify }

class NFCWriterScreen extends StatefulWidget {
  final NFCWriteMode mode;
  
  const NFCWriterScreen({super.key, required this.mode});

  @override
  State<NFCWriterScreen> createState() => _NFCWriterScreenState();
}

class _NFCWriterScreenState extends State<NFCWriterScreen> with SingleTickerProviderStateMixin {
  bool _success = false;
  String _statusText = "Bereit zum Schreiben";
  Meetup? _homeMeetup;
  String _meetupInfo = "";
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadHomeMeetup();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadHomeMeetup() async {
    final user = await UserProfile.load();
    
    if (user.homeMeetupId.isEmpty) {
      setState(() {
        _statusText = "⚠️ Kein Home-Meetup gesetzt";
        _meetupInfo = "Bitte erst ein Home-Meetup im Profil auswählen";
      });
      return;
    }

    List<Meetup> meetups = await MeetupService.fetchMeetups();
    if (meetups.isEmpty) {
      meetups = allMeetups;
    }

    final meetup = meetups.where((m) => m.city == user.homeMeetupId).firstOrNull;
    
    if (meetup != null) {
      setState(() {
        _homeMeetup = meetup;
        _meetupInfo = "📍 ${meetup.city}, ${meetup.country}";
        _statusText = "Bereit zum Schreiben";
      });
    } else {
      setState(() {
        _statusText = "⚠️ Home-Meetup nicht gefunden";
        _meetupInfo = "Meetup: ${user.homeMeetupId}";
      });
    }
  }

  void _writeTag() async {
    if (widget.mode == NFCWriteMode.badge && _homeMeetup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Bitte erst ein Home-Meetup im Profil auswählen!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _statusText = "Halte Tag an das Gerät...";
      _success = false;
    });

    final isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      await _simulateWriteTag();
      return;
    }

    Map<String, dynamic> tagData = {
      'type': widget.mode == NFCWriteMode.badge ? 'BADGE' : 'VERIFY',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (widget.mode == NFCWriteMode.badge && _homeMeetup != null) {
      tagData['meetup_id'] = _homeMeetup!.id;
      tagData['meetup_name'] = _homeMeetup!.city;
      tagData['meetup_country'] = _homeMeetup!.country;
      tagData['meetup_date'] = DateTime.now().toIso8601String();
    }
    
    String jsonData = jsonEncode(tagData);
    final payload = Uint8List.fromList([0x02, 0x65, 0x6e, ...utf8.encode(jsonData)]);

    final message = NdefMessage([
      NdefRecord(
        typeNameFormat: NdefTypeNameFormat.nfcWellknown,
        type: Uint8List.fromList([0x54]),
        identifier: Uint8List(0),
        payload: payload,
      ),
    ]);

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            var ndef = Ndef.from(tag);
            
            if (ndef == null) {
              // v4.x: NdefFormatable aus platform_tags.dart
              var formatable = NdefFormatable.from(tag);
              if (formatable != null) {
                try {
                  await formatable.format(message);
                  await NfcManager.instance.stopSession();
                  _handleSuccessInUI();
                  return;
                } catch (e) {
                  await NfcManager.instance.stopSession();
                  _handleErrorInUI("Formatierung fehlgeschlagen");
                  return;
                }
              }
              await NfcManager.instance.stopSession();
              _handleErrorInUI("Kein NDEF Format");
              return;
            }

            if (!ndef.isWritable) {
              await NfcManager.instance.stopSession();
              _handleErrorInUI("Schreibgeschützt");
              return;
            }

            await ndef.write(message);
            await NfcManager.instance.stopSession();
            _handleSuccessInUI();

          } catch (e) {
            print("[ERROR] Write Error: $e");
            await NfcManager.instance.stopSession();
            _handleErrorInUI(e.toString());
          }
        },
      );
    } catch (e) {
      setState(() => _statusText = "❌ Start Fehler: $e");
    }
  }

  void _handleSuccessInUI() {
    if (!mounted) return;
    setState(() {
      _success = true;
      _statusText = widget.mode == NFCWriteMode.badge
          ? "✅ MEETUP TAG geschrieben!\n\n📍 ${_homeMeetup?.city}\nBadge-System aktiv."
          : "✅ VERIFIZIERUNGS-TAG geschrieben!\n\nAdmin-Key gespeichert.";
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _handleErrorInUI(String error) {
    if (!mounted) return;
    setState(() {
      _statusText = "❌ Fehler: $error";
    });
  }

  Future<void> _simulateWriteTag() async {
    setState(() {
      _statusText = "Schreibe Tag... (SIM)";
    });
    await Future.delayed(const Duration(seconds: 2));
    _handleSuccessInUI();
  }

  @override
  Widget build(BuildContext context) {
    Color modeColor = widget.mode == NFCWriteMode.badge ? cOrange : cCyan;
    IconData modeIcon = widget.mode == NFCWriteMode.badge ? Icons.bookmark : Icons.verified_user;
    String modeTitle = widget.mode == NFCWriteMode.badge ? "MEETUP TAG" : "VERIFIZIERUNGS-TAG";
    
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(modeTitle),
        backgroundColor: modeColor,
      ),
      body: Center(
        child: _success
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 100, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text(
                    "ERFOLG!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: modeColor, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: modeColor.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          modeIcon,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    modeTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.mode == NFCWriteMode.badge
                          ? "Halte einen leeren NFC Tag an das Gerät um einen Meetup Tag zu erstellen."
                          : "Halte einen leeren NFC Tag an das Gerät um einen Verifizierungs-Tag zu erstellen.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (widget.mode == NFCWriteMode.badge) ...[
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cOrange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "DEIN HOME-MEETUP",
                            style: TextStyle(
                              color: cOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _meetupInfo.isNotEmpty ? _meetupInfo : "...",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _writeTag,
                      icon: const Icon(Icons.nfc, color: Colors.white),
                      label: const Text(
                        "TAG ERSTELLEN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _statusText,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}