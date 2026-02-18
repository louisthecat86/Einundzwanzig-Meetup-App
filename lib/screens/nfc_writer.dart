// ============================================
// NFC WRITER SCREEN (v2.1 — Kapazitätserkennung)
// ============================================
//
// NEU in v2.1:
// - Erkennt automatisch die Tag-Kapazität (NTAG213/215/216)
// - Wählt das passende Format:
//     NTAG213 (144B): Legacy v1 kompakt (~120B)
//     NTAG215 (504B): Nostr v2 kompakt (~350B)
//     NTAG216 (888B): Nostr v2 kompakt (~350B)
// - Bessere Fehlermeldungen bei Schreibfehlern
// - Retry-Button nach Fehler

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import '../services/badge_security.dart';
import '../services/nostr_service.dart';
import '../services/mempool.dart';

enum NFCWriteMode { badge, verify }

class NFCWriterScreen extends StatefulWidget {
  final NFCWriteMode mode;
  
  const NFCWriterScreen({super.key, required this.mode});

  @override
  State<NFCWriterScreen> createState() => _NFCWriterScreenState();
}

class _NFCWriterScreenState extends State<NFCWriterScreen> with SingleTickerProviderStateMixin {
  bool _success = false;
  bool _error = false;
  String _statusText = "Bereit zum Schreiben";
  String _errorDetail = "";
  Meetup? _homeMeetup;
  String _meetupInfo = "";
  
  late AnimationController _controller;
  late Animation<double> _animation;

  // Vorberechnete Tag-Daten (für Retry)
  String _preparedTimestamp = "";
  int _preparedBlockHeight = 0;

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

