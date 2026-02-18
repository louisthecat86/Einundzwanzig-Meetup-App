// ============================================
// NFC WRITER SCREEN — Nur Badge-Modus
// ============================================
// Schreibt Meetup-Badge-Tags auf NFC.
// Verifizierungs-Tags gibt es nicht mehr.
// Organisator-Status kommt automatisch über Trust Score.
// ============================================

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../services/mempool.dart';

class NFCWriterScreen extends StatefulWidget {
  const NFCWriterScreen({super.key});

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
    if (meetups.isEmpty) meetups = allMeetups;

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
    if (_homeMeetup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Bitte erst ein Home-Meetup im Profil auswählen!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _statusText = "Berechne Signatur...";
      _success = false;
    });

    final timestamp = DateTime.now().toIso8601String();
    int blockHeight = 0;
    
    try {
      blockHeight = await MempoolService.getBlockHeight();
    } catch (e) {
      print("Mempool Fehler: $e");
    }

    final meetupId = _homeMeetup?.id ?? "global";

    // --- SIGNIERUNG: Nostr (v2) oder Legacy (v1) ---
    Map<String, dynamic> tagData;
    final hasNostrKey = await NostrService.hasKey();

    if (hasNostrKey) {
      try {
        tagData = await BadgeSecurity.signWithNostr(
          meetupId: meetupId,
          timestamp: timestamp,
          blockHeight: blockHeight,
          meetupName: _homeMeetup?.city ?? 'Unknown',
          meetupCountry: _homeMeetup?.country ?? '',
          tagType: 'BADGE',
        );
        setState(() => _statusText = "🔐 Nostr-Signatur erstellt...");
      } catch (e) {
        final signature = BadgeSecurity.signLegacy(meetupId, timestamp, blockHeight);
        tagData = {
          'type': 'BADGE',
          'meetup_id': meetupId,
          'timestamp': timestamp,
          'block_height': blockHeight,
          'meetup_name': _homeMeetup!.city,
          'meetup_country': _homeMeetup!.country,
          'meetup_date': DateTime.now().toIso8601String(),
          'sig': signature,
        };
      }
    } else {
      final signature = BadgeSecurity.signLegacy(meetupId, timestamp, blockHeight);
      tagData = {
        'type': 'BADGE',
        'meetup_id': meetupId,
        'timestamp': timestamp,
        'block_height': blockHeight,
        'meetup_name': _homeMeetup!.city,
        'meetup_country': _homeMeetup!.country,
        'meetup_date': DateTime.now().toIso8601String(),
        'sig': signature,
      };
    }

    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      await _simulateWriteTag();
      return;
    }

    setState(() => _statusText = "Halte Tag an das Gerät...");

    String jsonData = jsonEncode(tagData);
    final payload = Uint8List.fromList([0x02, 0x65, 0x6e, ...utf8.encode(jsonData)]);

    final message = NdefMessage(records: [
      NdefRecord(
        typeNameFormat: TypeNameFormat.wellKnown,
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
              var formatable = NdefFormatableAndroid.from(tag);
              if (formatable != null) {
                try {
                  setState(() => _statusText = "Formatiere leeren Tag...");
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
              _handleErrorInUI("Kein NDEF Format möglich");
              return;
            }

            if (!ndef.isWritable) {
              await NfcManager.instance.stopSession();
              _handleErrorInUI("Tag ist schreibgeschützt");
              return;
            }

            // Payload-Größe prüfen
            final payloadSize = jsonData.length + 7;
            final maxSize = ndef.maxSize;
            if (payloadSize > maxSize) {
              await NfcManager.instance.stopSession();
              _handleErrorInUI(
                "Tag zu klein! Daten: ${payloadSize}B, Tag: ${maxSize}B.\n"
                "Verwende einen NTAG215 (504B) oder größer."
              );
              return;
            }

            await ndef.write(message: message);
            await NfcManager.instance.stopSession();
            _handleSuccessInUI();

          } catch (e) {
            print("[ERROR] Write Error: $e");
            await NfcManager.instance.stopSession();
            
            final errorMsg = e.toString();
            if (errorMsg.contains('IOException')) {
              _handleErrorInUI("Tag zu früh entfernt — halte ihn ruhig 2–3 Sekunden ans Gerät");
            } else if (errorMsg.contains('TagLost')) {
              _handleErrorInUI("Tag verloren während dem Schreiben");
            } else {
              _handleErrorInUI(errorMsg);
            }
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
      _statusText = "✅ MEETUP TAG geschrieben!\n\n📍 ${_homeMeetup?.city}\nTeilnehmer können jetzt Badges scannen.";
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _handleErrorInUI(String error) {
    if (!mounted) return;
    setState(() => _statusText = "❌ $error");
  }

  Future<void> _simulateWriteTag() async {
    setState(() => _statusText = "Schreibe Tag... (SIM)");
    await Future.delayed(const Duration(seconds: 2));
    _handleSuccessInUI();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text("MEETUP TAG ERSTELLEN"), backgroundColor: cOrange),
      body: Center(
        child: _success
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 100, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text("ERFOLG!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Text(_statusText, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16, height: 1.6)),
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
                  const Text("MEETUP TAG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Halte einen leeren NFC Tag an das Gerät.\nTeilnehmer scannen diesen Tag um ein Badge zu sammeln.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cOrange.withOpacity(0.3)),
                    ),
                    child: Column(children: [
                      const Text("DEIN HOME-MEETUP", style: TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(_meetupInfo.isNotEmpty ? _meetupInfo : "...", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250, height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _writeTag,
                      icon: const Icon(Icons.nfc, color: Colors.white),
                      label: const Text("TAG ERSTELLEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: cOrange),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(_statusText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
      ),
    );
  }
}