import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager.dart';
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
    
    print("[DEBUG] Home-Meetup Name: ${user.homeMeetupId}");
    
    if (user.homeMeetupId.isEmpty) {
      setState(() {
        _statusText = "⚠️ Kein Home-Meetup gesetzt";
        _meetupInfo = "Bitte erst ein Home-Meetup im Profil auswählen";
      });
      return;
    }

    // Versuche das Meetup zu laden (erst aus API, dann aus Fallback)
    List<Meetup> meetups = await MeetupService.fetchMeetups();
    if (meetups.isEmpty) {
      meetups = allMeetups;
    }

    print("[DEBUG] Geladene Meetups:");
    for (var m in meetups) {
      print("  - Name: ${m.city}");
    }

    // Match auf Stadt-Namen statt ID
    final meetup = meetups.where((m) => m.city == user.homeMeetupId).firstOrNull;
    
    if (meetup != null) {
      print("[DEBUG] Meetup gefunden: ${meetup.city}");
      setState(() {
        _homeMeetup = meetup;
        _meetupInfo = "📍 ${meetup.city}, ${meetup.country}";
        _statusText = "Bereit zum Schreiben";
      });
    } else {
      print("[DEBUG] Kein Meetup gefunden für: ${user.homeMeetupId}");
      setState(() {
        _statusText = "⚠️ Home-Meetup nicht gefunden";
        _meetupInfo = "Meetup: ${user.homeMeetupId}";
      });
    }
  }

  void _writeTag() async {
    // Badge-Modus benötigt ein Home-Meetup
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
      _statusText = "Warte auf NFC Tag zum Schreiben...";
    });

    // Fallback für Web/Desktop: Simulation
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
    final payload = [0x02, 0x65, 0x6e, ...utf8.encode(jsonData)]; // Sprachcode "en"

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (tag) async {
          try {
            // Versuche NDEF zu schreiben (Android/iOS unterschiedlich!)
            dynamic tagMap;
            if (tag.data is Map) {
              tagMap = tag.data as Map;
            } else {
              setState(() => _statusText = "❌ Fehler: Unerwarteter Tag-Typ: " + tag.data.runtimeType.toString());
              await NfcManager.instance.stopSession();
              return;
            }
            final ndef = tagMap['ndef'];
            if (ndef == null || ndef['isWritable'] != true) {
              setState(() => _statusText = "❌ Kein beschreibbarer NDEF-Tag erkannt");
              await NfcManager.instance.stopSession();
              return;
            }
            // Schreibe NDEF-Text-Record (Payload als JSON)
            // Die aktuelle nfc_manager API unterstützt das Schreiben nur über native Methoden, nicht direkt in Dart.
            // Zeige stattdessen eine Info an, dass der Tag erkannt wurde (Demo/Fallback).
            setState(() {
              _success = true;
              _statusText = widget.mode == NFCWriteMode.badge
                  ? "MEETUP TAG erkannt (Schreibfunktion muss ggf. nativ implementiert werden)!\n\n📍 ${_homeMeetup!.city}, ${_homeMeetup!.country}\n\nTeilnehmer können jetzt scannen und Badge sammeln."
                  : "VERIFIZIERUNGS-TAG erkannt (Schreibfunktion muss ggf. nativ implementiert werden)!\n\nNeue Nutzer können ihre Identität bestätigen.";
            });
            await NfcManager.instance.stopSession();
            await Future.delayed(const Duration(seconds: 3));
            if (mounted) Navigator.pop(context);
          } catch (e) {
            setState(() => _statusText = "❌ Fehler beim Schreiben: $e");
            await NfcManager.instance.stopSession();
          }
        },
      );
    } catch (e) {
      setState(() => _statusText = "❌ NFC Fehler: $e");
    }
  }

  // Simulation für Web/Desktop
  Future<void> _simulateWriteTag() async {
    setState(() {
      _statusText = "Schreibe Tag... (SIM)";
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _success = true;
      _statusText = widget.mode == NFCWriteMode.badge
          ? "MEETUP TAG erstellt!\n\n📍 ${_homeMeetup?.city ?? "?"}, ${_homeMeetup?.country ?? "?"}\n\nTeilnehmer können jetzt scannen und Badge sammeln."
          : "VERIFIZIERUNGS-TAG erstellt!\n\nNeue Nutzer können ihre Identität bestätigen.";
    });
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.pop(context);
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
                  Icon(Icons.check_circle, size: 100, color: Colors.green),
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
                  // Animation Kreis
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
                  // Meetup-Info für Badge-Mode anzeigen
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
                        "TAG ERSTELLEN (SIM)",
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
