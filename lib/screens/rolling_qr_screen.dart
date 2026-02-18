// ============================================
// ROLLING QR SCREEN v2 — SESSION + ROLLING
// ============================================
//
// Organisator-Workflow:
//   1. "Session starten" → 6h Session wird erstellt
//   2. QR rollt alle 10 Sekunden (Anti-Screenshot)
//   3. App schließen + öffnen → Session läuft weiter
//   4. Nachzügler nach 1h → scannt den aktuellen QR → OK
//   5. Nach 6h → "Session abgelaufen" → neue Session starten
//
// Der QR enthält:
//   - Badge-Daten (kompakt, Schnorr-signiert)
//   - Rolling Nonce (10s gültig, Screenshot = wertlos)
//   - Session-Ablauf (6h)
//
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

class _RollingQRScreenState extends State<RollingQRScreen> with WidgetsBindingObserver {
  String _qrData = '';
  String _meetupInfo = '';
  Meetup? _homeMeetup;
  int _blockHeight = 0;
  int _secondsLeft = 10;
  String _adminNpub = '';

  bool _isLoading = true;
  bool _isActive = false;
  MeetupSession? _session;

  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // App-Lifecycle beobachten
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// App kommt in den Vordergrund → Session fortsetzen
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _session != null && !_session!.isExpired) {
      _resumeRolling();
    }
  }

  Future<void> _initialize() async {
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

    // Bestehende Session prüfen
    await _checkExistingSession();
  }

  /// Prüft ob eine laufende Session existiert und setzt sie fort
  Future<void> _checkExistingSession() async {
    final session = await RollingQRService.loadSession();
    if (session != null && !session.isExpired) {
      setState(() {
        _session = session;
        _isActive = true;
      });
      _startTimers();
      await _refreshQR();
    }
  }

  /// Neue Session starten
  Future<void> _startNewSession() async {
    if (_homeMeetup == null) return;

    final compactId = '${_homeMeetup!.city.toLowerCase().replaceAll(' ', '-')}-${_homeMeetup!.country.toLowerCase()}';

    final session = await RollingQRService.getOrCreateSession(
      meetupId: compactId,
      meetupName: _homeMeetup!.city,
      meetupCountry: _homeMeetup!.country,
      blockHeight: _blockHeight,
    );

    if (session == null) return;

    setState(() {
      _session = session;
      _isActive = true;
    });

    _startTimers();
    await _refreshQR();
  }

  /// Rolling fortsetzen (nach App-Resume)
  void _resumeRolling() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _startTimers();
    _refreshQR();
  }

  void _startTimers() {
    // QR alle 10 Sekunden neu
    _refreshTimer = Timer.periodic(
      Duration(seconds: RollingQRService.intervalSeconds),
      (_) => _refreshQR(),
    );

    // Countdown jede Sekunde
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        // Session abgelaufen?
        if (_session != null && _session!.isExpired) {
          _stopSession();
          return;
        }

        setState(() {
          _secondsLeft = RollingQRService.secondsUntilNextChange();
        });
      },
    );
  }

  Future<void> _refreshQR() async {
    if (_session == null || _session!.isExpired) return;

    try {
      final qrString = await RollingQRService.generateQRString(_session!);
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

  Future<void> _stopSession() async {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    await RollingQRService.endSession();
    if (mounted) {
      setState(() {
        _isActive = false;
        _session = null;
        _qrData = '';
      });
    }
  }

  void _confirmStopSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("Session beenden?", style: TextStyle(color: Colors.white)),
        content: Text(
          "Restzeit: ${_session?.remainingTimeString ?? '-'}\n\n"
          "Eine beendete Session kann nicht fortgesetzt werden. "
          "Du kannst danach eine neue starten.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ABBRECHEN", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _stopSession();
            },
            child: const Text("BEENDEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =============================================
  // UI
  // =============================================

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
              icon: const Icon(Icons.stop_circle, color: Colors.white70),
              onPressed: _confirmStopSession,
              tooltip: "Session beenden",
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
      child: SingleChildScrollView(
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
            const Text("MEETUP QR-CODE",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 16),
            Text(_meetupInfo, style: const TextStyle(color: cOrange, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),

            // Feature-Erklärung
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("So funktioniert's:",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  _featureRow(Icons.timer, "6 Stunden gültig", "Session überlebt App-Neustart"),
                  const SizedBox(height: 8),
                  _featureRow(Icons.refresh, "Rollt alle 10 Sekunden", "Screenshots sind sofort wertlos"),
                  const SizedBox(height: 8),
                  _featureRow(Icons.lock, "Schnorr-signiert", "Unfälschbar, kryptographisch sicher"),
                  const SizedBox(height: 8),
                  _featureRow(Icons.group, "Beliebig viele Scans", "Alle Teilnehmer können scannen"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            if (_homeMeetup != null)
              SizedBox(
                width: 280, height: 60,
                child: ElevatedButton.icon(
                  onPressed: _startNewSession,
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                  label: const Text("SESSION STARTEN (6h)",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: cOrange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: cOrange, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveQR() {
    final progress = _secondsLeft / RollingQRService.intervalSeconds;
    final remaining = _session?.remainingTimeString ?? '-';

    return Column(
      children: [
        // Session-Info Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          color: cOrange.withOpacity(0.15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_meetupInfo, style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text("Session: $remaining", style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              // Session-Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text("AKTIV", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
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
                // QR mit weißem Hintergrund
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: cOrange.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                  ),
                  child: _qrData.isNotEmpty
                      ? QrImageView(
                          data: _qrData,
                          version: QrVersions.auto,
                          size: 260,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        )
                      : const SizedBox(
                          width: 260, height: 260,
                          child: Center(child: CircularProgressIndicator(color: cOrange)),
                        ),
                ),
                const SizedBox(height: 24),

                // Rolling Countdown
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60, height: 60,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey.withOpacity(0.3),
                        color: _secondsLeft <= 3 ? Colors.red : cOrange,
                      ),
                    ),
                    Text('$_secondsLeft',
                      style: TextStyle(
                        color: _secondsLeft <= 3 ? Colors.red : Colors.white,
                        fontSize: 22, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _secondsLeft <= 3 ? "Code erneuert sich..." : "Nächster Code in",
                  style: TextStyle(color: _secondsLeft <= 3 ? Colors.red : Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Footer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: cCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("⛓️ Block $_blockHeight",
                style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12)),
              if (_adminNpub.isNotEmpty)
                Text(NostrService.shortenNpub(_adminNpub),
                  style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}