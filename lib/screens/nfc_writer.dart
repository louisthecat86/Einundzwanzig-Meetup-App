// ============================================
// NFC WRITER — KOMPAKT-FORMAT (passt auf NTAG215)
// ============================================
// Payload: ~285 Bytes (vorher 583B → passt jetzt!)
//
// Format: {"v":2,"t":"B","m":"city-cc","b":875432,
//          "x":expiry,"c":created,"p":"pubkey","s":"sig"}
//
// Features:
//   • Kompakt-Signatur (Schnorr, unfälschbar)
//   • 6h Ablaufzeit → Überschreibbar für nächstes Meetup
//   • Payload-Größe wird VOR dem Schreiben angezeigt
//   • Funktioniert mit NTAG213 (137B), 215 (492B), 216 (872B)
//   • NFC-Simulation ENTFERNT — kein Fake-Schreiben mehr möglich.
// ============================================

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';            // NfcManager, NfcTag, NfcPollingOption, NfcAvailability
import 'package:nfc_manager/ndef_record.dart';              // NdefRecord, NdefMessage, TypeNameFormat
import 'package:nfc_manager/nfc_manager_android.dart';      // NdefFormatableAndroid
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';    // Ndef (cross-platform)
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import '../services/badge_security.dart';
import '../services/rolling_qr_service.dart';
// NEU: Import für den QR-Screen, um nach Erfolg dorthin zu springen
import 'rolling_qr_screen.dart';
import '../services/app_logger.dart';

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
  int _payloadSize = 0;
  
  // THE FIX: Sperre, damit das Handy nicht mehrfach schreibt/vibriert
  bool _isProcessingTag = false; 
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadHomeMeetup();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
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
      // Payload-Größe vorberechnen
      final compactId = '${meetup.city.toLowerCase().replaceAll(' ', '-')}-${meetup.country.toLowerCase()}';
      final estimatedPayload = '{"v":2,"t":"B","m":"$compactId","b":000000,"x":0000000000,"c":0000000000,"p":"${"0" * 64}","s":"${"0" * 128}"}';
      
      setState(() {
        _homeMeetup = meetup;
        _meetupInfo = "📍 ${meetup.city}, ${meetup.country}";
        _payloadSize = estimatedPayload.length + 10; // +10 für NFC Record Header
        _statusText = "Bereit zum Schreiben";
      });
    } else {
      setState(() {
        _statusText = "⚠️ Home-Meetup nicht gefunden";
        _meetupInfo = "Meetup: ${user.homeMeetupId}";
      });
    }
  }

  // =============================================
  // NFC TAG SCHREIBEN
  // =============================================
  // FIX: Bei fehlendem/deaktiviertem NFC wird jetzt ein
  // Dialog angezeigt statt einen Erfolg zu simulieren.
  // =============================================

  void _writeTag() async {
    if (_homeMeetup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Bitte erst ein Home-Meetup im Profil auswählen!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _statusText = "Lade Session-Daten...";
      _success = false;
      _isProcessingTag = false; // Reset lock
    });

    // Zentraler Payload Abruf
    final tagData = await RollingQRService.getBasePayload();
    
    if (tagData == null) {
       setState(() => _statusText = "❌ Keine aktive Meetup-Session gefunden. Bitte starte das Meetup neu.");
       return;
    }

    // NFC verfügbar?
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      // ── NFC nicht verfügbar → Dialog ──
      if (!mounted) return;

      // NFC könnte deaktiviert oder nicht unterstützt sein
      final bool isNotSupported = availability.toString().toLowerCase().contains('not');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(
            Icons.nfc_rounded,
            size: 48,
            color: isNotSupported ? Colors.red : cOrange,
          ),
          title: Text(
            isNotSupported ? "NFC nicht verfügbar" : "NFC ist deaktiviert",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isNotSupported
                ? "Dieses Gerät unterstützt kein NFC.\n\n"
                  "Du kannst stattdessen Rolling QR-Codes "
                  "für dein Meetup verwenden."
                : "Bitte aktiviere NFC in deinen Geräteeinstellungen, "
                  "um den Tag zu beschreiben.\n\n"
                  "Android: Einstellungen → Verbindungen → NFC",
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
          actions: [
            if (!isNotSupported)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("EINSTELLUNGEN ÖFFNEN",
                    style: TextStyle(color: Colors.grey)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: cOrange)),
            ),
          ],
        ),
      );

      setState(() {
        _statusText = isNotSupported
            ? "Dieses Gerät hat kein NFC. Nutze Rolling QR-Codes."
            : "NFC ist deaktiviert. Bitte einschalten.";
      });
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

    final actualSize = jsonData.length + 7; // 3 prefix + ~4 NDEF header

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          // Verhindert, dass der Scanner während dem Schreibvorgang neu triggert
          if (_isProcessingTag) return;
          _isProcessingTag = true;

          try {
            var ndef = Ndef.from(tag);
            
            if (ndef == null) {
              var formatable = NdefFormatableAndroid.from(tag);
              if (formatable != null) {
                try {
                  setState(() => _statusText = "Formatiere leeren Tag...");
                  await formatable.format(message);
                  await NfcManager.instance.stopSession();
                  _handleSuccessInUI(jsonData.length);
                  return;
                } catch (e) {
                  await NfcManager.instance.stopSession();
                  _handleErrorInUI("Formatierung fehlgeschlagen");
                  _isProcessingTag = false;
                  return;
                }
              }
              await NfcManager.instance.stopSession();
              _handleErrorInUI("Kein NDEF Format möglich");
              _isProcessingTag = false;
              return;
            }

            if (!ndef.isWritable) {
              await NfcManager.instance.stopSession();
              _handleErrorInUI("Tag ist schreibgeschützt");
              _isProcessingTag = false;
              return;
            }

            // Payload-Größe prüfen
            final maxSize = ndef.maxSize;
            if (actualSize > maxSize) {
              await NfcManager.instance.stopSession();
              _handleErrorInUI(
                "Tag zu klein! Daten: ${actualSize}B, Tag: ${maxSize}B.\n"
                "Verwende einen NTAG215 (504B) oder größer."
              );
              _isProcessingTag = false;
              return;
            }

            await ndef.write(message: message);
            await NfcManager.instance.stopSession();
            _handleSuccessInUI(jsonData.length);

          } catch (e) {
            AppLogger.debug('App', "[ERROR] Write Error: $e");
            await NfcManager.instance.stopSession();
            final errorMsg = e.toString();
            if (errorMsg.contains('IOException')) {
              _handleErrorInUI("Tag zu früh entfernt — halte ihn ruhig 2–3 Sekunden ans Gerät");
            } else if (errorMsg.contains('TagLost')) {
              _handleErrorInUI("Tag verloren während dem Schreiben");
            } else {
              _handleErrorInUI(errorMsg);
            }
            _isProcessingTag = false;
          }
        },
      );
    } catch (e) {
      setState(() {
        _statusText = "❌ Start Fehler: $e";
        _isProcessingTag = false;
      });
    }
  }

  void _handleSuccessInUI(int dataSize) {
    if (!mounted) return;
    final expiresIn = BadgeSecurity.badgeValidityHours;
    setState(() {
      _success = true;
      _statusText = "✅ MEETUP TAG geschrieben!\n\n"
          "📦 ${dataSize}B (kompakt)\n"
          "⏱️ Gültig für ${expiresIn}h\n\n"
          "Springe zum QR-Code...";
    });
    
    // Automatischer Sprung zum QR-Code Screen
    // pushAndRemoveUntil: Entfernt Wizard + AdminPanel vom Stack
    // → Zurück-Button im RollingQR führt direkt zum Dashboard
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const RollingQRScreen()),
          (route) => route.isFirst, // Nur Dashboard behalten
        );
      }
    });
  }

  void _handleErrorInUI(String error) {
    if (!mounted) return;
    setState(() => _statusText = "❌ $error");
  }

  // =============================================
  // _simulateWriteTag() ENTFERNT — Sicherheitslücke geschlossen
  // =============================================

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
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14, height: 1.6)),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
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
                        "Halte einen NFC Tag an das Gerät.\nTeilnehmer scannen diesen Tag um ein Badge zu sammeln.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Home-Meetup Anzeige
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
                    const SizedBox(height: 12),

                    // Payload-Info
                    if (_payloadSize > 0)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text("~${_payloadSize}B — passt auf NTAG215 (492B)",
                            style: const TextStyle(color: Colors.green, fontSize: 12)),
                        ]),
                      ),
                    const SizedBox(height: 8),

                    // Ablauf + Überschreibbar Info
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cCyan.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: const [
                            Icon(Icons.timer, color: cCyan, size: 16),
                            SizedBox(width: 6),
                            Text("Gültig für 6 Stunden", style: TextStyle(color: cCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: const [
                            Icon(Icons.refresh, color: cCyan, size: 16),
                            SizedBox(width: 6),
                            Text("Tag kann danach überschrieben werden", style: TextStyle(color: cCyan, fontSize: 12)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Schreib-Button
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }
}