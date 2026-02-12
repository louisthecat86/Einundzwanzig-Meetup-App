// ============================================
// ROLLING QR SCREEN
// ============================================
// 
// Der Organisator legt sein Handy auf den Tisch.
// Auf dem Screen wird ein QR-Code angezeigt der sich
// alle 30 Sekunden ändert.
//
// Teilnehmer scannen den QR-Code mit ihrer App.
// → Gleicher Effekt wie NFC-Tag scannen.
// → Aber kein NFC-Tag nötig!
//
// Die Rolling Nonce verhindert:
// - Screenshots weiterleiten (nach 30s ungültig)
// - Remote-Scan von der Couch (Code ändert sich)
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../services/meetup_service.dart';
import '../services/rolling_qr_service.dart';
import '../services/mempool.dart';
import '../services/nostr_service.dart';

class RollingQRScreen extends StatefulWidget {
  const RollingQRScreen({super.key});

  @override
  State<RollingQRScreen> createState() => _RollingQRScreenState();
}

class _RollingQRScreenState extends State<RollingQRScreen> {
  String _qrData = '';
  String _meetupInfo = '';
  Meetup? _homeMeetup;
  int _blockHeight = 0;
  int _secondsLeft = 30;
  int _scanCount = 0;
  bool _isActive = false;
  bool _isLoading = true;
  String _adminNpub = '';

  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Meetup laden
    final user = await UserProfile.load();
    final npub = await NostrService.getNpub();

    if (user.homeMeetupId.isEmpty) {
      setState(() {
        _isLoading = false;
        _meetupInfo = "⚠️ Kein Home-Meetup gesetzt";
      });
      return;
    }

    List<Meetup> meetups = await MeetupService.fetchMeetups();
    if (meetups.isEmpty) meetups = allMeetups;

    final meetup = meetups.where((m) => m.city == user.homeMeetupId).firstOrNull;

    // Blockhöhe holen
    try {
      _blockHeight = await MempoolService.getBlockHeight();
    } catch (e) {
      print('[RollingQR] Mempool Fehler: $e');
    }

    setState(() {
      _homeMeetup = meetup;
      _meetupInfo = meetup != null ? "📍 ${meetup.city}, ${meetup.country}" : "⚠️ Meetup nicht gefunden";
      _adminNpub = npub ?? '';
      _isLoading = false;
    });
  }

  void _startRolling() async {
    if (_homeMeetup == null) return;

    setState(() => _isActive = true);

    // Sofort ersten QR generieren
    await _refreshQR();

    // Timer: QR alle 30 Sekunden neu generieren
    _refreshTimer = Timer.periodic(
      Duration(seconds: RollingQRService.intervalSeconds),
      (_) => _refreshQR(),
    );

    // Countdown jede Sekunde aktualisieren
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            _secondsLeft = RollingQRService.secondsUntilNextChange();
          });
        }
      },
    );
  }

  void _stopRolling() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isActive = false;
      _qrData = '';
    });
  }

  Future<void> _refreshQR() async {
    if (_homeMeetup == null) return;

    try {
      final qrString = await RollingQRService.generateQRString(
        meetupId: _homeMeetup!.id,
        meetupName: _homeMeetup!.city,
        meetupCountry: _homeMeetup!.country,
        blockHeight: _blockHeight,
      );

      if (mounted) {
        setState(() {
          _qrData = qrString;
          _secondsLeft = RollingQRService.secondsUntilNextChange();
        });
      }
    } catch (e) {
      print('[RollingQR] Fehler: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("MEETUP QR-CODE"),
        backgroundColor: cOrange,
        actions: [
          if (_isActive)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red),
              onPressed: _stopRolling,
              tooltip: "Stoppen",
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cOrange))
          : _isActive
              ? _buildActiveQR()
              : _buildStartScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cOrange, width: 3),
              ),
              child: const Icon(Icons.qr_code_2, size: 80, color: cOrange),
            ),
            const SizedBox(height: 30),
            const Text(
              "ROLLING QR-CODE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _meetupInfo,
              style: const TextStyle(color: cOrange, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder),
              ),
              child: Column(
                children: const [
                  Text(
                    "So funktioniert's:",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "1. Starte den QR-Code\n"
                    "2. Lege dein Handy auf den Tisch\n"
                    "3. Teilnehmer scannen mit ihrer App\n"
                    "4. Der Code ändert sich alle 30 Sekunden\n\n"
                    "⚡ Screenshots sind nach 30s ungültig\n"
                    "🔐 Signiert mit deinem Nostr-Key",
                    style: TextStyle(color: Colors.white70, height: 1.6, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (_homeMeetup != null)
              SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _startRolling,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    "QR STARTEN",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: cOrange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveQR() {
    final progress = _secondsLeft / RollingQRService.intervalSeconds;

    return Column(
      children: [
        // Meetup Info Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          color: cOrange.withOpacity(0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _meetupInfo,
                style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold),
              ),
              if (_adminNpub.isNotEmpty)
                Text(
                  NostrService.shortenNpub(_adminNpub),
                  style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11),
                ),
            ],
          ),
        ),

        // QR Code (dominanter Bereich)
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR-Code mit weißem Hintergrund
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cOrange.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: _qrData.isNotEmpty
                      ? QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 260,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        )
                      : const SizedBox(
                          width: 260,
                          height: 260,
                          child: Center(child: CircularProgressIndicator(color: cOrange)),
                        ),
                ),
                const SizedBox(height: 24),

                // Countdown Timer
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      // Kreisförmiger Countdown
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              color: _secondsLeft <= 5 ? Colors.red : cOrange,
                            ),
                          ),
                          Text(
                            '$_secondsLeft',
                            style: TextStyle(
                              color: _secondsLeft <= 5 ? Colors.red : Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _secondsLeft <= 5 ? "Code erneuert sich..." : "Nächster Code in",
                        style: TextStyle(
                          color: _secondsLeft <= 5 ? Colors.red : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Footer: Block Height + Status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: cCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "⛏️ Block $_blockHeight",
                style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "AKTIV",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}