  // =============================================
  // HAUPTFUNKTION: Tag beschreiben
  // =============================================

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
      _statusText = "Vorbereitung...";
      _success = false;
      _error = false;
      _errorDetail = "";
    });

    // --- DATEN VORBEREITEN ---
    _preparedTimestamp = DateTime.now().toIso8601String();
    _preparedBlockHeight = 0;
    
    try {
      _preparedBlockHeight = await MempoolService.getBlockHeight();
    } catch (e) {
      print("Mempool Fehler: $e");
    }

    // --- NFC VERFÜGBARKEIT PRÜFEN ---
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      await _simulateWriteTag();
      return;
    }

    setState(() => _statusText = "📱 Halte den NFC-Tag an dein Gerät...");

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          await _handleTagDiscovered(tag);
        },
      );
    } catch (e) {
      _handleErrorInUI("NFC-Session konnte nicht gestartet werden", e.toString());
    }
  }

  // =============================================
  // TAG ENTDECKT → Kapazität prüfen → Schreiben
  // =============================================

  Future<void> _handleTagDiscovered(NfcTag tag) async {
    try {
      var ndef = Ndef.from(tag);
      final meetupId = _homeMeetup?.id ?? "global";
      final meetupName = _homeMeetup?.city ?? 'Unknown';
      final meetupCountry = _homeMeetup?.country ?? '';
      final tagType = widget.mode == NFCWriteMode.badge ? 'BADGE' : 'VERIFY';

      // --- FALL 1: Tag ist NICHT NDEF-formatiert → Formatieren ---
      if (ndef == null) {
        var formatable = NdefFormatableAndroid.from(tag);
        if (formatable != null) {
          setState(() => _statusText = "Formatiere neuen Tag...");
          
          // Für unformatierte Tags: Legacy v1 kompakt (sicher klein genug)
          final tagData = BadgeSecurity.signLegacyCompact(
            meetupId: meetupId,
            timestamp: _preparedTimestamp,
            blockHeight: _preparedBlockHeight,
            meetupName: meetupName,
            tagType: tagType,
          );
          
          final message = _buildNdefMessage(tagData);
          
          try {
            await formatable.format(message);
            await NfcManager.instance.stopSession();
            _handleSuccessInUI("v1 (neuer Tag formatiert)");
            return;
          } catch (e) {
            await NfcManager.instance.stopSession();
            _handleErrorInUI(
              "Tag konnte nicht formatiert werden",
              "Versuche es nochmal und halte den Tag ruhig ans Gerät.\n\n$e",
            );
            return;
          }
        }
        await NfcManager.instance.stopSession();
        _handleErrorInUI(
          "Tag nicht kompatibel",
          "Dieser Tag unterstützt kein NDEF-Format. Bitte verwende einen anderen NFC-Tag.",
        );
        return;
      }

      // --- FALL 2: Tag ist NDEF-formatiert ---
      
      // Schreibschutz prüfen
      if (!ndef.isWritable) {
        await NfcManager.instance.stopSession();
        _handleErrorInUI(
          "Tag ist schreibgeschützt",
          "Dieser Tag ist gesperrt und kann nicht beschrieben werden.",
        );
        return;
      }

      // Kapazität ermitteln
      final maxSize = ndef.maxSize;
      setState(() => _statusText = "Tag erkannt (${maxSize}B)...");

      // --- FORMAT WÄHLEN basierend auf Kapazität ---
      Map<String, dynamic> tagData;
      String usedFormat;
      final hasNostrKey = await NostrService.hasKey();

      if (hasNostrKey && maxSize >= 400) {
        // NTAG215+ → Nostr v2 kompakt
        try {
          tagData = await BadgeSecurity.signWithNostr(
            meetupId: meetupId,
            timestamp: _preparedTimestamp,
            blockHeight: _preparedBlockHeight,
            meetupName: meetupName,
            meetupCountry: meetupCountry,
            tagType: tagType,
          );
          usedFormat = "Nostr v2";
          setState(() => _statusText = "🔐 Nostr-Signatur erstellt...");
        } catch (e) {
          // Fallback auf Legacy
          tagData = BadgeSecurity.signLegacyCompact(
            meetupId: meetupId,
            timestamp: _preparedTimestamp,
            blockHeight: _preparedBlockHeight,
            meetupName: meetupName,
            tagType: tagType,
          );
          usedFormat = "v1 (Nostr-Fehler)";
        }
      } else {
        // NTAG213 oder kein Nostr-Key → Legacy v1 kompakt
        tagData = BadgeSecurity.signLegacyCompact(
          meetupId: meetupId,
          timestamp: _preparedTimestamp,
          blockHeight: _preparedBlockHeight,
          meetupName: meetupName,
          tagType: tagType,
        );
        usedFormat = hasNostrKey ? "v1 (Tag zu klein für Nostr)" : "v1";
      }

      final message = _buildNdefMessage(tagData);
      
      // Payload-Größe berechnen
      final jsonStr = jsonEncode(tagData);
      final payloadSize = utf8.encode(jsonStr).length + 3; // +3 für Sprach-Header
      
      if (payloadSize > maxSize) {
        await NfcManager.instance.stopSession();
        _handleErrorInUI(
          "Tag zu klein!",
          "Daten: ${payloadSize}B, Tag: ${maxSize}B.\n\n"
          "Verwende einen größeren NFC-Tag:\n"
          "• NTAG215 (504B) für Nostr\n"
          "• NTAG216 (888B) für maximale Daten",
        );
        return;
      }

      // --- SCHREIBEN ---
      setState(() => _statusText = "Schreibe (${payloadSize}B / ${maxSize}B)...");
      
      await ndef.write(message: message);
      await NfcManager.instance.stopSession();
      _handleSuccessInUI(usedFormat);

    } catch (e) {
      print("[ERROR] NFC Write: $e");
      await NfcManager.instance.stopSession();
      
      final errorStr = e.toString();
      
      if (errorStr.contains('IOException')) {
        _handleErrorInUI(
          "Schreibfehler",
          "Der Tag konnte nicht beschrieben werden.\n\n"
          "Mögliche Ursachen:\n"
          "• Tag zu früh entfernt — halte ihn ruhig 2–3 Sekunden ans Gerät\n"
          "• Tag ist voll oder defekt — versuche einen neuen Tag\n"
          "• Tag-Typ nicht kompatibel",
        );
      } else if (errorStr.contains('TagLost')) {
        _handleErrorInUI(
          "Tag verloren",
          "Der NFC-Tag wurde während dem Schreiben entfernt.\n\n"
          "Halte den Tag ruhig ans Gerät bis 'Erfolg' erscheint.",
        );
      } else {
        _handleErrorInUI("Unbekannter Fehler", errorStr);
      }
    }
  }

  // =============================================
  // NDEF MESSAGE BAUEN
  // =============================================

  NdefMessage _buildNdefMessage(Map<String, dynamic> tagData) {
    final jsonData = jsonEncode(tagData);
    final payload = Uint8List.fromList([
      0x02,       // UTF-8 + Sprach-Code-Länge
      0x65, 0x6e, // "en"
      ...utf8.encode(jsonData),
    ]);

    return NdefMessage(records: [
      NdefRecord(
        typeNameFormat: TypeNameFormat.wellKnown,
        type: Uint8List.fromList([0x54]),  // "T" = Text Record
        identifier: Uint8List(0),
        payload: payload,
      ),
    ]);
  }

  // =============================================
  // UI CALLBACKS
  // =============================================

  void _handleSuccessInUI(String format) {
    if (!mounted) return;
    setState(() {
      _success = true;
      _error = false;
      _statusText = widget.mode == NFCWriteMode.badge
          ? "✅ MEETUP TAG geschrieben!\n\n📍 ${_homeMeetup?.city}\nFormat: $format"
          : "✅ VERIFIZIERUNGS-TAG geschrieben!\n\nFormat: $format";
    });
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _handleErrorInUI(String title, String detail) {
    if (!mounted) return;
    setState(() {
      _error = true;
      _success = false;
      _statusText = "❌ $title";
      _errorDetail = detail;
    });
  }

  Future<void> _simulateWriteTag() async {
    setState(() => _statusText = "Schreibe Tag... (SIM)");
    await Future.delayed(const Duration(seconds: 2));
    _handleSuccessInUI("Simulation");
  }

  // =============================================
  // BUILD
  // =============================================

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
            ? _buildSuccessView()
            : _error
                ? _buildErrorView(modeColor)
                : _buildReadyView(modeColor, modeIcon, modeTitle),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 100, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          "ERFOLG!",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
    );
  }

  Widget _buildErrorView(Color modeColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              _errorDetail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 250,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _writeTag,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "NOCHMAL VERSUCHEN",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: modeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyView(Color modeColor, IconData modeIcon, String modeTitle) {
    return Column(
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
                BoxShadow(color: modeColor.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Center(
              child: Icon(modeIcon, size: 80, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          modeTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 2),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            widget.mode == NFCWriteMode.badge
                ? "Halte einen NFC-Tag an das Gerät um einen Meetup-Tag zu erstellen."
                : "Halte einen NFC-Tag an das Gerät um einen Verifizierungs-Tag zu erstellen.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, height: 1.5),
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
                  style: TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  _meetupInfo.isNotEmpty ? _meetupInfo : "...",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: modeColor),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _statusText,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}